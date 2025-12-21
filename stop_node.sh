#!/bin/bash
# Retardio Node Stop Script (Linux/Mac)

RETARDIO_DIR="$HOME/.retardio"
RETARDIO_CLI="./src/retardio-cli"

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}Stopping Retardio Node...${NC}"

if [ ! -f "$RETARDIO_CLI" ]; then
    echo -e "${RED}Error: retardio-cli not found at $RETARDIO_CLI${NC}"
    exit 1
fi

$RETARDIO_CLI -datadir="$RETARDIO_DIR" stop

if [ $? -eq 0 ]; then
    echo -e "${GREEN}Shutdown signal sent. Waiting for node to stop...${NC}"
    sleep 5
    echo -e "${GREEN}Retardio node stopped successfully${NC}"
else
    echo -e "${RED}Failed to stop node. It may not be running.${NC}"
    exit 1
fi
