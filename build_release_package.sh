#!/bin/bash
#
# Build Complete Release Package
# This creates a ready-to-use installer with pre-built binaries
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RELEASE_DIR="${SCRIPT_DIR}/retardio_release"
VERSION="1.0.0"

echo "╔══════════════════════════════════════════════════════╗"
echo "║                                                      ║"
echo "║     Building Retardio Release Package               ║"
echo "║                                                      ║"
echo "╚══════════════════════════════════════════════════════╝"
echo ""

# Step 1: Build binaries
echo "[1/6] Building Retardio binaries..."
if [ ! -d "build" ]; then
    mkdir build && cd build
    cmake .. -DBUILD_GUI=OFF
    cd ..
fi

cd build
make -j$(nproc)
cd ..

if [ ! -f "build/bin/retardiod" ] || [ ! -f "build/bin/retardio-cli" ]; then
    echo "ERROR: Build failed! Binaries not found."
    exit 1
fi

echo "✓ Binaries built successfully"
echo ""

# Step 2: Create release directory
echo "[2/6] Creating release package..."
rm -rf "$RELEASE_DIR"
mkdir -p "$RELEASE_DIR"

# Copy binaries
mkdir -p "$RELEASE_DIR/bin"
cp build/bin/retardiod "$RELEASE_DIR/bin/"
cp build/bin/retardio-cli "$RELEASE_DIR/bin/"
chmod +x "$RELEASE_DIR/bin/"*

echo "✓ Copied binaries"

# Step 3: Copy scripts
cp retardio_master_setup.sh "$RELEASE_DIR/"
cp easy_setup.sh "$RELEASE_DIR/"
cp connect_nodes.sh "$RELEASE_DIR/"
cp easy_setup.bat "$RELEASE_DIR/"
cp connect_nodes.bat "$RELEASE_DIR/"
chmod +x "$RELEASE_DIR/"*.sh

echo "✓ Copied setup scripts"

# Step 4: Copy documentation
cp START_HERE.md "$RELEASE_DIR/"
cp ONE_COMMAND_SETUP.md "$RELEASE_DIR/"
cp QUICK_TEST.md "$RELEASE_DIR/"

echo "✓ Copied documentation"

# Step 5: Create simple installer script
cat > "$RELEASE_DIR/INSTALL.sh" << 'EOFINSTALL'
#!/bin/bash
#
# Retardio One-Click Installer
# Just run this script and answer a few questions!
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="${HOME}/.retardio"
BIN_DIR="${HOME}/.local/bin"

clear
echo "╔══════════════════════════════════════════════════════╗"
echo "║                                                      ║"
echo "║         RETARDIO ONE-CLICK INSTALLER                 ║"
echo "║                                                      ║"
echo "║  This will install Retardio to your system          ║"
echo "║                                                      ║"
echo "╚══════════════════════════════════════════════════════╝"
echo ""

# Create directories
mkdir -p "$INSTALL_DIR"
mkdir -p "$BIN_DIR"

echo "[1/5] Installing binaries..."
cp "${SCRIPT_DIR}/bin/retardiod" "$BIN_DIR/"
cp "${SCRIPT_DIR}/bin/retardio-cli" "$BIN_DIR/"
chmod +x "$BIN_DIR/retardiod" "$BIN_DIR/retardio-cli"

# Add to PATH if not already
if [[ ":$PATH:" != *":$BIN_DIR:"* ]]; then
    echo "export PATH=\"\$PATH:$BIN_DIR\"" >> ~/.bashrc
    export PATH="$PATH:$BIN_DIR"
fi

echo "✓ Binaries installed to $BIN_DIR"

# Generate config
echo ""
echo "[2/5] Creating configuration..."

RPC_PASSWORD=$(openssl rand -base64 32 2>/dev/null || cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)

