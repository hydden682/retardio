@echo off
title Retardio Miner
color 0A

echo ================================================
echo           RETARDIO MINER
echo ================================================
echo.

:: Check if wallet address is configured
if not exist "config.txt" (
    echo First time setup - please enter your wallet address:
    echo.
    set /p WALLET_ADDRESS="Wallet Address: "
    echo %WALLET_ADDRESS%> config.txt
    echo.
    echo Wallet saved!
) else (
    set /p WALLET_ADDRESS=<config.txt
)

echo.
echo Your wallet: %WALLET_ADDRESS%
echo.
echo Pool: stratum+tcp://pool.retardio.net:3333
echo.
echo Starting miner...
echo.
echo Press Ctrl+C to stop mining
echo ================================================
echo.

:: Start cpuminer
cpuminer.exe -a sha256d -o stratum+tcp://pool.retardio.net:3333 -u %WALLET_ADDRESS% -p x

pause
