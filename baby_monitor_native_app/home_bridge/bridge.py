#!/usr/bin/env python3
"""
KOA Home Bridge v1.1 - Puente entre cámaras locales y Supabase.

Usa API REST directa de Supabase (sin SDK) para máxima compatibilidad.

  1. Lee streams RTSP de las cámaras TV-628 con OpenCV
  2. Sube frames JPEG a Supabase Storage
  3. Actualiza la tabla camera_streams con heartbeat
  4. Escucha comandos PTZ desde ptz_commands y los ejecuta via ONVIF
"""

import os
import sys
import json
import time
import signal
import logging
import threading
from datetime import datetime, timezone
from base64 import b64encode

import cv2
import requests

# ============================================================================
# CONFIGURACIÓN
# ============================================================================

CONFIG_FILE = os.path.join(os.path.dirname(os.path.abspath(__file__)), "config.json")
STORAGE_BUCKET = "camera-streams"
FRAME_QUALITY = 70
MAX_FRAME_SIZE = 150_000
HEARTBEAT_INTERVAL = 10
RECONNECT_DELAY = 5
CLEANUP_INTERVAL = 60

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    datefmt="%H:%M:%S",
)
log = logging.getLogger("KOA-Bridge")

_shutdown = threading.Event()


# ============================================================================
# SUPABASE REST CLIENT (sin SDK)
# ============================================================================

class SupabaseREST:
    """Cliente ligero para Supabase usando solo requests."""

    def __init__(self, url: str, anon_key: str):
        self.url = url.rstrip("/")
        self.anon_key = anon_key
        self.access_token = None
        self.user_id = None

    def _headers(self, content_type="application/json"):
        h = {
            "apikey": self.anon_key,
            "Content-Type": content_type,
        }
        if self.access_token:
            h["Authorization"] = f"Bearer {self.access_token}"
        return h

    def sign_in(self, email: str, password: str):
        """Autenticar con email/contraseña."""
        resp = requests.post(
            f"{self.url}/auth/v1/token?grant_type=password",
            headers={"apikey": self.anon_key, "Content-Type": "application/json"},
            json={"email": email, "password": password},
            timeout=15,
        )
        if resp.status_code != 200:
            raise Exception(f"Auth error {resp.status_code}: {resp.text}")

        data = resp.json()
        self.access_token = data["access_token"]
        self.user_id = data["user"]["id"]
        return data["user"]

    # --- Database (PostgREST) ---

    def upsert(self, table: str, data: dict, on_conflict: str = ""):
        """Insertar o actualizar una fila."""
        headers = self._headers()
        headers["Prefer"] = "resolution=merge-duplicates"

        params = {}
        if on_conflict:
            params["on_conflict"] = on_conflict

        resp = requests.post(
            f"{self.url}/rest/v1/{table}",
            headers=headers,
            json=data,
            params=params,
            timeout=10,
        )
        if resp.status_code not in (200, 201, 204):
            raise Exception(f"Upsert {table} error {resp.status_code}: {resp.text}")

    def update(self, table: str, data: dict, filters: dict):
        """Actualizar filas con filtros."""
        params = {f"{k}": f"eq.{v}" for k, v in filters.items()}
        resp = requests.patch(
            f"{self.url}/rest/v1/{table}",
            headers=self._headers(),
            json=data,
            params=params,
            timeout=10,
        )
        if resp.status_code not in (200, 204):
            raise Exception(f"Update {table} error {resp.status_code}: {resp.text}")

    def select(self, table: str, filters: dict, order: str = "", limit: int = 0):
        """Leer filas con filtros."""
        params = {f"{k}": f"eq.{v}" for k, v in filters.items()}
        if order:
            params["order"] = order
        if limit:
            params["limit"] = str(limit)

        resp = requests.get(
            f"{self.url}/rest/v1/{table}",
            headers=self._headers(),
            params=params,
            timeout=10,
        )
        if resp.status_code != 200:
            raise Exception(f"Select {table} error {resp.status_code}: {resp.text}")
        return resp.json()

    def rpc(self, function_name: str):
        """Llamar una función RPC."""
        resp = requests.post(
            f"{self.url}/rest/v1/rpc/{function_name}",
            headers=self._headers(),
            json={},
            timeout=10,
        )
        return resp

    # --- Storage ---

    def storage_upload(self, bucket: str, path: str, data: bytes, content_type: str = "image/jpeg"):
        """Subir archivo a Storage (upsert)."""
        headers = {
            "apikey": self.anon_key,
            "Authorization": f"Bearer {self.access_token}",
            "Content-Type": content_type,
            "x-upsert": "true",
        }
        resp = requests.post(
            f"{self.url}/storage/v1/object/{bucket}/{path}",
            headers=headers,
            data=data,
            timeout=15,
        )
        if resp.status_code not in (200, 201):
            raise Exception(f"Storage upload error {resp.status_code}: {resp.text}")

    def storage_signed_url(self, bucket: str, path: str, expires_in: int = 300):
        """Obtener URL firmada temporal."""
        resp = requests.post(
            f"{self.url}/storage/v1/object/sign/{bucket}/{path}",
            headers=self._headers(),
            json={"expiresIn": expires_in},
            timeout=10,
        )
        if resp.status_code == 200:
            data = resp.json()
            signed_path = data.get("signedURL", "")
            if signed_path:
                return f"{self.url}/storage/v1{signed_path}"
        return ""

    def ensure_bucket(self, bucket: str):
        """Crear bucket si no existe."""
        try:
            resp = requests.get(
                f"{self.url}/storage/v1/bucket/{bucket}",
                headers=self._headers(),
                timeout=10,
            )
            if resp.status_code == 200:
                log.info(f"Bucket '{bucket}' encontrado")
                return
        except Exception:
            pass

        try:
            requests.post(
                f"{self.url}/storage/v1/bucket",
                headers=self._headers(),
                json={"id": bucket, "name": bucket, "public": False},
                timeout=10,
            )
            log.info(f"✅ Bucket '{bucket}' creado")
        except Exception as e:
            log.warning(f"No se pudo crear bucket: {e}")


