@echo off
REM Continuous Solo Mining Script for Retardio (Windows)

set RETARDIO_CLI=src\retardio-cli.exe
set DATADIR=%USERPROFILE%\.retardio

if "%1"=="" (
    echo Error: No mining address provided
    echo Usage: %0 ^<your_retardio_address^>
    echo Example: %0 FaDf8jKmN3pQrS9tV2wX4yZ5bC6dE7fG8h
    pause
    exit /b 1
)

set ADDRESS=%1

REM Check if address starts with F
echo %ADDRESS% | findstr /B /C:"F" >nul
if errorlevel 1 (
    echo Error: Address must start with 'F'
    pause
    exit /b 1
)

REM Check if node is running
%RETARDIO_CLI% -datadir="%DATADIR%" getblockchaininfo >nul 2>&1
if errorlevel 1 (
    echo Error: Retardio node is not running
    echo Start the node first with: start_node.bat
    pause
    exit /b 1
)

echo Starting continuous solo mining...
echo Mining to address: %ADDRESS%
echo Press Ctrl+C to stop
echo.

set BLOCKS_MINED=0

:mining_loop
REM Get current block height
for /f %%i in ('%RETARDIO_CLI% -datadir="%DATADIR%" getblockcount 2^>nul') do set HEIGHT=%%i

REM Mine one block
for /f "tokens=*" %%a in ('%RETARDIO_CLI% -datadir="%DATADIR%" generatetoaddress 1 %ADDRESS% 2^>nul') do set RESULT=%%a

if errorlevel 1 (
    echo Failed to mine block. Retrying...
    timeout /t 2 /nobreak >nul
    goto mining_loop
)

set /a BLOCKS_MINED+=1
set /a NEW_HEIGHT=%HEIGHT%+1

echo [%date% %time%] Block %NEW_HEIGHT% mined!
echo   Total mined: %BLOCKS_MINED% blocks
echo.

REM Small delay
timeout /t 1 /nobreak >nul

goto mining_loop
