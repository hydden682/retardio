#!/bin/bash
#
# RETARDIO MASTER SETUP
# All-in-one automatic setup script
#
# This script does EVERYTHING:
# - Rebuilds the node with networking fix
# - Configures the node
# - Connects to peers
# - Starts and syncs the node
# - Patches RPC for solo mining
# - Sets up stratum pool (ckpool)
# - Creates mining scripts
#
# Just run this script and answer a few questions!
#

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m'

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="${SCRIPT_DIR}/build"
RETARDIOD="${BUILD_DIR}/bin/retardiod"
RETARDIO_CLI="${BUILD_DIR}/bin/retardio-cli"
DATADIR="${HOME}/.retardio"
CONF_FILE="${DATADIR}/retardio.conf"
CKPOOL_DIR="${HOME}/ckpool"

# Banner
clear
cat << "EOF"
╔══════════════════════════════════════════════════════╗
║                                                      ║
║       ██████╗ ███████╗████████╗ █████╗ ██████╗      ║
║       ██╔══██╗██╔════╝╚══██╔══╝██╔══██╗██╔══██╗     ║
║       ██████╔╝█████╗     ██║   ███████║██████╔╝     ║
║       ██╔══██╗██╔══╝     ██║   ██╔══██║██╔══██╗     ║
║       ██║  ██║███████╗   ██║   ██║  ██║██║  ██║     ║
║       ╚═╝  ╚═╝╚══════╝   ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝     ║
║                                                      ║
║           MASTER SETUP - ONE SCRIPT TO RULE          ║
║                    THEM ALL                          ║
║                                                      ║
║  This will automatically set up:                     ║
║  ✓ Rebuild node with network fix                    ║
║  ✓ Configure node settings                          ║
║  ✓ Connect to peer network                          ║
║  ✓ Sync blockchain                                  ║
║  ✓ Patch RPC for solo mining                        ║
║  ✓ Install & configure stratum pool                 ║
║  ✓ Create mining scripts                            ║
║                                                      ║
║  Just answer a few questions and everything         ║
║  will be set up automatically!                      ║
║                                                      ║
╚══════════════════════════════════════════════════════╝
EOF
echo ""

# Functions
print_step() {
    echo -e "${BOLD}${BLUE}┌─────────────────────────────────────────────────────┐${NC}"
    echo -e "${BOLD}${BLUE}│${NC} ${BOLD}$1${NC}"
    echo -e "${BOLD}${BLUE}└─────────────────────────────────────────────────────┘${NC}"
}

print_success() { echo -e "${GREEN}✓${NC} $1"; }
print_error() { echo -e "${RED}✗${NC} $1"; }
print_warning() { echo -e "${YELLOW}⚠${NC} $1"; }
print_info() { echo -e "${BLUE}ℹ${NC} $1"; }

# Check environment
print_step "STEP 1: Environment Check"
echo ""

if [ ! -d "${SCRIPT_DIR}/src" ]; then
    print_error "Please run this script from the retardio-coin directory!"
    exit 1
fi

print_success "Running from correct directory"

# Check dependencies
print_info "Checking build dependencies..."
MISSING_DEPS=()

for cmd in make cmake gcc g++ autoconf automake libtool pkg-config; do
    if ! command -v $cmd &> /dev/null; then
        MISSING_DEPS+=($cmd)
    fi
done

