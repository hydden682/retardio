#!/bin/bash
# Retardio Release Builder v1.1
# Creates ready-to-distribute packages configured for a specific pool

set -e

VERSION="${2:-1.1.0}"
POOL_IP="$1"

if [ -z "$POOL_IP" ]; then
    echo "Usage: $0 <pool-ip> [version]"
    echo "Example: $0 123.45.67.89 1.1.0"
    exit 1
fi

echo ""
echo "========================================"
echo "  RETARDIO RELEASE BUILDER v1.1"
echo "========================================"
echo ""
echo "Pool IP: $POOL_IP"
echo "Version: $VERSION"
echo ""

OUT_DIR="Retardio-v$VERSION"
TAR_FILE="Retardio-v$VERSION-linux.tar.gz"

# Clean
rm -rf "$OUT_DIR" "$TAR_FILE"

# Create output directory
mkdir -p "$OUT_DIR"

# Copy and configure the all-in-one HTML
echo "Creating configured wallet/miner interface..."
sed "s/POOL_HOST_HERE/$POOL_IP/g; s|DASHBOARD_URL_HERE|http://$POOL_IP|g" \
    retardio_all_in_one.html > "$OUT_DIR/Retardio.html"

# Copy standalone wallet
echo "Copying standalone wallet..."
cp wallet_standalone.html "$OUT_DIR/Wallet.html"

# Create launcher script
cat > "$OUT_DIR/start.sh" << 'EOF'
#!/bin/bash
# Open Retardio in default browser
if command -v xdg-open &> /dev/null; then
    xdg-open Retardio.html
elif command -v open &> /dev/null; then
    open Retardio.html
else
    echo "Please open Retardio.html in your browser"
fi
EOF
chmod +x "$OUT_DIR/start.sh"

# Create README
cat > "$OUT_DIR/README.txt" << EOF
==================================================
         RETARDIO v$VERSION
==================================================

QUICK START:
------------
1. Run ./start.sh (or open Retardio.html in browser)
2. Click "Generate Wallet"
3. SAVE YOUR PRIVATE KEY SECURELY!
4. Configure your miner with the settings shown
5. Start mining!

FILES:
------
- Retardio.html  : Main interface (wallet + mining config)
- Wallet.html    : Standalone wallet generator
- start.sh       : Quick launcher

POOL INFO:
----------
Address: stratum+tcp://${POOL_IP}:3333
Dashboard: http://$POOL_IP

SECURITY:
---------
- Your private key is generated locally in your browser
- Never share your private key with anyone
- Back up your private key securely

SUPPORT:
--------
GitHub: https://github.com/hydden682/retardio

==================================================
EOF

# Create checksums
echo "Generating checksums..."
cd "$OUT_DIR"
sha256sum * > SHA256SUMS.txt
cd ..

# Create tarball
echo "Creating archive..."
tar -czf "$TAR_FILE" "$OUT_DIR"

# Calculate archive checksum
TAR_HASH=$(sha256sum "$TAR_FILE" | cut -d' ' -f1)

echo ""
echo "========================================"
echo "  BUILD COMPLETE!"
echo "========================================"
echo ""
echo "Created: $TAR_FILE"
echo "SHA256:  $TAR_HASH"
echo ""
echo "Contents:"
ls -la "$OUT_DIR"
echo ""
echo "Next steps:"
echo "1. Test the release locally"
echo "2. Upload to GitHub Releases"
echo "3. Add the SHA256 checksum to the release notes"
echo ""
