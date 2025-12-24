#!/bin/bash

# Create Windows Release Package for Retardio
# This creates a .zip file that Windows users can download and install

set -e

VERSION="1.0.0"
PACKAGE_NAME="retardio_v${VERSION}_windows"
BUILD_DIR="build/bin"

echo "╔══════════════════════════════════════════════════════╗"
echo "║    Creating Retardio Windows Package v${VERSION}        ║"
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
cp INSTALL_WINDOWS.bat "$PACKAGE_NAME/"

# Copy documentation
echo "Copying documentation..."
cp README.md "$PACKAGE_NAME/" 2>/dev/null || echo "No README.md found"
cp WINDOWS_COMMANDS.md "$PACKAGE_NAME/" 2>/dev/null || true
cp SIMPLE_WORKFLOW.md "$PACKAGE_NAME/" 2>/dev/null || true

# Create Windows-specific README
cat > "$PACKAGE_NAME/README_WINDOWS.txt" << 'EOF'
╔══════════════════════════════════════════════════════╗
║         Retardio for Windows                         ║
╚══════════════════════════════════════════════════════╝

REQUIREMENTS:
- Windows 10/11
- WSL (Windows Subsystem for Linux)

INSTALLATION:
1. Double-click INSTALL_WINDOWS.bat
2. Follow the prompts
3. Done!

IF WSL IS NOT INSTALLED:
1. Open PowerShell as Administrator
2. Run: wsl --install
3. Restart your computer
4. Run INSTALL_WINDOWS.bat again

USAGE:
After installation, open WSL terminal and run:
  retardio-status    - Check node status
  retardio-mine 10   - Mine 10 blocks
  retardio help      - Show all commands

Or from PowerShell/CMD:
  wsl retardio-status
  wsl retardio-mine 10

FEATURES:
✓ Pre-built binaries (no compilation needed)
✓ One-click installer
✓ Automatic node configuration
✓ Built-in mining commands
✓ Easy peer connection

SUPPORT:
For help, see WINDOWS_COMMANDS.md

EOF

# Create the zip package
echo "Creating zip package..."
zip -r "${PACKAGE_NAME}.zip" "$PACKAGE_NAME/" > /dev/null 2>&1

# Get package size
SIZE=$(du -h "${PACKAGE_NAME}.zip" | cut -f1)

# Clean up directory
rm -rf "$PACKAGE_NAME"

echo ""
echo "╔══════════════════════════════════════════════════════╗"
echo "║       ✓ WINDOWS PACKAGE CREATED! ✓                  ║"
echo "╚══════════════════════════════════════════════════════╝"
echo ""
echo "Package: ${PACKAGE_NAME}.zip"
echo "Size: $SIZE"
echo ""
echo "Windows users can:"
echo "1. Download ${PACKAGE_NAME}.zip"
echo "2. Extract it"
echo "3. Run INSTALL_WINDOWS.bat"
echo ""
echo "Done!"
echo ""
