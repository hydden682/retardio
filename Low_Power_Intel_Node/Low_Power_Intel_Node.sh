#!/bin/bash
#
# Low Power Intel Node Deployment Script (N100/N95/N5105)
# Target OS: Ubuntu 22.04 / Debian 12
#
# Usage: ./Low_Power_Intel_Node.sh
#

set -e

# --- Configuration ---
NODE_USER=$(whoami)
DATA_DIR="$HOME/.retardio"
REPO_URL="https://github.com/hydden682/retardio.git"
BRANCH="29.x-knots"
BUILD_DIR="$HOME/retardio-build"
CORES=$(nproc)
RAM_MB=$(free -m | awk '/^Mem:/{print $2}')

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}==================================================${NC}"
echo -e "${GREEN}   Low Power Intel Node Setup (N100 Optimized)  ${NC}"
echo -e "${GREEN}==================================================${NC}"
echo -e "Detected Cores: ${CORES}"
echo -e "Detected RAM:   ${RAM_MB} MB"
echo ""

if [ "$RAM_MB" -lt 8000 ]; then
    echo -e "${YELLOW}Warning: This script is optimized for 8GB+ RAM. You have ${RAM_MB}MB.${NC}"
    echo "Adjusting optimizations down for safety..."
    DB_CACHE=1024
else
    # Use ~4GB for DB Cache on a 16GB system
    DB_CACHE=4096
fi

# 1. Update & Dependencies
echo -e "${YELLOW}[1/6] Installing build dependencies...${NC}"
sudo apt update && sudo apt upgrade -y
sudo apt install -y build-essential libtool autotools-dev automake pkg-config \
    libssl-dev libevent-dev bsdmainutils python3 libboost-all-dev \
    libsqlite3-dev libminiupnpc-dev libnatpmp-dev cmake ninja-build git \
    curl

# 2. Clone Repository
echo -e "${YELLOW}[2/6] Cloning Repository...${NC}"
if [ -d "$BUILD_DIR" ]; then
    echo "Updating existing repository..."
    cd "$BUILD_DIR"
    git fetch origin
    git checkout $BRANCH
    git pull origin $BRANCH
else
    git clone $REPO_URL -b $BRANCH "$BUILD_DIR"
    cd "$BUILD_DIR"
fi

# 3. Build (CMake + Ninja)
echo -e "${YELLOW}[3/6] Building Retardio Node (Jobs: ${CORES})...${NC}"
mkdir -p cmake-build
cd cmake-build

# Clean previous build if needed
# rm -rf * 

cmake -G Ninja .. \
    -DBUILD_GUI=OFF \
    -DWITH_ZMQ=ON \
    -DENABLE_WALLET=ON \
    -DCMAKE_BUILD_TYPE=Release

ninja -j${CORES}

# 4. Install
echo -e "${YELLOW}[4/6] Installing binaries...${NC}"
sudo ninja install

# 5. Configuration
echo -e "${YELLOW}[5/6] Configuring Node...${NC}"
mkdir -p "$DATA_DIR"

# Generate secure RPC password
RPC_PASS=$(openssl rand -hex 32)
cat > "$DATA_DIR/retardio.conf" <<EOF
# Retardio Node Config (N100 Optimized)
server=1
daemon=1
listen=1
txindex=1

# RPC
rpcuser=retardio
rpcpassword=${RPC_PASS}
rpcallowip=127.0.0.1
rpcbind=127.0.0.1

# Performance (N100/16GB)
dbcache=${DB_CACHE}
par=${CORES}
maxconnections=125
maxmempool=512

# Network
port=18333
rpcport=18332

# Logging
debug=0
logips=1
EOF

echo -e "Saved config to: $DATA_DIR/retardio.conf"

# 6. Systemd Service
echo -e "${YELLOW}[6/6] Creating Systemd Service...${NC}"
SERVICE_FILE="/etc/systemd/system/retardiod.service"

sudo tee "$SERVICE_FILE" > /dev/null <<EOF
[Unit]
Description=Retardio Node Daemon
After=network.target

[Service]
User=${NODE_USER}
Group=${NODE_USER}
Type=forking
ExecStart=/usr/local/bin/retardiod -conf=${DATA_DIR}/retardio.conf -datadir=${DATA_DIR}
ExecStop=/usr/local/bin/retardio-cli -conf=${DATA_DIR}/retardio.conf -datadir=${DATA_DIR} stop
Restart=always
RestartSec=30
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable retardiod

echo -e "${GREEN}==================================================${NC}"
echo -e "${GREEN}   Setup Complete!                                ${NC}"
echo -e "${GREEN}==================================================${NC}"
echo ""
echo "Command to start node: sudo systemctl start retardiod"
echo "Check logs:            sudo journalctl -fn 100 -u retardiod"
echo "Check info:            retardio-cli -conf=$DATA_DIR/retardio.conf getblockchaininfo"
echo ""
echo "RPC Password: $RPC_PASS"
echo "(Saved in $DATA_DIR/retardio.conf)"
