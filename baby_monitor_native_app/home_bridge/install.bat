@echo off
echo ============================================
echo   KOA Home Bridge - Instalador
echo ============================================
echo.

:: Verificar Python
python --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: Python no esta instalado.
    echo Descargalo de https://python.org/downloads/
    echo Asegurate de marcar "Add Python to PATH" al instalar.
    pause
    exit /b 1
)

echo [1/2] Instalando dependencias...
pip install -r "%~dp0requirements.txt"
if errorlevel 1 (
    echo ERROR: No se pudieron instalar las dependencias.
    pause
    exit /b 1
)

echo.
echo [2/2] Verificando config.json...
if not exist "%~dp0config.json" (
    echo No se encontro config.json. Creando plantilla...
    (
        echo {
        echo   "supabase_url": "https://ujbqnsdznvjjrqbrguyx.supabase.co",
        echo   "supabase_anon_key": "PEGA_TU_ANON_KEY_AQUI",
        echo   "user_email": "tu@email.com",
        echo   "user_password": "tu_contraseña",
        echo   "cameras": [
        echo     {
        echo       "id": "cam_1",
        echo       "name": "Camara 1",
        echo       "host": "192.168.1.100",
        echo       "rtsp_port": 554,
        echo       "rtsp_path": "/onvif1",
        echo       "username": "admin",
        echo       "password": "",
        echo       "onvif_port": 8899,
        echo       "fps": 2
        echo     }
        echo   ]
        echo }
    ) > "%~dp0config.json"
    echo.
    echo IMPORTANTE: Edita config.json con tus datos antes de ejecutar.
    echo   - supabase_anon_key: la clave anon de tu proyecto Supabase
    echo   - user_email/password: tu cuenta de KOA
    echo   - cameras: IP y datos de tus camaras
)

echo.
echo ============================================
echo   Instalacion completada!
echo.
echo   Para ejecutar: python "%~dp0bridge.py"
echo   O usa: start.bat
echo ============================================
pause
