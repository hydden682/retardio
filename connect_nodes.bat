@echo off
REM Retardio Node Connection Helper - Windows Version

setlocal EnableDelayedExpansion

set RETARDIO_CLI=build\bin\retardio-cli.exe
set DATADIR=%USERPROFILE%\.retardio

echo ==================================
echo Retardio Node Connection Helper
echo ==================================
echo.

REM Check if retardio-cli exists
if not exist "%RETARDIO_CLI%" (
    echo Error: retardio-cli not found at %RETARDIO_CLI%
    echo Please build Retardio first or update the RETARDIO_CLI path in this script.
    pause
    exit /b 1
)

:menu
echo What would you like to do?
echo 1) Add a peer node
echo 2) List current connections
echo 3) Show network info
echo 4) Exit
echo.
set /p choice="Enter choice [1-4]: "

if "%choice%"=="1" goto add_peer
if "%choice%"=="2" goto list_connections
if "%choice%"=="3" goto show_network_info
if "%choice%"=="4" goto exit
echo Invalid choice
goto menu

:add_peer
set /p peer_ip="Enter peer IP address: "
set /p peer_port="Enter peer port (default 18333): "
if "%peer_port%"=="" set peer_port=18333

echo Adding peer: %peer_ip%:%peer_port%
%RETARDIO_CLI% -datadir="%DATADIR%" addnode "%peer_ip%:%peer_port%" "add"

if %errorlevel% equ 0 (
    echo Peer added successfully
) else (
    echo Failed to add peer
)
echo.
goto list_connections

:list_connections
echo Current connections:
%RETARDIO_CLI% -datadir="%DATADIR%" getconnectioncount
echo.
echo Peer details:
%RETARDIO_CLI% -datadir="%DATADIR%" getpeerinfo
echo.
pause
goto menu

:show_network_info
echo Network information:
%RETARDIO_CLI% -datadir="%DATADIR%" getnetworkinfo
echo.
pause
goto menu

:exit
echo Exiting...
exit /b 0
