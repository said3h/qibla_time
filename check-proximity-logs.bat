@echo off
REM ============================================
REM Script de diagnóstico de sensor de proximidad
REM ============================================

echo.
echo ============================================
echo   Diagnóstico de Sensor - Rakaha (Qibla)
echo ============================================
echo.

REM Matar procesos anteriores
taskkill /F /IM adb.exe >nul 2>&1

echo [1/4] Iniciando adb...
adb start-server >nul 2>&1

echo [2/4] Verificando dispositivo...
adb devices | findstr "device" >nul
if %errorlevel% neq 0 (
    echo ERROR: No se detectó ningún dispositivo Android conectado.
    echo Conecta tu dispositivo y habilita la depuración USB.
    pause
    exit /b 1
)
echo Dispositivo conectado OK.
echo.

echo [3/4] Limpiando logs anteriores...
adb logcat -c

echo [4/4] Monitoreando logs de proximidad...
echo.
echo ============================================
echo   Presiona CTRL+C para detener
echo ============================================
echo.
echo Logs Android (QiblaProximity):
echo --------------------------------------------

REM Ejecutar logcat en segundo plano y filtrar
adb logcat -s QiblaProximity:D
