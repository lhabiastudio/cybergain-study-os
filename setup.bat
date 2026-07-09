@echo off
setlocal
cd /d "%~dp0"

echo [Cybergain Study OS] Arrancando setup de Windows...
powershell -ExecutionPolicy Bypass -File ".\scripts\bootstrap-windows.ps1"
if errorlevel 1 (
  echo.
  echo El bootstrap fallo. Revisa el mensaje anterior.
  exit /b %errorlevel%
)

echo.
echo Comprobando estado basico del sistema...
powershell -ExecutionPolicy Bypass -File ".\scripts\check-system.ps1"
if errorlevel 1 (
  echo.
  echo La comprobacion devolvio un error.
  exit /b %errorlevel%
)

echo.
echo Setup completado. Siguiente paso recomendado:
echo powershell -ExecutionPolicy Bypass -File .\scripts\start-study.ps1
endlocal