if [ ${#MISSING_DEPS[@]} -gt 0 ]; then
    print_warning "Missing dependencies: ${MISSING_DEPS[*]}"
    read -p "Install missing dependencies? (requires sudo) (y/N): " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        if command -v apt-get &> /dev/null; then
            sudo apt-get update
            sudo apt-get install -y build-essential cmake libtool autotools-dev automake pkg-config \
                bsdmainutils python3 libevent-dev libboost-system-dev libboost-filesystem-dev \
                libboost-test-dev libboost-thread-dev libsqlite3-dev libminiupnpc-dev \
                libzmq3-dev libqrencode-dev git redis-server
            print_success "Dependencies installed"
        else
            print_error "Could not install dependencies automatically. Please install manually."
            exit 1
        fi
    else
        print_warning "Some features may not work without dependencies"
    fi
else
    print_success "All dependencies found"
fi

echo ""

# Step 2: Rebuild node
print_step "STEP 2: Building Retardio Node"
echo ""

if [ ! -f "$RETARDIOD" ] || [ "${SCRIPT_DIR}/src/chainparamsseeds.h" -nt "$RETARDIOD" ]; then
    print_warning "Build required..."

    if [ ! -d "$BUILD_DIR" ]; then
        mkdir -p "$BUILD_DIR"
        cd "$BUILD_DIR"
        print_info "Configuring build..."
        cmake .. -DBUILD_GUI=OFF || {
            print_error "CMake configuration failed!"
            exit 1
        }
    else
        cd "$BUILD_DIR"
    fi

    print_info "Compiling (this takes 5-15 minutes)..."
    echo ""
    make -j$(nproc) 2>&1 | tail -30

    if [ -f "$RETARDIOD" ]; then
        print_success "Build completed!"
    else
        print_error "Build failed!"
        exit 1
    fi

    cd "$SCRIPT_DIR"
else
    print_success "Binaries up to date (skipping build)"
fi

echo ""

# Step 3: Patch RPC for solo mining
print_step "STEP 3: Patching RPC for Solo Mining"
echo ""

print_info "Checking if getblocktemplate needs patching..."

if grep -q "Bitcoin Knots is not connected!" "${SCRIPT_DIR}/src/rpc/mining.cpp" 2>/dev/null; then
    print_warning "Found connection check in mining.cpp - needs patching"

    cat > /tmp/mining_cpp.patch << 'PATCHEOF'
--- a/src/rpc/mining.cpp
+++ b/src/rpc/mining.cpp
@@ -577,8 +577,10 @@
     NodeContext& node = EnsureAnyNodeContext(request.context);
     ChainstateManager& chainman = EnsureChainman(node);

-    if (!node.connman)
-        throw JSONRPCError(RPC_CLIENT_P2P_DISABLED, "Bitcoin Knots is not connected!");
+    // Allow solo mining without peers for altcoin
+    // Commented out for Retardio solo mining support
+    // if (!node.connman)
+    //     throw JSONRPCError(RPC_CLIENT_P2P_DISABLED, "Bitcoin Knots is not connected!");

     if (chainman.IsInitialBlockDownload()) {
         throw JSONRPCError(RPC_CLIENT_IN_INITIAL_DOWNLOAD, PACKAGE_NAME " is in initial sync and waiting for blocks...");
PATCHEOF

    cd "$SCRIPT_DIR"
    if patch -p1 < /tmp/mining_cpp.patch 2>/dev/null; then
        print_success "Patched mining.cpp successfully"

        print_info "Rebuilding with patch..."
        cd "$BUILD_DIR"
        make -j$(nproc) 2>&1 | tail -10
        cd "$SCRIPT_DIR"
        print_success "Rebuild complete"
    else
        print_warning "Patch failed or already applied - checking manually..."

        # Manual sed replacement as fallback
        sed -i.bak 's/if (!node.connman)/\/\/ if (!node.connman)/' "${SCRIPT_DIR}/src/rpc/mining.cpp" 2>/dev/null || true
        sed -i.bak 's/throw JSONRPCError(RPC_CLIENT_P2P_DISABLED, "Bitcoin Knots is not connected!");/\/\/ throw JSONRPCError(RPC_CLIENT_P2P_DISABLED, "Bitcoin Knots is not connected!");/' "${SCRIPT_DIR}/src/rpc/mining.cpp" 2>/dev/null || true

        if grep -q "// if (!node.connman)" "${SCRIPT_DIR}/src/rpc/mining.cpp"; then
            print_success "Manually patched mining.cpp"
            cd "$BUILD_DIR"
            make -j$(nproc) 2>&1 | tail -10
            cd "$SCRIPT_DIR"
        else
            print_warning "Could not patch - solo mining may not work"
        fi
    fi
else
    print_success "RPC already patched or not needed"
fi

echo ""

# Step 4: Configure node
print_step "STEP 4: Configuring Node"
echo ""

mkdir -p "$DATADIR"

if [ -f "$CONF_FILE" ]; then
    print_warning "Configuration exists. Backup and recreate? (y/N):"
    read -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        mv "$CONF_FILE" "${CONF_FILE}.backup.$(date +%s)"
        print_success "Backed up old config"
    else
        print_info "Keeping existing config"
        SKIP_CONFIG=1
    fi
fi

if [ -z "$SKIP_CONFIG" ]; then
    RPC_PASSWORD=$(openssl rand -base64 32 2>/dev/null || cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)

    cat > "$CONF_FILE" << EOF
# Retardio Configuration
# Generated by retardio_master_setup.sh on $(date)

server=1
listen=1
daemon=1

# Network
port=18333
maxconnections=125

# RPC
rpcport=18332
rpcuser=retardiouser
rpcpassword=${RPC_PASSWORD}
rpcbind=127.0.0.1
rpcallowip=127.0.0.1

# Performance
dbcache=450
maxmempool=300
par=4

# Indexing
txindex=1

# Mining
blockminsize=0
blockmaxsize=4000000

# Logging
debug=0
EOF

    print_success "Configuration created"
    print_info "RPC Password: ${YELLOW}${RPC_PASSWORD}${NC}"
fi

echo ""

# Step 5: Add peers
print_step "STEP 5: Network Peers"
echo ""

read -p "Do you have a peer node IP to add? (y/N): " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    while true; do
        read -p "Peer IP address (or 'done'): " peer_ip
        [ "$peer_ip" = "done" ] && break

        read -p "Peer port (default 18333): " peer_port
        peer_port=${peer_port:-18333}

        echo "addnode=${peer_ip}:${peer_port}" >> "$CONF_FILE"
        print_success "Added: ${peer_ip}:${peer_port}"

        read -p "Add another? (y/N): " -n 1 -r
        echo ""
        [[ ! $REPLY =~ ^[Yy]$ ]] && break
    done
else
    print_warning "No peers added - you can add later in $CONF_FILE"
fi

echo ""

# Step 6: Firewall
print_step "STEP 6: Firewall Setup"
echo ""

if command -v ufw &> /dev/null; then
    if ! sudo ufw status | grep -q "18333.*ALLOW"; then
        read -p "Open port 18333 in UFW? (y/N): " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            sudo ufw allow 18333/tcp
            sudo ufw allow 3333/tcp  # For stratum
            print_success "Ports opened"
        fi
    else
        print_success "Port already open"
    fi
else
    print_warning "Please open ports 18333 (P2P) and 3333 (Stratum) manually"
fi

echo ""

# Step 7: Start node
print_step "STEP 7: Starting Node"
echo ""

if pgrep -x "retardiod" > /dev/null; then
    print_warning "Node already running"
else
    "$RETARDIOD" -datadir="$DATADIR"
    sleep 5
    print_success "Node started"
fi

# Step 8: Create wallet
print_step "STEP 8: Wallet Setup"
echo ""

WALLET_LIST=$("$RETARDIO_CLI" -datadir="$DATADIR" listwallets 2>/dev/null || echo "[]")

if [ "$WALLET_LIST" = "[]" ]; then
    "$RETARDIO_CLI" -datadir="$DATADIR" createwallet "mining" > /dev/null
    print_success "Wallet created"
else
    print_success "Wallet exists"
fi

MINING_ADDRESS=$("$RETARDIO_CLI" -datadir="$DATADIR" getnewaddress "mining" "legacy" 2>/dev/null)
echo "$MINING_ADDRESS" > "${DATADIR}/mining_address.txt"

print_success "Mining address: ${GREEN}${MINING_ADDRESS}${NC}"
print_info "Saved to: ${DATADIR}/mining_address.txt"

echo ""

# Step 9: Wait for initial sync
print_step "STEP 9: Blockchain Sync"
echo ""

print_info "Waiting for node to sync..."
sleep 3

BLOCK_COUNT=$("$RETARDIO_CLI" -datadir="$DATADIR" getblockcount 2>/dev/null || echo "0")
PEER_COUNT=$("$RETARDIO_CLI" -datadir="$DATADIR" getconnectioncount 2>/dev/null || echo "0")

print_info "Current block: ${BLOCK_COUNT}"
print_info "Connected peers: ${PEER_COUNT}"

if [ "$PEER_COUNT" -eq 0 ]; then
    print_warning "No peers connected yet - may need to wait or add peers"
else
    print_success "Connected to ${PEER_COUNT} peer(s)"
fi

# Mine genesis blocks if blockchain is empty
if [ "$BLOCK_COUNT" -eq 0 ]; then
    print_warning "Blockchain is empty"
    read -p "Mine initial 100 blocks for testing? (y/N): " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_info "Mining 100 blocks (this may take a minute)..."
        "$RETARDIO_CLI" -datadir="$DATADIR" generatetoaddress 100 "$MINING_ADDRESS" > /dev/null
        print_success "Mined 100 blocks!"
    fi
fi

echo ""

# Step 10: Install ckpool
print_step "STEP 10: Installing Stratum Pool (ckpool)"
echo ""

read -p "Install and configure ckpool stratum server? (y/N): " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    if [ ! -d "$CKPOOL_DIR" ]; then
        print_info "Cloning ckpool..."
        git clone https://github.com/ckolivas/ckpool.git "$CKPOOL_DIR"

        cd "$CKPOOL_DIR"
        print_info "Building ckpool..."
        ./autogen.sh
        ./configure
        make -j$(nproc)

        if [ -f "${CKPOOL_DIR}/src/ckpool" ]; then
            print_success "ckpool built successfully"
        else
            print_error "ckpool build failed"
            cd "$SCRIPT_DIR"
        fi
    else
        print_success "ckpool already installed"
    fi

    # Configure ckpool
    if [ -d "$CKPOOL_DIR" ]; then
        print_info "Configuring ckpool..."

        RPC_USER=$(grep "rpcuser=" "$CONF_FILE" | cut -d'=' -f2)
        RPC_PASS=$(grep "rpcpassword=" "$CONF_FILE" | cut -d'=' -f2)

        cat > "${CKPOOL_DIR}/retardio.conf" << CKPOOLEOF
{
"btcd" : [
    {
        "url" : "127.0.0.1:18332",
        "auth" : "${RPC_USER}",
        "pass" : "${RPC_PASS}",
        "notify" : true
    }
],
"proxy" : "127.0.0.1:3333",
"btcaddress" : "${MINING_ADDRESS}",
"btcsig" : "/Retardio/",
"blockpoll" : 100,
"nonce1length" : 4,
"nonce2length" : 8,
"update_interval" : 30,
"serverurl" : [
    "127.0.0.1:3333",
    "stratum+tcp://127.0.0.1:3333"
],
"mindiff" : 1,
"startdiff" : 1,
"maxdiff" : 0
}
CKPOOLEOF

        print_success "ckpool configured"

        # Create start script
        cat > "${CKPOOL_DIR}/start_pool.sh" << 'STARTPOOL'
#!/bin/bash
CKPOOL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$CKPOOL_DIR"

echo "Starting ckpool stratum server..."
./src/ckpool -c retardio.conf

echo "ckpool is running!"
echo "Miners can connect to: stratum+tcp://YOUR_IP:3333"
STARTPOOL

        chmod +x "${CKPOOL_DIR}/start_pool.sh"

        print_success "Created start script: ${CKPOOL_DIR}/start_pool.sh"

        # Ask to start pool
        read -p "Start ckpool now? (y/N): " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            cd "$CKPOOL_DIR"
            ./start_pool.sh &
            sleep 2
            print_success "ckpool started on port 3333"
        fi
    fi
else
    print_info "Skipping ckpool installation"
fi

cd "$SCRIPT_DIR"
echo ""

# Step 11: Create helper scripts
print_step "STEP 11: Creating Helper Scripts"
echo ""

# CLI shortcut
cat > "${SCRIPT_DIR}/cli" << 'EOFCLI'
#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
"${SCRIPT_DIR}/build/bin/retardio-cli" -datadir="${HOME}/.retardio" "$@"
EOFCLI
chmod +x "${SCRIPT_DIR}/cli"
print_success "Created: ./cli (shortcut for retardio-cli)"

# Mining script
cat > "${SCRIPT_DIR}/mine.sh" << EOFMINE
#!/bin/bash
MINING_ADDRESS=\$(cat ~/.retardio/mining_address.txt)
BLOCKS=\${1:-10}

echo "Mining \$BLOCKS blocks to \$MINING_ADDRESS..."
./cli generatetoaddress \$BLOCKS \$MINING_ADDRESS

echo ""
echo "Balance:"
./cli getbalance
EOFMINE
chmod +x "${SCRIPT_DIR}/mine.sh"
print_success "Created: ./mine.sh [blocks] (quick mine script)"

# Status script
cat > "${SCRIPT_DIR}/status.sh" << 'EOFSTATUS'
#!/bin/bash
echo "=== Retardio Node Status ==="
echo ""
echo "Blockchain Info:"
./cli getblockchaininfo | grep -E '"chain"|"blocks"|"headers"|"difficulty"|"verificationprogress"'
echo ""
echo "Network:"
echo "  Peers: $(./cli getconnectioncount)"
echo ""
echo "Wallet:"
echo "  Balance: $(./cli getbalance) RET"
echo ""
echo "Mining Address:"
cat ~/.retardio/mining_address.txt
EOFSTATUS
chmod +x "${SCRIPT_DIR}/status.sh"
print_success "Created: ./status.sh (show node status)"

echo ""

# Final summary
print_step "SETUP COMPLETE!"
echo ""

cat << EOF
${GREEN}${BOLD}╔══════════════════════════════════════════════════════╗
║                                                      ║
║              🎉  ALL DONE! 🎉                        ║
║                                                      ║
╚══════════════════════════════════════════════════════╝${NC}

${BOLD}Your Retardio network is fully operational!${NC}

${BOLD}Node Information:${NC}
  • Data directory: ${DATADIR}
  • Config file: ${CONF_FILE}
  • Mining address: ${GREEN}${MINING_ADDRESS}${NC}
  • Block height: $(./cli getblockcount 2>/dev/null || echo "0")
  • Connected peers: $(./cli getconnectioncount 2>/dev/null || echo "0")

${BOLD}Ports:${NC}
  • P2P: 18333
  • RPC: 18332
  • Stratum: 3333 (if ckpool installed)

${BOLD}Quick Commands:${NC}
  ${BLUE}./cli getblockchaininfo${NC}     - Node status
  ${BLUE}./cli getconnectioncount${NC}    - Check peers
  ${BLUE}./cli getbalance${NC}            - Wallet balance
  ${BLUE}./mine.sh 10${NC}                - Mine 10 blocks
  ${BLUE}./status.sh${NC}                 - Full status report

${BOLD}Stratum Mining:${NC}
EOF

if [ -d "$CKPOOL_DIR" ]; then
    MY_IP=$(ip route get 8.8.8.8 2>/dev/null | grep -oP 'src \K\S+' || echo "YOUR_IP")
    echo "  ${GREEN}✓${NC} ckpool installed at: ${CKPOOL_DIR}"
    echo "  ${GREEN}✓${NC} Start pool: ${CKPOOL_DIR}/start_pool.sh"
    echo "  ${GREEN}✓${NC} Miners connect to: ${YELLOW}stratum+tcp://${MY_IP}:3333${NC}"
else
    echo "  ${YELLOW}⚠${NC} ckpool not installed (you skipped it)"
    echo "    Run this script again to install"
fi

cat << EOF

${BOLD}Share With Friends:${NC}
  Your IP addresses (for peers to connect):
$(ip addr show 2>/dev/null | grep "inet " | grep -v "127.0.0.1" | awk '{print "    • " $2}' | sed 's/\/.*//')

${BOLD}Next Steps:${NC}
  1. ${GREEN}Share your IP${NC} with peers so they can connect
  2. ${GREEN}Wait for blockchain sync${NC} (check with ./status.sh)
  3. ${GREEN}Mine some blocks${NC} with ./mine.sh 100
  4. ${GREEN}Point ESP32 miners${NC} to your stratum pool (port 3333)

${BOLD}Logs:${NC}
  • Node: tail -f ${DATADIR}/debug.log
  • ckpool: tail -f ${CKPOOL_DIR}/ckpool.log

${YELLOW}Remember: Port 18333 must be open in your firewall!${NC}

${BOLD}${GREEN}Happy mining! 🚀${NC}
EOF

echo ""
