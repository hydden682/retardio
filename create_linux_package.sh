#!/bin/bash

# Create Linux Release Package for Retardio
# This creates a .tar.gz file that Linux/Mac users can download and install

set -e

VERSION="1.0.0"
PACKAGE_NAME="retardio_v${VERSION}_linux"
BUILD_DIR="build/bin"

echo "╔══════════════════════════════════════════════════════╗"
echo "║     Creating Retardio Linux Package v${VERSION}         ║"
echo "╚══════════════════════════════════════════════════════╝"
echo ""

# Check if binaries exist
if [ ! -f "$BUILD_DIR/retardiod" ] || [ ! -f "$BUILD_DIR/retardio-cli" ]; then
    echo "❌ Error: Binaries not found in $BUILD_DIR"
    echo ""
    echo "Please build first:"
    echo "  cmake -B build && cmake --build build"
    echo ""
    exit 1
fi

# Create package directory
echo "Creating package directory..."
rm -rf "$PACKAGE_NAME"
mkdir -p "$PACKAGE_NAME"

# Copy binaries
echo "Copying binaries..."
cp "$BUILD_DIR/retardiod" "$PACKAGE_NAME/"
cp "$BUILD_DIR/retardio-cli" "$PACKAGE_NAME/"

# Copy installation script
echo "Copying installer..."
cp INSTALL.sh "$PACKAGE_NAME/"
chmod +x "$PACKAGE_NAME/INSTALL.sh"

# Copy documentation
echo "Copying documentation..."
cp README.md "$PACKAGE_NAME/" 2>/dev/null || echo "No README.md found"
cp SIMPLE_WORKFLOW.md "$PACKAGE_NAME/" 2>/dev/null || true
cp TEST_BEFORE_SHARING.md "$PACKAGE_NAME/" 2>/dev/null || true

# Copy block explorer
echo "Copying block explorer..."
cp block_explorer.html "$PACKAGE_NAME/" 2>/dev/null || echo "No block explorer found"
cp block_explorer_server.py "$PACKAGE_NAME/" 2>/dev/null || echo "No block explorer server found"
cp start_explorer.sh "$PACKAGE_NAME/" 2>/dev/null || echo "No start explorer script found"
chmod +x "$PACKAGE_NAME/start_explorer.sh" 2>/dev/null || true
chmod +x "$PACKAGE_NAME/block_explorer_server.py" 2>/dev/null || true

# Copy GUI wallet
echo "Copying GUI wallet..."
cp wallet_gui.html "$PACKAGE_NAME/" 2>/dev/null || echo "No GUI wallet found"
cp start_wallet.sh "$PACKAGE_NAME/" 2>/dev/null || echo "No wallet startup script found"
chmod +x "$PACKAGE_NAME/start_wallet.sh" 2>/dev/null || true

# Create Linux-specific README
cat > "$PACKAGE_NAME/README_LINUX.txt" << 'EOF'
╔══════════════════════════════════════════════════════╗
║         Retardio for Linux/Mac                       ║
╚══════════════════════════════════════════════════════╝

REQUIREMENTS:
- Linux (Ubuntu, Debian, Fedora, etc.) or macOS
- Basic tools: bash, sqlite3

INSTALLATION:
1. Extract this package:
   tar -xzf retardio_v1.0.0_linux.tar.gz
   cd retardio_v1.0.0_linux

2. Run installer:
   ./INSTALL.sh

3. Follow the prompts
4. Done!

USAGE:
After installation, run these commands:
  retardio-status    - Check node status
  retardio-mine 10   - Mine 10 blocks
  retardio help      - Show all commands
  retardio stop      - Stop the node

GUI TOOLS:
  ./start_wallet.sh     - Start GUI wallet (http://localhost:8080)
  ./start_explorer.sh   - Start block explorer (http://localhost:3002)

FEATURES:
✓ Pre-built binaries (no compilation needed)
✓ One-command installer
✓ Automatic node configuration
✓ Built-in mining commands
✓ Easy peer connection
✓ GUI wallet interface
✓ Local block explorer

SUPPORT:
For help, see SIMPLE_WORKFLOW.md or TEST_BEFORE_SHARING.md

EOF

# Create the tar.gz package
echo "Creating tar.gz package..."
tar -czf "${PACKAGE_NAME}.tar.gz" "$PACKAGE_NAME/"

# Get package size
SIZE=$(du -h "${PACKAGE_NAME}.tar.gz" | cut -f1)

# Clean up directory
rm -rf "$PACKAGE_NAME"

echo ""
echo "╔══════════════════════════════════════════════════════╗"
echo "║        ✓ LINUX PACKAGE CREATED! ✓                   ║"
echo "╚══════════════════════════════════════════════════════╝"
echo ""
echo "Package: ${PACKAGE_NAME}.tar.gz"
echo "Size: $SIZE"
echo ""
echo "Linux/Mac users can:"
echo "1. Download ${PACKAGE_NAME}.tar.gz"
echo "2. Extract: tar -xzf ${PACKAGE_NAME}.tar.gz"
echo "3. Run: cd ${PACKAGE_NAME} && ./INSTALL.sh"
echo ""
echo "Done!"
echo ""
