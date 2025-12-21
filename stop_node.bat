@echo off
REM Retardio Node Stop Script (Windows)

set RETARDIO_DIR=%USERPROFILE%\.retardio
set RETARDIO_CLI=src\retardio-cli.exe

echo Stopping Retardio Node...
echo.

if not exist "%RETARDIO_CLI%" (
    echo Error: retardio-cli.exe not found at %RETARDIO_CLI%
    pause
    exit /b 1
)

%RETARDIO_CLI% -datadir="%RETARDIO_DIR%" stop

if %errorlevel% equ 0 (
    echo Shutdown signal sent. Waiting for node to stop...
    timeout /t 5 /nobreak > nul
    echo Retardio node stopped successfully
) else (
    echo Failed to stop node. It may not be running.
    pause
    exit /b 1
)

pause
