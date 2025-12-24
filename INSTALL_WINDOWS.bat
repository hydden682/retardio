@echo off
REM Retardio Windows Installer
REM Requires WSL (Windows Subsystem for Linux) to be installed

echo.
echo ╔══════════════════════════════════════════════════════╗
echo ║         Retardio Installer for Windows              ║
echo ╚══════════════════════════════════════════════════════╝
echo.
echo This installer requires WSL (Windows Subsystem for Linux)
echo.

REM Check if WSL is installed
wsl --status >nul 2>&1
if errorlevel 1 (
    echo ERROR: WSL is not installed or not working!
    echo.
    echo Please install WSL first:
    echo   1. Open PowerShell as Administrator
    echo   2. Run: wsl --install
    echo   3. Restart your computer
    echo   4. Run this installer again
    echo.
    pause
    exit /b 1
)

echo WSL detected! Starting installation...
echo.

REM Get the current directory in Windows format
set "CURRENT_DIR=%~dp0"

REM Convert Windows path to WSL path
for /f "delims=" %%i in ('wsl wslpath "%CURRENT_DIR%"') do set "WSL_PATH=%%i"

echo Installing to: %WSL_PATH%
echo.

REM Run the Linux installer script via WSL
wsl bash -c "cd '%WSL_PATH%' && chmod +x INSTALL.sh && ./INSTALL.sh"

if errorlevel 1 (
    echo.
    echo Installation failed! Check the error messages above.
    echo.
    pause
    exit /b 1
)

echo.
echo ╔══════════════════════════════════════════════════════╗
echo ║        Installation Complete!                        ║
echo ╚══════════════════════════════════════════════════════╝
echo.
echo To use Retardio on Windows, open WSL terminal and run:
echo   retardio-status    - Check node status
echo   retardio-mine 10   - Mine 10 blocks
echo   retardio help      - Show all commands
echo.
echo Or in PowerShell/CMD, prefix commands with 'wsl':
echo   wsl retardio-status
echo   wsl retardio-mine 10
echo.
pause
