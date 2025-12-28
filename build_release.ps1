# Retardio Release Builder v1.1
# Creates ready-to-distribute packages configured for a specific pool

param(
    [Parameter(Mandatory=$true)]
    [string]$PoolIP,
    [string]$Version = "1.1.0"
)

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  RETARDIO RELEASE BUILDER v1.1" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Pool IP: $PoolIP" -ForegroundColor Green
Write-Host "Version: $Version" -ForegroundColor Green
Write-Host ""

$OutDir = "Retardio-v$Version"
$ZipFile = "Retardio-v$Version-win.zip"

# Clean
if (Test-Path $OutDir) { Remove-Item -Recurse -Force $OutDir }
if (Test-Path $ZipFile) { Remove-Item $ZipFile }

# Create output directory
New-Item -ItemType Directory -Path $OutDir | Out-Null

# Copy and configure the all-in-one HTML
Write-Host "Creating configured wallet/miner interface..."
$html = Get-Content "retardio_all_in_one.html" -Raw -Encoding UTF8
$html = $html -replace "POOL_HOST_HERE", $PoolIP
$html = $html -replace "DASHBOARD_URL_HERE", "http://$PoolIP"
[System.IO.File]::WriteAllText("$OutDir\Retardio.html", $html, [System.Text.Encoding]::UTF8)

# Copy standalone wallet
Write-Host "Copying standalone wallet..."
Copy-Item "wallet_standalone.html" "$OutDir\Wallet.html"

# Create simple batch launcher
@"
@echo off
echo Starting Retardio...
start "" "Retardio.html"
"@ | Set-Content "$OutDir\START.bat" -Encoding ASCII

# Create README
@"
==================================================
         RETARDIO v$Version
==================================================

QUICK START:
------------
1. Double-click START.bat (or open Retardio.html)
2. Click "Generate Wallet"
3. SAVE YOUR PRIVATE KEY SECURELY!
4. Configure your miner with the settings shown
5. Start mining!

FILES:
------
- Retardio.html  : Main interface (wallet + mining config)
- Wallet.html    : Standalone wallet generator
- START.bat      : Quick launcher

POOL INFO:
----------
Address: stratum+tcp://${PoolIP}:3333
Dashboard: http://$PoolIP

SECURITY:
---------
- Your private key is generated locally in your browser
- Never share your private key with anyone
- Back up your private key securely

SUPPORT:
--------
GitHub: https://github.com/hydden682/retardio

==================================================
"@ | Set-Content "$OutDir\README.txt" -Encoding UTF8

# Create checksums
Write-Host "Generating checksums..."
$checksums = @()
Get-ChildItem $OutDir -File | ForEach-Object {
    $hash = (Get-FileHash $_.FullName -Algorithm SHA256).Hash
    $checksums += "$hash  $($_.Name)"
}
$checksums | Set-Content "$OutDir\SHA256SUMS.txt" -Encoding UTF8

# Create ZIP
Write-Host "Creating archive..."
Compress-Archive -Path "$OutDir\*" -DestinationPath $ZipFile

# Calculate ZIP checksum
$zipHash = (Get-FileHash $ZipFile -Algorithm SHA256).Hash

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  BUILD COMPLETE!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Created: $ZipFile" -ForegroundColor Yellow
Write-Host "SHA256:  $zipHash" -ForegroundColor Cyan
Write-Host ""
Write-Host "Contents:" -ForegroundColor Cyan
Get-ChildItem $OutDir | Format-Table Name, Length -AutoSize
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Green
Write-Host "1. Test the release locally"
Write-Host "2. Upload to GitHub Releases"
Write-Host "3. Add the SHA256 checksum to the release notes"
Write-Host ""
