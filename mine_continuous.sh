#!/bin/bash
# Continuous Solo Mining Script for Retardio
# This script will continuously mine blocks to your address

RETARDIO_CLI="./src/retardio-cli"
DATADIR="$HOME/.retardio"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Check if address is provided
if [ -z "$1" ]; then
    echo -e "${RED}Error: No mining address provided${NC}"
    echo -e "${YELLOW}Usage: $0 <your_retardio_address>${NC}"
    echo -e "${YELLOW}Example: $0 FaDf8jKmN3pQrS9tV2wX4yZ5bC6dE7fG8h${NC}"
    exit 1
fi

ADDRESS="$1"

# Validate address starts with F
if [[ ! "$ADDRESS" =~ ^F ]]; then
    echo -e "${RED}Error: Address must start with 'F'${NC}"
    exit 1
fi

# Check if node is running
if ! $RETARDIO_CLI -datadir="$DATADIR" getblockchaininfo > /dev/null 2>&1; then
    echo -e "${RED}Error: Retardio node is not running${NC}"
    echo -e "${YELLOW}Start the node first with: ./start_node.sh${NC}"
    exit 1
fi

echo -e "${GREEN}Starting continuous solo mining...${NC}"
echo -e "${YELLOW}Mining to address: $ADDRESS${NC}"
echo -e "${YELLOW}Press Ctrl+C to stop${NC}"
echo ""

# Stats tracking
BLOCKS_MINED=0
START_TIME=$(date +%s)

# Trap Ctrl+C to show stats
trap ctrl_c INT

function ctrl_c() {
    echo ""
    echo -e "${GREEN}Mining stopped${NC}"
    END_TIME=$(date +%s)
    ELAPSED=$((END_TIME - START_TIME))
    HOURS=$((ELAPSED / 3600))
    MINUTES=$(((ELAPSED % 3600) / 60))
    SECONDS=$((ELAPSED % 60))
    echo -e "${YELLOW}Total blocks mined: $BLOCKS_MINED${NC}"
    echo -e "${YELLOW}Time elapsed: ${HOURS}h ${MINUTES}m ${SECONDS}s${NC}"
    if [ $BLOCKS_MINED -gt 0 ]; then
        AVG_TIME=$((ELAPSED / BLOCKS_MINED))
        echo -e "${YELLOW}Average time per block: ${AVG_TIME}s${NC}"
    fi
    exit 0
}

# Main mining loop
while true; do
    # Get current block height
    HEIGHT=$($RETARDIO_CLI -datadir="$DATADIR" getblockcount 2>/dev/null)

    # Mine one block
    BLOCK_HASH=$($RETARDIO_CLI -datadir="$DATADIR" generatetoaddress 1 "$ADDRESS" 2>/dev/null | grep -o '"[^"]*"' | tr -d '"')

    if [ $? -eq 0 ] && [ ! -z "$BLOCK_HASH" ]; then
        BLOCKS_MINED=$((BLOCKS_MINED + 1))
        NEW_HEIGHT=$((HEIGHT + 1))
        CURRENT_TIME=$(date '+%Y-%m-%d %H:%M:%S')

        # Get block reward
        BLOCK_INFO=$($RETARDIO_CLI -datadir="$DATADIR" getblock "$BLOCK_HASH" 2 2>/dev/null)

        echo -e "${GREEN}[$CURRENT_TIME] Block $NEW_HEIGHT mined!${NC}"
        echo -e "  Hash: ${YELLOW}${BLOCK_HASH:0:16}...${NC}"
        echo -e "  Total mined: ${YELLOW}$BLOCKS_MINED${NC} blocks"
        echo ""
    else
        echo -e "${RED}Failed to mine block. Retrying...${NC}"
        sleep 2
    fi

    # Small delay to avoid hammering the node
    sleep 0.5
done
