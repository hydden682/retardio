#!/bin/bash

# Retardio Installer Script
# Works on Linux, Mac, and Windows (via WSL)

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Configuration
INSTALL_DIR="$HOME/.retardio"
BIN_DIR="$HOME/.local/bin"
DATA_DIR="$HOME/.retardio/data"

echo ""
echo "╔══════════════════════════════════════════════════════╗"
echo "║         Retardio Installer                           ║"
echo "╚══════════════════════════════════════════════════════╝"
echo ""

# Check if retardiod binary exists in current directory
if [ ! -f "./retardiod" ]; then
    echo -e "${RED}Error: retardiod binary not found in current directory!${NC}"
    echo ""
    echo "This installer must be run from the extracted package directory."
    exit 1
fi

# Create directories
echo -e "${BLUE}Creating directories...${NC}"
mkdir -p "$INSTALL_DIR"
mkdir -p "$BIN_DIR"
mkdir -p "$DATA_DIR"

# Copy binaries
echo -e "${BLUE}Installing binaries...${NC}"
cp retardiod "$INSTALL_DIR/"
cp retardio-cli "$INSTALL_DIR/"
chmod +x "$INSTALL_DIR/retardiod"
chmod +x "$INSTALL_DIR/retardio-cli"

# Create symlinks in PATH
echo -e "${BLUE}Creating command aliases...${NC}"
ln -sf "$INSTALL_DIR/retardiod" "$BIN_DIR/retardiod"
ln -sf "$INSTALL_DIR/retardio-cli" "$BIN_DIR/retardio"
ln -sf "$INSTALL_DIR/retardio-cli" "$BIN_DIR/retardio-cli"

# Make sure BIN_DIR is in PATH
if [[ ":$PATH:" != *":$BIN_DIR:"* ]]; then
    echo -e "${YELLOW}Adding $BIN_DIR to PATH...${NC}"
    echo "" >> "$HOME/.bashrc"
    echo "# Retardio binaries" >> "$HOME/.bashrc"
    echo "export PATH=\"\$HOME/.local/bin:\$PATH\"" >> "$HOME/.bashrc"
    export PATH="$BIN_DIR:$PATH"
fi

# Create helper scripts
echo -e "${BLUE}Creating helper scripts...${NC}"

# retardio-status script
cat > "$BIN_DIR/retardio-status" << 'EOF'
#!/bin/bash
echo "=== Retardio Status ==="
echo ""
echo "Blockchain:"
retardio getblockchaininfo 2>/dev/null | grep -E "blocks|difficulty|chain"
echo ""
echo "Network:"
PEERS=$(retardio getconnectioncount 2>/dev/null)
echo "  Peers: $PEERS"
echo ""
echo "Wallet:"
BALANCE=$(retardio getbalance 2>/dev/null)
echo "  Balance: $BALANCE RET"
ADDRESS=$(retardio getnewaddress 2>/dev/null | head -1)
echo "  Address: $ADDRESS"
echo ""
EOF
chmod +x "$BIN_DIR/retardio-status"

# retardio-mine script
cat > "$BIN_DIR/retardio-mine" << 'EOF'
#!/bin/bash
BLOCKS=${1:-1}
echo "Mining $BLOCKS blocks..."
retardio generatetoaddress $BLOCKS $(retardio getnewaddress) > /dev/null
echo "✓ Mined $BLOCKS blocks!"
retardio-status
EOF
chmod +x "$BIN_DIR/retardio-mine"

# Create default configuration
echo -e "${BLUE}Creating configuration...${NC}"
cat > "$DATA_DIR/retardio.conf" << EOF
# Retardio Configuration
server=1
daemon=1
listen=1
port=18333
rpcport=18332
rpcallowip=127.0.0.1
datadir=$DATA_DIR

# Mining
gen=0

# Network
maxconnections=50
EOF

# Ask about peer connection
echo ""
echo -e "${GREEN}Do you want to connect to a peer node?${NC}"
echo -e "If you have another Retardio node running, enter its IP address."
echo -e "Otherwise, press Enter to skip."
echo ""
read -p "Peer IP address (or press Enter): " PEER_IP

if [ ! -z "$PEER_IP" ]; then
    echo "addnode=$PEER_IP:18333" >> "$DATA_DIR/retardio.conf"
    echo -e "${GREEN}✓ Peer added to configuration${NC}"
fi

# Ask about firewall
echo ""
echo -e "${GREEN}Do you want to open firewall port 18333?${NC}"
echo -e "This allows other nodes to connect to you."
echo ""
read -p "Open firewall? (y/n): " OPEN_FW

if [ "$OPEN_FW" = "y" ] || [ "$OPEN_FW" = "Y" ]; then
    if command -v ufw &> /dev/null; then
        sudo ufw allow 18333/tcp
        echo -e "${GREEN}✓ Firewall port opened${NC}"
    else
        echo -e "${YELLOW}⚠ ufw not found, please open port 18333 manually${NC}"
    fi
fi

# Start the node
echo ""
echo -e "${BLUE}Starting Retardio node...${NC}"
$INSTALL_DIR/retardiod -datadir="$DATA_DIR" -daemon

# Wait for node to start
sleep 3

# Check if it's running
if retardio getblockchaininfo > /dev/null 2>&1; then
    echo ""
    echo "╔══════════════════════════════════════════════════════╗"
    echo "║       ✓ INSTALLATION COMPLETE! ✓                    ║"
    echo "╚══════════════════════════════════════════════════════╝"
    echo ""
    echo -e "${GREEN}Retardio is now running!${NC}"
    echo ""
    echo "Useful commands:"
    echo "  retardio-status    - Check node status"
    echo "  retardio-mine 10   - Mine 10 blocks"
    echo "  retardio help      - Show all RPC commands"
    echo "  retardio stop      - Stop the node"
    echo ""
    echo "Configuration file: $DATA_DIR/retardio.conf"
    echo "Data directory: $DATA_DIR"
    echo ""

    # Show initial status
    retardio-status
else
    echo ""
    echo -e "${RED}⚠ Node may not have started correctly${NC}"
    echo "Check logs: $DATA_DIR/debug.log"
    echo ""
fi
