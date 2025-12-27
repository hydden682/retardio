#!/bin/bash
#
# Create distributable pool package
# Run this on your VPS after setting up the pool
#

set -e

POOL_IP=$(curl -s ifconfig.me)
PACKAGE_DIR="retardio-pool-package"
VERSION="1.0.0"

echo "Creating Retardio Pool Package..."
echo "Pool IP: $POOL_IP"

# Clean and create package directory
rm -rf "$PACKAGE_DIR"
mkdir -p "$PACKAGE_DIR"

# Copy miner files
cp miner_package/miner_gui.html "$PACKAGE_DIR/"
cp miner_package/start_mining.bat "$PACKAGE_DIR/"
cp wallet_gui.html "$PACKAGE_DIR/"

# Update pool IP in files
sed -i "s/POOL_IP_HERE/$POOL_IP/g" "$PACKAGE_DIR/miner_gui.html"
sed -i "s/DASHBOARD_URL_HERE/http:\/\/$POOL_IP/g" "$PACKAGE_DIR/miner_gui.html"
sed -i "s/pool.retardio.net/$POOL_IP/g" "$PACKAGE_DIR/start_mining.bat"

# Create README
cat > "$PACKAGE_DIR/README.txt" << EOF
==================================================
         RETARDIO MINING PACKAGE v$VERSION
==================================================

POOL ADDRESS: $POOL_IP:3333
DASHBOARD:    http://$POOL_IP

FILES INCLUDED:
---------------
- miner_gui.html    : Mining setup guide and dashboard link
- wallet_gui.html   : Wallet generator
- start_mining.bat  : CPU miner launcher (Windows)
- README.txt        : This file

FOR NERDMINER USERS:
--------------------
1. Open miner_gui.html in your browser
2. Follow the NerdMiner configuration instructions
3. Use your wallet address as the username
4. Use 'x' as the password

FOR CPU MINERS:
---------------
1. Download cpuminer-opt for your system
2. Place cpuminer.exe in this folder
3. Run start_mining.bat
4. Enter your wallet address when prompted

NEED A WALLET?
--------------
Open wallet_gui.html to generate a new wallet address.
Save your private key securely!

VIEW YOUR STATS:
----------------
Visit http://$POOL_IP to see found blocks and pool statistics.

SUPPORT:
--------
Discord: [Your Discord]
GitHub:  https://github.com/hydden682/retardio

Happy Mining!
==================================================
EOF

# Create zip package
zip -r "retardio-miner-v${VERSION}.zip" "$PACKAGE_DIR"

echo ""
echo "=============================================="
echo "Package created: retardio-miner-v${VERSION}.zip"
echo ""
echo "Contents:"
ls -la "$PACKAGE_DIR/"
echo ""
echo "Upload this zip to GitHub releases or your website"
echo "for users to download!"
echo "=============================================="
