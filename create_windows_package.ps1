# Retardio Mining Package Creator for Windows
# Run this to create a distributable package

param(
    [string]$PoolIP = "YOUR_VPS_IP_HERE",
    [string]$Version = "1.0.0"
)

$ErrorActionPreference = "Stop"

Write-Host "=============================================="
Write-Host "  RETARDIO PACKAGE CREATOR"
Write-Host "=============================================="
Write-Host ""

# Set your pool IP here
if ($PoolIP -eq "YOUR_VPS_IP_HERE") {
    $PoolIP = Read-Host "Enter your pool VPS IP address"
}

$PackageDir = "RetardioMiner-v$Version"
$ZipFile = "RetardioMiner-v$Version.zip"

# Clean and create
if (Test-Path $PackageDir) { Remove-Item -Recurse -Force $PackageDir }
New-Item -ItemType Directory -Path $PackageDir | Out-Null

Write-Host "Creating package for pool: $PoolIP"

# Copy files
Copy-Item "miner_package\miner_gui.html" "$PackageDir\"
Copy-Item "miner_package\start_mining.bat" "$PackageDir\"
Copy-Item "wallet_gui.html" "$PackageDir\"

# Update placeholders with actual pool IP
$minerGui = Get-Content "$PackageDir\miner_gui.html" -Raw
$minerGui = $minerGui -replace "POOL_IP_HERE", $PoolIP
$minerGui = $minerGui -replace "DASHBOARD_URL_HERE", "http://$PoolIP"
Set-Content "$PackageDir\miner_gui.html" $minerGui

$startBat = Get-Content "$PackageDir\start_mining.bat" -Raw
$startBat = $startBat -replace "pool.retardio.net", $PoolIP
Set-Content "$PackageDir\start_mining.bat" $startBat

# Create README
@"
==================================================
         RETARDIO MINING PACKAGE v$Version
==================================================

POOL ADDRESS: $PoolIP`:3333
DASHBOARD:    http://$PoolIP

FILES INCLUDED:
---------------
- miner_gui.html    : Mining setup guide (open in browser)
- wallet_gui.html   : Wallet generator
- start_mining.bat  : CPU miner launcher
- README.txt        : This file

QUICK START:
------------
1. Open miner_gui.html in your browser
2. Follow instructions for your mining device
3. Check http://$PoolIP for your stats!

Happy Mining!
==================================================
"@ | Set-Content "$PackageDir\README.txt"

# Create ZIP
if (Test-Path $ZipFile) { Remove-Item $ZipFile }
Compress-Archive -Path "$PackageDir\*" -DestinationPath $ZipFile

Write-Host ""
Write-Host "=============================================="
Write-Host "  PACKAGE CREATED: $ZipFile"
Write-Host "=============================================="
Write-Host ""
Write-Host "Contents:"
Get-ChildItem $PackageDir | Format-Table Name, Length
Write-Host ""
Write-Host "Upload $ZipFile to GitHub releases!"