# ============================================================================
# CONFIG
# ============================================================================

def load_config() -> dict:
    if not os.path.exists(CONFIG_FILE):
        log.error(f"No se encontró {CONFIG_FILE}")
        log.info("Crea config.json con tus credenciales. Ejemplo:")
        example = {
            "supabase_url": "https://xxxxx.supabase.co",
            "supabase_anon_key": "eyJ...",
            "user_email": "tu@email.com",
            "user_password": "tu_contraseña",
            "cameras": [
                {
                    "id": "cam_1",
                    "name": "Habitación Bebé",
                    "host": "192.168.1.100",
                    "rtsp_port": 554,
                    "rtsp_path": "/onvif1",
                    "username": "admin",
                    "password": "",
                    "onvif_port": 8899,
                    "fps": 2,
                }
            ],
        }
        print(json.dumps(example, indent=2, ensure_ascii=False))
        sys.exit(1)

    with open(CONFIG_FILE, "r", encoding="utf-8") as f:
        return json.load(f)


# ============================================================================
# CAMERA WORKER
# ============================================================================

class CameraWorker(threading.Thread):
    def __init__(self, sb: SupabaseREST, cam_config: dict):
        super().__init__(daemon=True)
        self.sb = sb
        self.cam_id = cam_config["id"]
        self.cam_name = cam_config.get("name", self.cam_id)
        self.fps = cam_config.get("fps", 2)
        self.frame_interval = 1.0 / max(self.fps, 1)

        # RTSP URL
        user = cam_config.get("username", "")
        pwd = cam_config.get("password", "")
        host = cam_config["host"]
        port = cam_config.get("rtsp_port", 554)
        path = cam_config.get("rtsp_path", "/onvif1")
        auth = f"{user}:{pwd}@" if user else ""
        self.rtsp_url = f"rtsp://{auth}{host}:{port}{path}"

        # ONVIF PTZ
        self.onvif_url = f"http://{host}:{cam_config.get('onvif_port', 8899)}/onvif/ptz_service"
        self.onvif_auth = (user, pwd) if user else None

        self._last_heartbeat = 0
        self._frame_count = 0

    def run(self):
        log.info(f"[{self.cam_name}] Iniciando captura: {self.rtsp_url}")
        self._register_camera()

        while not _shutdown.is_set():
            try:
                self._capture_loop()
            except Exception as e:
                log.error(f"[{self.cam_name}] Error: {e}")

            if not _shutdown.is_set():
                self._set_offline()
                log.info(f"[{self.cam_name}] Reintentando en {RECONNECT_DELAY}s...")
                _shutdown.wait(RECONNECT_DELAY)

        self._set_offline()
        log.info(f"[{self.cam_name}] Detenido")

    def _capture_loop(self):
        cap = cv2.VideoCapture(self.rtsp_url, cv2.CAP_FFMPEG)
        if not cap.isOpened():
            log.error(f"[{self.cam_name}] No se pudo abrir RTSP")
            return

        log.info(f"[{self.cam_name}] ✅ Conectado a RTSP")
        self._set_online()

        try:
            while not _shutdown.is_set():
                ret, frame = cap.read()
                if not ret:
                    log.warning(f"[{self.cam_name}] Frame perdido, reconectando...")
                    break

                self._upload_frame(frame)
                self._send_heartbeat()
                self._process_ptz_commands()
                _shutdown.wait(self.frame_interval)
        finally:
            cap.release()

    def _upload_frame(self, frame):
        try:
            h, w = frame.shape[:2]
            if w > 640:
                scale = 640 / w
                frame = cv2.resize(frame, (640, int(h * scale)))

            _, buffer = cv2.imencode(".jpg", frame, [cv2.IMWRITE_JPEG_QUALITY, FRAME_QUALITY])
            jpeg_bytes = buffer.tobytes()

            if len(jpeg_bytes) > MAX_FRAME_SIZE:
                _, buffer = cv2.imencode(".jpg", frame, [cv2.IMWRITE_JPEG_QUALITY, 40])
                jpeg_bytes = buffer.tobytes()

            file_path = f"{self.sb.user_id}/{self.cam_id}/latest.jpg"
            self.sb.storage_upload(STORAGE_BUCKET, file_path, jpeg_bytes)

            frame_url = self.sb.storage_signed_url(STORAGE_BUCKET, file_path, 300)

            self.sb.upsert("camera_streams", {
                "user_id": self.sb.user_id,
                "camera_id": self.cam_id,
                "camera_name": self.cam_name,
                "is_online": True,
                "last_frame_url": frame_url,
                "last_heartbeat": datetime.now(timezone.utc).isoformat(),
                "fps": self.fps,
            }, on_conflict="user_id,camera_id")

            self._frame_count += 1
            if self._frame_count % 30 == 0:
                log.info(f"[{self.cam_name}] {self._frame_count} frames subidos")

        except Exception as e:
            log.error(f"[{self.cam_name}] Error subiendo frame: {e}")

    def _send_heartbeat(self):
        now = time.time()
        if now - self._last_heartbeat < HEARTBEAT_INTERVAL:
            return
        self._last_heartbeat = now
        try:
            self.sb.upsert("camera_streams", {
                "user_id": self.sb.user_id,
                "camera_id": self.cam_id,
                "camera_name": self.cam_name,
                "is_online": True,
                "last_heartbeat": datetime.now(timezone.utc).isoformat(),
                "fps": self.fps,
            }, on_conflict="user_id,camera_id")
        except Exception:
            pass

    def _register_camera(self):
        try:
            self.sb.upsert("camera_streams", {
                "user_id": self.sb.user_id,
                "camera_id": self.cam_id,
                "camera_name": self.cam_name,
                "is_online": False,
                "fps": self.fps,
            }, on_conflict="user_id,camera_id")
        except Exception as e:
            log.error(f"[{self.cam_name}] Error registrando: {e}")

    def _set_online(self):
        try:
            self.sb.upsert("camera_streams", {
                "user_id": self.sb.user_id,
                "camera_id": self.cam_id,
                "camera_name": self.cam_name,
                "is_online": True,
                "last_heartbeat": datetime.now(timezone.utc).isoformat(),
                "fps": self.fps,
            }, on_conflict="user_id,camera_id")
        except Exception:
            pass

    def _set_offline(self):
        try:
            self.sb.update("camera_streams",
                {"is_online": False},
                {"user_id": self.sb.user_id, "camera_id": self.cam_id},
            )
        except Exception:
            pass

    # --- PTZ ---

    def _process_ptz_commands(self):
        try:
            commands = self.sb.select("ptz_commands", {
                "user_id": self.sb.user_id,
                "camera_id": self.cam_id,
                "executed": "false",
            }, order="created_at.asc", limit=5)

            for cmd in commands:
                self._execute_ptz(cmd["command"])
                self.sb.update("ptz_commands", {"executed": True}, {"id": cmd["id"]})

        except Exception as e:
            pass  # Silenciar errores de polling

    def _execute_ptz(self, command: str):
        log.info(f"[{self.cam_name}] PTZ: {command}")

        if command == "stop":
            soap = self._ptz_stop_soap()
        else:
            x, y, zoom = 0.0, 0.0, 0.0
            if command == "left":     x = -0.5
            elif command == "right":  x = 0.5
            elif command == "up":     y = 0.5
            elif command == "down":   y = -0.5
            elif command == "zoom_in":  zoom = 0.5
            elif command == "zoom_out": zoom = -0.5
            soap = self._ptz_move_soap(x, y, zoom)

        try:
            headers = {"Content-Type": "application/soap+xml; charset=utf-8"}
            if self.onvif_auth:
                creds = f"{self.onvif_auth[0]}:{self.onvif_auth[1]}"
                headers["Authorization"] = f"Basic {b64encode(creds.encode()).decode()}"

            requests.post(self.onvif_url, data=soap, headers=headers, timeout=5)

            if command != "stop":
                time.sleep(0.5)
                requests.post(self.onvif_url, data=self._ptz_stop_soap(), headers=headers, timeout=5)
        except Exception as e:
            log.error(f"[{self.cam_name}] PTZ error: {e}")

    @staticmethod
    def _ptz_move_soap(x, y, zoom):
        return f"""<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope"
  xmlns:tptz="http://www.onvif.org/ver20/ptz/wsdl"
  xmlns:tt="http://www.onvif.org/ver10/schema">
  <soap:Body>
    <tptz:ContinuousMove>
      <tptz:ProfileToken>Profile_1</tptz:ProfileToken>
      <tptz:Velocity>
        <tt:PanTilt x="{x}" y="{y}"/>
        <tt:Zoom x="{zoom}"/>
      </tptz:Velocity>
    </tptz:ContinuousMove>
  </soap:Body>
</soap:Envelope>"""

    @staticmethod
    def _ptz_stop_soap():
        return """<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope"
  xmlns:tptz="http://www.onvif.org/ver20/ptz/wsdl">
  <soap:Body>
    <tptz:Stop>
      <tptz:ProfileToken>Profile_1</tptz:ProfileToken>
      <tptz:PanTilt>true</tptz:PanTilt>
      <tptz:Zoom>true</tptz:Zoom>
    </tptz:Stop>
  </soap:Body>
</soap:Envelope>"""


