// ============================================================================
// CAMERA RELAY SERVICE - Servicio de relay remoto via Supabase
// ============================================================================
// Lee frames JPEG desde Supabase Storage y envía comandos PTZ remotos.
// Usado cuando la app no puede conectarse directamente via RTSP (fuera de casa).

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/supabase_client.dart';

/// Estado de una cámara remota.
class RemoteCameraState {
  final String cameraId;
  final String cameraName;
  final bool isOnline;
  final String? lastFrameUrl;
  final DateTime? lastHeartbeat;
  final int fps;

  RemoteCameraState({
    required this.cameraId,
    required this.cameraName,
    this.isOnline = false,
    this.lastFrameUrl,
    this.lastHeartbeat,
    this.fps = 2,
  });

  /// Tiempo desde último heartbeat.
  Duration? get timeSinceHeartbeat =>
      lastHeartbeat != null ? DateTime.now().toUtc().difference(lastHeartbeat!) : null;

  /// La cámara se considera activa si el heartbeat fue hace menos de 30s.
  bool get isActive =>
      isOnline && timeSinceHeartbeat != null && timeSinceHeartbeat!.inSeconds < 30;
}

/// Servicio singleton para el relay de cámaras remoto.
class CameraRelayService {
  CameraRelayService._();
  static final instance = CameraRelayService._();

  Timer? _pollTimer;
  final _frameController = StreamController<Uint8List>.broadcast();
  final _stateController = StreamController<RemoteCameraState>.broadcast();
  final _httpClient = http.Client();

  String? _activeCameraId;
  RemoteCameraState? _lastState;
  bool _isPolling = false;

  /// Stream de frames JPEG remotos.
  Stream<Uint8List> get frameStream => _frameController.stream;

  /// Stream de estado de la cámara remota.
  Stream<RemoteCameraState> get stateStream => _stateController.stream;

  /// Estado actual.
  RemoteCameraState? get currentState => _lastState;

  /// Inicia el polling de frames para una cámara.
  void startPolling(String cameraId, {int fps = 2}) {
    stopPolling();
    _activeCameraId = cameraId;
    _isPolling = true;

    final interval = Duration(milliseconds: (1000 / fps).round());
    _pollTimer = Timer.periodic(interval, (_) => _fetchLatestFrame());

    debugPrint('📡 Relay: polling cámara $cameraId a ${fps}fps');
  }

  /// Detiene el polling.
  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
    _activeCameraId = null;
    _isPolling = false;
    _lastState = null;
  }

  /// Obtiene la lista de cámaras remotas disponibles.
  Future<List<RemoteCameraState>> getRemoteCameras() async {
    try {
      final userId = currentUserId;
      if (userId == null) return [];

      final result = await supabase
          .from('camera_streams')
          .select()
          .eq('user_id', userId)
          .order('camera_name');

      return (result as List).map((row) => RemoteCameraState(
        cameraId: row['camera_id'] ?? '',
        cameraName: row['camera_name'] ?? '',
        isOnline: row['is_online'] ?? false,
        lastFrameUrl: row['last_frame_url'],
        lastHeartbeat: row['last_heartbeat'] != null
            ? DateTime.tryParse(row['last_heartbeat'])
            : null,
        fps: row['fps'] ?? 2,
      )).toList();
    } catch (e) {
      debugPrint('Relay: error obteniendo cámaras: $e');
      return [];
    }
  }

  /// Busca una cámara remota por su camera_id, nombre, o la primera online.
  Future<RemoteCameraState?> findRemoteCamera(String cameraId, {String? cameraName}) async {
    try {
      final userId = currentUserId;
      if (userId == null) return null;

      // 1. Intentar por camera_id exacto
      var result = await supabase
          .from('camera_streams')
          .select()
          .eq('user_id', userId)
          .eq('camera_id', cameraId)
          .maybeSingle();

      // 2. Si no encuentra, buscar por nombre
      if (result == null && cameraName != null && cameraName.isNotEmpty) {
        result = await supabase
            .from('camera_streams')
            .select()
            .eq('user_id', userId)
            .eq('camera_name', cameraName)
            .maybeSingle();
      }

      // 3. Si aún no encuentra, tomar la primera cámara online
      if (result == null) {
        result = await supabase
            .from('camera_streams')
            .select()
            .eq('user_id', userId)
            .eq('is_online', true)
            .limit(1)
            .maybeSingle();
      }

      if (result == null) return null;

      return RemoteCameraState(
        cameraId: result['camera_id'] ?? '',
        cameraName: result['camera_name'] ?? '',
        isOnline: result['is_online'] ?? false,
        lastFrameUrl: result['last_frame_url'],
        lastHeartbeat: result['last_heartbeat'] != null
            ? DateTime.tryParse(result['last_heartbeat'])
            : null,
        fps: result['fps'] ?? 2,
      );
    } catch (e) {
      debugPrint('Relay: error buscando cámara: $e');
      return null;
    }
  }

  /// Descarga el último frame de una cámara.
  Future<void> _fetchLatestFrame() async {
    if (!_isPolling || _activeCameraId == null) return;

    try {
      final userId = currentUserId;
      if (userId == null) return;

      // Leer estado de camera_streams
      final result = await supabase
          .from('camera_streams')
          .select()
          .eq('user_id', userId)
          .eq('camera_id', _activeCameraId!)
          .maybeSingle();

      if (result == null) return;

      final state = RemoteCameraState(
        cameraId: result['camera_id'] ?? '',
        cameraName: result['camera_name'] ?? '',
        isOnline: result['is_online'] ?? false,
        lastFrameUrl: result['last_frame_url'],
        lastHeartbeat: result['last_heartbeat'] != null
            ? DateTime.tryParse(result['last_heartbeat'])
            : null,
        fps: result['fps'] ?? 2,
      );

      _lastState = state;
      if (!_stateController.isClosed) {
        _stateController.add(state);
      }

      // Descargar frame JPEG si hay URL
      final frameUrl = state.lastFrameUrl;
      if (frameUrl != null && frameUrl.isNotEmpty && state.isActive) {
        final response = await _httpClient.get(Uri.parse(frameUrl));
        if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
          if (!_frameController.isClosed) {
            _frameController.add(response.bodyBytes);
          }
        }
      }
    } catch (e) {
      // Silenciar errores de polling (red intermitente, etc.)
      debugPrint('Relay: frame poll error: $e');
    }
  }

  // ==========================================================================
  // PTZ REMOTO
  // ==========================================================================

  /// Envía un comando PTZ remoto (se ejecuta via Home Bridge).
  Future<void> sendPTZCommand(String cameraId, String command) async {
    try {
      final userId = currentUserId;
      if (userId == null) return;

      await supabase.from('ptz_commands').insert({
        'user_id': userId,
        'camera_id': cameraId,
        'command': command,
      });

      debugPrint('📡 PTZ remoto: $command → $cameraId');
    } catch (e) {
      debugPrint('Relay: PTZ error: $e');
    }
  }

  /// Detiene PTZ remoto.
  Future<void> stopPTZ(String cameraId) async {
    await sendPTZCommand(cameraId, 'stop');
  }

  /// Libera recursos.
  void dispose() {
    stopPolling();
    _frameController.close();
    _stateController.close();
    _httpClient.close();
  }
}