cat > "${INSTALL_DIR}/retardio.conf" << EOF
server=1
listen=1
daemon=1
port=18333
rpcport=18332
rpcuser=retardiouser
rpcpassword=${RPC_PASSWORD}
rpcbind=127.0.0.1
rpcallowip=127.0.0.1
dbcache=450
maxmempool=300
txindex=1
maxconnections=125
EOF

echo "✓ Configuration created"
echo "  RPC Password: ${RPC_PASSWORD}"

# Add peers
echo ""
echo "[3/5] Network setup..."
read -p "Do you have a peer IP address to connect to? (y/N): " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    read -p "Enter peer IP address: " peer_ip
    read -p "Enter peer port (default 18333): " peer_port
    peer_port=${peer_port:-18333}
    echo "addnode=${peer_ip}:${peer_port}" >> "${INSTALL_DIR}/retardio.conf"
    echo "✓ Added peer: ${peer_ip}:${peer_port}"
else
    echo "⚠ No peers added (you can add later)"
fi

# Firewall
echo ""
echo "[4/5] Firewall configuration..."
if command -v ufw &> /dev/null; then
    read -p "Open port 18333 in firewall? (y/N): " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        sudo ufw allow 18333/tcp
        echo "✓ Firewall configured"
    fi
fi

# Start node
echo ""
echo "[5/5] Starting Retardio node..."
retardiod -datadir="$INSTALL_DIR"
sleep 5

# Create wallet
retardio-cli -datadir="$INSTALL_DIR" createwallet "mining" >/dev/null 2>&1 || true
MINING_ADDRESS=$(retardio-cli -datadir="$INSTALL_DIR" getnewaddress "mining" "legacy" 2>/dev/null)

echo "✓ Node started"
echo "✓ Wallet created"
echo "✓ Mining address: ${MINING_ADDRESS}"

# Save address
echo "$MINING_ADDRESS" > "${INSTALL_DIR}/mining_address.txt"

# Create shortcuts
cat > "$BIN_DIR/retardio" << 'EOFCLI'
#!/bin/bash
retardio-cli -datadir="${HOME}/.retardio" "$@"
EOFCLI
chmod +x "$BIN_DIR/retardio"

cat > "$BIN_DIR/retardio-mine" << 'EOFMINE'
#!/bin/bash
BLOCKS=${1:-10}
ADDRESS=$(cat ~/.retardio/mining_address.txt)
echo "Mining $BLOCKS blocks to $ADDRESS..."
retardio-cli -datadir="${HOME}/.retardio" generatetoaddress $BLOCKS $ADDRESS
EOFMINE
chmod +x "$BIN_DIR/retardio-mine"

cat > "$BIN_DIR/retardio-status" << 'EOFSTATUS'
#!/bin/bash
echo "=== Retardio Status ==="
echo ""
echo "Blockchain:"
retardio-cli -datadir="${HOME}/.retardio" getblockchaininfo | grep -E '"chain"|"blocks"|"difficulty"'
echo ""
echo "Network:"
echo "  Peers: $(retardio-cli -datadir="${HOME}/.retardio" getconnectioncount)"
echo ""
echo "Wallet:"
echo "  Balance: $(retardio-cli -datadir="${HOME}/.retardio" getbalance) RET"
echo "  Address: $(cat ~/.retardio/mining_address.txt)"
EOFSTATUS
chmod +x "$BIN_DIR/retardio-status"

# Summary
echo ""
echo "╔══════════════════════════════════════════════════════╗"
echo "║                                                      ║"
echo "║              ✓ INSTALLATION COMPLETE! ✓             ║"
echo "║                                                      ║"
echo "╚══════════════════════════════════════════════════════╝"
echo ""
echo "Quick Commands:"
echo "  retardio getblockchaininfo    - Check node status"
echo "  retardio getconnectioncount   - Check peers"
echo "  retardio getbalance           - Check balance"
echo "  retardio-mine 10              - Mine 10 blocks"
echo "  retardio-status               - Show full status"
echo ""
echo "Config: ${INSTALL_DIR}/retardio.conf"
echo "Mining address: ${MINING_ADDRESS}"
echo ""
echo "To stop: retardio stop"
echo ""
EOFINSTALL

