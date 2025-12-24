#!/bin/bash
#
# Retardio Node Connection Helper
# This script helps connect two or more Retardio nodes together
#

set -e

RETARDIO_CLI="./build/bin/retardio-cli"
DATADIR="${HOME}/.retardio"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}==================================${NC}"
echo -e "${GREEN}Retardio Node Connection Helper${NC}"
echo -e "${GREEN}==================================${NC}"
echo ""

# Check if retardio-cli exists
if [ ! -f "$RETARDIO_CLI" ]; then
    echo -e "${RED}Error: retardio-cli not found at $RETARDIO_CLI${NC}"
    echo "Please build Retardio first or update the RETARDIO_CLI path in this script."
    exit 1
fi

# Function to add a peer node
add_peer() {
    local peer_address=$1
    local peer_port=${2:-18333}

    echo -e "${YELLOW}Adding peer: ${peer_address}:${peer_port}${NC}"

    if $RETARDIO_CLI -datadir="$DATADIR" addnode "${peer_address}:${peer_port}" "add" 2>/dev/null; then
        echo -e "${GREEN}✓ Peer added successfully${NC}"
    else
        echo -e "${RED}✗ Failed to add peer${NC}"
        return 1
    fi
}

# Function to list current connections
list_connections() {
    echo -e "${YELLOW}Current connections:${NC}"
    local peer_count=$($RETARDIO_CLI -datadir="$DATADIR" getconnectioncount 2>/dev/null || echo "0")
    echo "Total peers: $peer_count"

    if [ "$peer_count" -gt 0 ]; then
        echo ""
        $RETARDIO_CLI -datadir="$DATADIR" getpeerinfo | grep -E '"addr"|"subver"|"inbound"' | head -20
    else
        echo -e "${YELLOW}No peers connected${NC}"
    fi
}

# Function to show network info
show_network_info() {
    echo -e "${YELLOW}Network information:${NC}"
    $RETARDIO_CLI -datadir="$DATADIR" getnetworkinfo | grep -E '"version"|"subversion"|"localservices"|"localrelay"|"networkactive"'
}

# Main menu
echo "What would you like to do?"
echo "1) Add a peer node"
echo "2) List current connections"
echo "3) Show network info"
echo "4) Add multiple peers from a file"
echo "5) Exit"
echo ""
read -p "Enter choice [1-5]: " choice

case $choice in
    1)
        read -p "Enter peer IP address: " peer_ip
        read -p "Enter peer port (default 18333): " peer_port
        peer_port=${peer_port:-18333}
        add_peer "$peer_ip" "$peer_port"
        echo ""
        list_connections
        ;;
    2)
        list_connections
        ;;
    3)
        show_network_info
        ;;
    4)
        read -p "Enter path to peers file (one IP per line): " peers_file
        if [ -f "$peers_file" ]; then
            while IFS= read -r line; do
                # Skip empty lines and comments
                [[ -z "$line" || "$line" =~ ^#.* ]] && continue

                # Parse IP:PORT or just IP
                if [[ "$line" =~ ^(.+):([0-9]+)$ ]]; then
                    add_peer "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}"
                else
                    add_peer "$line" "18333"
                fi
                sleep 1
            done < "$peers_file"
            echo ""
            list_connections
        else
            echo -e "${RED}Error: File not found: $peers_file${NC}"
        fi
        ;;
    5)
        echo "Exiting..."
        exit 0
        ;;
    *)
        echo -e "${RED}Invalid choice${NC}"
        exit 1
        ;;
esac

echo ""
echo -e "${GREEN}Done!${NC}"