# ============================================================================
# CLEANUP
# ============================================================================

def cleanup_worker(sb: SupabaseREST):
    while not _shutdown.is_set():
        _shutdown.wait(CLEANUP_INTERVAL)
        if _shutdown.is_set():
            break
        try:
            sb.rpc("clean_old_ptz_commands")
        except Exception:
            pass


# ============================================================================
# MAIN
# ============================================================================

def main():
    log.info("=" * 50)
    log.info("  KOA Home Bridge v1.1")
    log.info("  Puente de cámaras para acceso remoto")
    log.info("=" * 50)

    config = load_config()
    cameras = config.get("cameras", [])
    if not cameras:
        log.error("No hay cámaras configuradas en config.json")
        sys.exit(1)

    # Inicializar Supabase REST
    sb = SupabaseREST(config["supabase_url"], config["supabase_anon_key"])

    log.info("Autenticando con Supabase...")
    user = sb.sign_in(config["user_email"], config["user_password"])
    log.info(f"✅ Autenticado como {user['email']}")

    sb.ensure_bucket(STORAGE_BUCKET)

    log.info(f"Cámaras configuradas: {len(cameras)}")

    # Iniciar workers
    workers = []
    for cam in cameras:
        w = CameraWorker(sb, cam)
        w.start()
        workers.append(w)

    # Limpieza periódica
    threading.Thread(target=cleanup_worker, args=(sb,), daemon=True).start()

    # Ctrl+C
    def on_signal(sig, frame):
        log.info("\n⏹ Deteniendo...")
        _shutdown.set()

    signal.signal(signal.SIGINT, on_signal)
    signal.signal(signal.SIGTERM, on_signal)

    log.info("✅ Home Bridge corriendo. Presiona Ctrl+C para detener.")

    try:
        while not _shutdown.is_set():
            _shutdown.wait(1)
    except KeyboardInterrupt:
        _shutdown.set()

    for w in workers:
        w.join(timeout=5)

    log.info("Home Bridge detenido.")


if __name__ == "__main__":
    main()