chmod +x "$RELEASE_DIR/INSTALL.sh"

echo "✓ Created one-click installer"

# Step 6: Create README
cat > "$RELEASE_DIR/README.txt" << 'EOFREADME'
╔══════════════════════════════════════════════════════╗
║                                                      ║
║              RETARDIO - READY TO USE                 ║
║                                                      ║
╚══════════════════════════════════════════════════════╝

This package contains EVERYTHING you need - pre-built and ready!

QUICK START:
============

1. Extract this folder anywhere

2. Run the installer:

   Linux/Mac:
   ----------
   chmod +x INSTALL.sh
   ./INSTALL.sh

   Windows (WSL):
   --------------
   wsl bash INSTALL.sh

3. Answer 2 simple questions:
   - Peer IP? (your friend's IP or skip)
   - Open firewall? (yes)

4. Done! Node is running!


WHAT YOU GET:
=============
✓ Pre-built binaries (no compilation needed!)
✓ Automatic configuration
✓ Wallet created automatically
✓ Mining address generated
✓ Simple commands: retardio, retardio-mine, retardio-status


SYSTEM REQUIREMENTS:
====================
- Linux, macOS, or Windows with WSL
- 4GB RAM
- 10GB disk space
- Internet connection (for first sync)


AFTER INSTALLATION:
===================

Check status:
  retardio-status

Mine blocks:
  retardio-mine 10

Check peers:
  retardio getconnectioncount

Stop node:
  retardio stop


CONNECTING TO FRIENDS:
======================
1. Find your IP: ip addr show
2. Share your IP with friends
3. They run installer and enter your IP when asked
4. Both nodes connect automatically!


NO TECHNICAL KNOWLEDGE REQUIRED!
=================================
Everything is pre-built and configured.
Just run INSTALL.sh and you're mining!


SUPPORT:
========
- See START_HERE.md for detailed guide
- See QUICK_TEST.md for testing
- Config file: ~/.retardio/retardio.conf


Happy mining! 🚀
EOFREADME

echo "✓ Created README"
echo ""

# Step 6: Create archive
echo "[6/6] Creating release archive..."
cd "$SCRIPT_DIR"
tar -czf "retardio_v${VERSION}_ready_to_use.tar.gz" -C "$RELEASE_DIR" .

FILE_SIZE=$(du -h "retardio_v${VERSION}_ready_to_use.tar.gz" | cut -f1)

echo ""
echo "╔══════════════════════════════════════════════════════╗"
echo "║                                                      ║"
echo "║         ✓ RELEASE PACKAGE CREATED! ✓                ║"
echo "║                                                      ║"
echo "╚══════════════════════════════════════════════════════╝"
echo ""
echo "Package: retardio_v${VERSION}_ready_to_use.tar.gz"
echo "Size: ${FILE_SIZE}"
echo ""
echo "This package contains:"
echo "  ✓ Pre-built binaries (retardiod, retardio-cli)"
echo "  ✓ One-click installer (INSTALL.sh)"
echo "  ✓ Auto-configuration"
echo "  ✓ Helper scripts"
echo "  ✓ Complete documentation"
echo ""
echo "HOW TO USE:"
echo "  1. Send this .tar.gz file to anyone"
echo "  2. They extract it"
echo "  3. They run: ./INSTALL.sh"
echo "  4. Answer 2 questions"
echo "  5. Done! Node is running!"
echo ""
echo "NO compilation, NO technical knowledge needed!"
echo ""
echo "Test it yourself first:"
echo "  tar -xzf retardio_v${VERSION}_ready_to_use.tar.gz"
echo "  cd retardio_release"
echo "  ./INSTALL.sh"
echo ""
