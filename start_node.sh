#!/bin/bash
# Retardio Node Startup Script (Linux/Mac)

# Configuration
RETARDIO_DIR="$HOME/.retardio"
RETARDIO_BIN="./src/retardiod"
RETARDIO_CLI="./src/retardio-cli"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Starting Retardio Node...${NC}"

# Check if binary exists
if [ ! -f "$RETARDIO_BIN" ]; then
    echo -e "${RED}Error: retardiod binary not found at $RETARDIO_BIN${NC}"
    echo -e "${YELLOW}Have you compiled the code? Run: ./autogen.sh && ./configure && make${NC}"
    exit 1
fi

# Create data directory if it doesn't exist
if [ ! -d "$RETARDIO_DIR" ]; then
    echo -e "${YELLOW}Creating data directory at $RETARDIO_DIR${NC}"
    mkdir -p "$RETARDIO_DIR"
fi

# Check if config file exists
if [ ! -f "$RETARDIO_DIR/retardio.conf" ]; then
    echo -e "${YELLOW}No config file found. Copying example config...${NC}"
    if [ -f "retardio.conf.example" ]; then
        cp retardio.conf.example "$RETARDIO_DIR/retardio.conf"
        echo -e "${RED}IMPORTANT: Edit $RETARDIO_DIR/retardio.conf and change the RPC password!${NC}"
    else
        echo -e "${RED}Error: retardio.conf.example not found${NC}"
        exit 1
    fi
fi

# Check if node is already running
if [ -f "$RETARDIO_DIR/retardiod.pid" ]; then
    PID=$(cat "$RETARDIO_DIR/retardiod.pid")
    if ps -p $PID > /dev/null 2>&1; then
        echo -e "${YELLOW}Retardio node is already running (PID: $PID)${NC}"
        exit 0
    else
        echo -e "${YELLOW}Removing stale PID file${NC}"
        rm "$RETARDIO_DIR/retardiod.pid"
    fi
fi

# Start the node
echo -e "${GREEN}Starting Retardio daemon...${NC}"
$RETARDIO_BIN -datadir="$RETARDIO_DIR" -daemon

# Wait for startup
sleep 3

# Check if it started successfully
if $RETARDIO_CLI -datadir="$RETARDIO_DIR" getblockchaininfo > /dev/null 2>&1; then
    echo -e "${GREEN}Retardio node started successfully!${NC}"
    echo ""
    $RETARDIO_CLI -datadir="$RETARDIO_DIR" getblockchaininfo
else
    echo -e "${RED}Failed to start Retardio node. Check $RETARDIO_DIR/debug.log for errors${NC}"
    exit 1
fi
