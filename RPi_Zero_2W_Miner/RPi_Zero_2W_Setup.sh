#!/bin/bash
#
# Retardio "Firmware" Setup for Raspberry Pi Zero 2 W
# Optimization: Extremely Low Memory (512MB RAM)
#
# Usage: ./RPi_Zero_2W_Setup.sh
#

set -e

# --- Configuration ---
NODE_USER=$(whoami)
DATA_DIR="$HOME/.retardio"
REPO_URL="https://github.com/hydden682/retardio.git"
BRANCH="29.x-knots"
BUILD_DIR="$HOME/retardio-build"
SWAP_SIZE_MB=2048

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}==================================================${NC}"
echo -e "${GREEN}   Retardio Miner Setup (Pi Zero 2 W Edition)   ${NC}"
echo -e "${GREEN}==================================================${NC}"

# 1. Dependencies (Moved First to ensure dphys-swapfile exists)
echo -e "${YELLOW}[1/7] Installing Dependencies...${NC}"
sudo apt update
sudo apt install -y build-essential libtool autotools-dev automake pkg-config \
    libssl-dev libevent-dev bsdmainutils python3 libboost-system-dev \
    libboost-filesystem-dev libboost-test-dev libboost-thread-dev \
    libsqlite3-dev libminiupnpc-dev libnatpmp-dev cmake ninja-build git \
    curl dphys-swapfile

# 2. Critical Swap Setup
echo -e "${YELLOW}[2/7] Configuring Swap (Critical for 512MB RAM)...${NC}"
FREE_SWAP=$(free -m | awk '/^Swap:/{print $2}')
# Check if swap is less than 1800MB (approx 2GB target)
if [ "$FREE_SWAP" -lt 1800 ]; then
    echo "Creating ${SWAP_SIZE_MB}MB swap file..."
    sudo dphys-swapfile swapoff || true
    # Use sed to safely replace or append the CONF_SWAPSIZE line
    if grep -q "^CONF_SWAPSIZE" /etc/dphys-swapfile; then
        sudo sed -i "s/^CONF_SWAPSIZE=.*/CONF_SWAPSIZE=${SWAP_SIZE_MB}/" /etc/dphys-swapfile
    else
        echo "CONF_SWAPSIZE=${SWAP_SIZE_MB}" | sudo tee -a /etc/dphys-swapfile
    fi
    sudo dphys-swapfile setup
    sudo dphys-swapfile swapon
    echo "Swap enabled."
else
    echo "Swap already sufficient ($FREE_SWAP MB)."
fi

# 3. Clone
echo -e "${YELLOW}[3/7] Cloning Repository...${NC}"
if [ -d "$BUILD_DIR" ]; then
    cd "$BUILD_DIR"
    git fetch origin
    git checkout $BRANCH
    git pull origin $BRANCH
else
    git clone $REPO_URL -b $BRANCH "$BUILD_DIR"
    cd "$BUILD_DIR"
fi

# 4. Build (Low Memory)
echo -e "${YELLOW}[4/7] Compiling (This will take hours on Zero 2W)...${NC}"
echo "Running in low-memory mode (-j1)..."
mkdir -p cmake-build
cd cmake-build

cmake -G Ninja .. \
    -DBUILD_GUI=OFF \
    -DWITH_ZMQ=OFF \
    -DENABLE_WALLET=ON \
    -DCMAKE_BUILD_TYPE=Release \
    -DREDUCE_EXPORTS=ON

# Single core build is mandatory to avoid OOM crash on 512MB RAM
ninja -j1

# 5. Install
echo -e "${YELLOW}[5/7] Installing...${NC}"
sudo ninja install

# 6. Configure Miner
echo -e "${YELLOW}[6/7] Configuring Miner...${NC}"
mkdir -p "$DATA_DIR"
RPC_PASS=$(openssl rand -hex 16)

cat > "$DATA_DIR/retardio.conf" <<EOF
# Retardio Pi Zero 2 W Config
# Optimized for 512MB RAM

# Mining
gen=1
genproclimit=-1

# Network
server=1
daemon=1
listen=1
maxconnections=8
maxmempool=50
dbcache=50
checkblocks=2
checklevel=0

# RPC
rpcuser=retardio_zero
rpcpassword=${RPC_PASS}
rpcallowip=127.0.0.1
rpcport=18332
port=18333

# Disk Space Saving
prune=550
EOF

echo "Config saved. Mining enabled (gen=1)."

# 7. Systemd Service
echo -e "${YELLOW}[7/7] Enabling Autostart...${NC}"
SERVICE_FILE="/etc/systemd/system/retardio-miner.service"

sudo tee "$SERVICE_FILE" > /dev/null <<EOF
[Unit]
Description=Retardio Miner (Pi Zero 2W)
After=network.target

[Service]
User=${NODE_USER}
Group=${NODE_USER}
Type=forking
ExecStart=/usr/local/bin/retardiod -conf=${DATA_DIR}/retardio.conf -datadir=${DATA_DIR}
ExecStop=/usr/local/bin/retardio-cli -conf=${DATA_DIR}/retardio.conf -datadir=${DATA_DIR} stop
Restart=always
RestartSec=60
# Low priority for mining to keep system responsive
Nice=19
CPUSchedulingPolicy=idle

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable retardio-miner

echo -e "${GREEN}==================================================${NC}"
echo -e "${GREEN}   Setup Complete! System will mine on boot.    ${NC}"
echo -e "${GREEN}==================================================${NC}"
echo ""
echo "Start now: sudo systemctl start retardio-miner"
echo "Check Status: sudo systemctl status retardio-miner"
echo "Monitor: retardio-cli -conf=$DATA_DIR/retardio.conf getmininginfo"
