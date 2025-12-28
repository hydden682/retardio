#!/bin/bash
# Retardio Node Setup for Raspberry Pi 5
# Tested on Raspberry Pi OS (64-bit)

set -e

echo "=================================="
echo "Retardio Node Setup for RPi5"
echo "=================================="

# Generate secure random password
RPC_PASSWORD=$(openssl rand -hex 24)
echo ""
echo "Generated RPC Password: $RPC_PASSWORD"
echo "(Save this - you'll need it for wallet access)"
echo ""

# Check architecture
ARCH=$(uname -m)
if [[ "$ARCH" != "aarch64" ]]; then
    echo "Warning: Expected aarch64 (ARM64), got $ARCH"
    echo "This script is optimized for Raspberry Pi 5"
fi

# Install dependencies
echo ""
echo "[1/6] Installing build dependencies..."
sudo apt-get update
sudo apt-get install -y \
    build-essential libtool autotools-dev automake pkg-config \
    bsdmainutils python3 libssl-dev libevent-dev libboost-all-dev \
    libsqlite3-dev libzmq3-dev git

# Clone repo if not already in it
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "$SCRIPT_DIR/../autogen.sh" ]]; then
    cd "$SCRIPT_DIR/.."
    echo "[2/6] Already in retardio-coin directory"
else
    echo "[2/6] Cloning retardio-coin..."
    cd ~
    if [[ ! -d "retardio-coin" ]]; then
        git clone https://github.com/hydden682/retardio.git retardio-coin
    fi
    cd retardio-coin
fi

# Build
echo ""
echo "[3/6] Building Retardio (this takes 15-30 minutes on RPi5)..."
./autogen.sh
./configure --without-gui --disable-tests --disable-bench --with-incompatible-bdb
make -j4

# Create data directory
echo ""
echo "[4/6] Setting up data directory..."
mkdir -p ~/.retardio/data

# Create config
echo ""
echo "[5/6] Creating configuration..."
cat > ~/.retardio/data/retardio.conf << EOF
# Retardio Node Configuration for RPi5
server=1
daemon=1
listen=1
port=18333
rpcport=18332

# RPC credentials
rpcuser=retardio
rpcpassword=$RPC_PASSWORD

# Allow local RPC
rpcallowip=127.0.0.1
rpcbind=127.0.0.1

# Data directory
datadir=$HOME/.retardio/data

# Performance settings for RPi5
dbcache=512
maxmempool=100
maxconnections=20

# Connect to main node
addnode=96.236.21.232:18333

# Mining disabled by default (enable with gen=1)
gen=0
EOF

# Save credentials for future reference
cat > ~/.retardio/credentials << EOF
# Retardio RPC Credentials - KEEP SECURE
RPC_USER=retardio
RPC_PASSWORD=$RPC_PASSWORD
EOF
chmod 600 ~/.retardio/credentials

# Create helper scripts
echo ""
echo "[6/6] Creating helper scripts..."

# Start script
cat > ~/retardio-start.sh << 'EOF'
#!/bin/bash
cd ~/retardio-coin
./src/retardiod -datadir=$HOME/.retardio/data -daemon
sleep 3
./src/retardio-cli -datadir=$HOME/.retardio/data getblockchaininfo
EOF
chmod +x ~/retardio-start.sh

# CLI wrapper
cat > ~/retardio-cli.sh << 'EOF'
#!/bin/bash
~/retardio-coin/src/retardio-cli -datadir=$HOME/.retardio/data "$@"
EOF
chmod +x ~/retardio-cli.sh

# Status script
cat > ~/retardio-status.sh << 'EOF'
#!/bin/bash
echo "=== Retardio Node Status ==="
echo ""
~/retardio-coin/src/retardio-cli -datadir=$HOME/.retardio/data getblockchaininfo 2>/dev/null || echo "Node not running"
echo ""
echo "=== Peers ==="
~/retardio-coin/src/retardio-cli -datadir=$HOME/.retardio/data getpeerinfo 2>/dev/null | grep -E '"addr"|"subver"' || echo "No peers"
echo ""
echo "=== Mining Info ==="
~/retardio-coin/src/retardio-cli -datadir=$HOME/.retardio/data getmininginfo 2>/dev/null || echo "N/A"
EOF
chmod +x ~/retardio-status.sh

# Mining script
cat > ~/retardio-mine.sh << 'EOF'
#!/bin/bash
CLI="$HOME/retardio-coin/src/retardio-cli -datadir=$HOME/.retardio/data"

# Check if wallet exists
if ! $CLI listwallets 2>/dev/null | grep -q "mining"; then
    echo "Creating mining wallet..."
    $CLI createwallet "mining"
fi

# Get or create mining address
ADDRESS=$($CLI -rpcwallet=mining getnewaddress "mining" "legacy" 2>/dev/null)
if [[ -z "$ADDRESS" ]]; then
    ADDRESS=$($CLI -rpcwallet=mining getaddressesbyaccount "" 2>/dev/null | grep -oP 'R[a-zA-Z0-9]+' | head -1)
fi

echo "Mining to address: $ADDRESS"
echo "Mining 1 block..."
$CLI generatetoaddress 1 "$ADDRESS"
EOF
chmod +x ~/retardio-mine.sh

echo ""
echo "=================================="
echo "Setup Complete!"
echo "=================================="
echo ""
echo "Helper scripts created in your home directory:"
echo "  ~/retardio-start.sh  - Start the node"
echo "  ~/retardio-cli.sh    - Run CLI commands"
echo "  ~/retardio-status.sh - Check node status"
echo "  ~/retardio-mine.sh   - Mine a block"
echo ""
echo "Quick start:"
echo "  ~/retardio-start.sh"
echo ""
echo "The node will connect to the main node at 96.236.21.232:18333"
echo ""
