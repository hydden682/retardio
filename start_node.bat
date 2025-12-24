@echo off
REM Retardio Node Startup Script (Windows)

set RETARDIO_DIR=%USERPROFILE%\.retardio
set RETARDIO_BIN=src\retardiod.exe
set RETARDIO_CLI=src\retardio-cli.exe

echo Starting Retardio Node...
echo.

REM Check if binary exists
if not exist "%RETARDIO_BIN%" (
    echo Error: retardiod.exe not found at %RETARDIO_BIN%
    echo Have you compiled the code?
    pause
    exit /b 1
)

REM Create data directory if it doesn't exist
if not exist "%RETARDIO_DIR%" (
    echo Creating data directory at %RETARDIO_DIR%
    mkdir "%RETARDIO_DIR%"
)

REM Check if config file exists
if not exist "%RETARDIO_DIR%\retardio.conf" (
    echo No config file found. Copying example config...
    if exist "retardio.conf.example" (
        copy retardio.conf.example "%RETARDIO_DIR%\retardio.conf"
        echo.
        echo IMPORTANT: Edit %RETARDIO_DIR%\retardio.conf and change the RPC password!
        echo.
    ) else (
        echo Error: retardio.conf.example not found
        pause
        exit /b 1
    )
)

REM Start the node
echo Starting Retardio daemon...
start "Retardio Node" %RETARDIO_BIN% -datadir="%RETARDIO_DIR%"

REM Wait for startup
timeout /t 5 /nobreak > nul

REM Check if it started successfully
%RETARDIO_CLI% -datadir="%RETARDIO_DIR%" getblockchaininfo > nul 2>&1
if %errorlevel% equ 0 (
    echo.
    echo Retardio node started successfully!
    echo.
    %RETARDIO_CLI% -datadir="%RETARDIO_DIR%" getblockchaininfo
) else (
    echo.
    echo Failed to start Retardio node. Check %RETARDIO_DIR%\debug.log for errors
    pause
    exit /b 1
)

echo.
pause
