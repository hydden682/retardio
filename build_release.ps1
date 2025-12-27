# Retardio Release Builder
# Creates a ready-to-distribute package with your pool configured

param(
    [Parameter(Mandatory=$true)]
    [string]$PoolIP,
    [string]$Version = "1.0.0"
)

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  RETARDIO RELEASE BUILDER" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Pool IP: $PoolIP" -ForegroundColor Green
Write-Host "Version: $Version" -ForegroundColor Green
Write-Host ""

$OutDir = "Retardio-v$Version"
$ZipFile = "Retardio-v$Version.zip"

# Clean
if (Test-Path $OutDir) { Remove-Item -Recurse -Force $OutDir }
if (Test-Path $ZipFile) { Remove-Item $ZipFile }

# Create output directory
New-Item -ItemType Directory -Path $OutDir | Out-Null

# Copy and configure the all-in-one HTML
$html = Get-Content "retardio_all_in_one.html" -Raw
$html = $html -replace "POOL_HOST_HERE", $PoolIP
$html = $html -replace "DASHBOARD_URL_HERE", "http://$PoolIP"
Set-Content "$OutDir\Retardio.html" $html

# Create simple batch launcher
@"
@echo off
start "" "Retardio.html"
"@ | Set-Content "$OutDir\START.bat"

# Create README
@"
==================================================
         RETARDIO v$Version
==================================================

QUICK START:
------------
1. Double-click START.bat (or open Retardio.html)
2. Click "Generate Wallet"
3. SAVE YOUR PRIVATE KEY!
4. Configure your miner with the settings shown
5. Start mining!

POOL INFO:
----------
Address: $PoolIP
Port: 3333
Dashboard: http://$PoolIP

SUPPORT:
--------
GitHub: https://github.com/hydden682/retardio

==================================================
"@ | Set-Content "$OutDir\README.txt"

# Create ZIP
Compress-Archive -Path "$OutDir\*" -DestinationPath $ZipFile

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  BUILD COMPLETE!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Created: $ZipFile" -ForegroundColor Yellow
Write-Host ""
Write-Host "Contents:" -ForegroundColor Cyan
Get-ChildItem $OutDir | Format-Table Name, Length -AutoSize
Write-Host ""
Write-Host "Upload this to GitHub Releases!" -ForegroundColor Green
Write-Host ""
