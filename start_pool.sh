#!/bin/bash

echo "╔══════════════════════════════════════════════════════╗"
echo "║   Retardio Mining Pool Setup                        ║"
echo "╚══════════════════════════════════════════════════════╝"
echo ""

# Check if retardiod is running
if ! pgrep -x "retardiod" > /dev/null; then
    echo "❌ Retardiod is not running!"
    echo ""
    echo "Please start your Retardio node first:"
    echo "  \$HOME/.retardio/retardiod -datadir=\$HOME/.retardio/data -daemon"
    echo ""
    exit 1
fi

echo "✓ Retardio node is running"
echo ""

# Check if pool address is configured
if grep -q "YOUR_POOL_ADDRESS_HERE" pool_server.py; then
    echo "⚠️  Pool address not configured!"
    echo ""
    echo "Getting a new address for the pool..."
    POOL_ADDR=$($HOME/.retardio/retardio-cli -datadir=$HOME/.retardio/data getnewaddress "mining_pool")

    if [ -z "$POOL_ADDR" ]; then
        echo "❌ Failed to get pool address"
        exit 1
    fi

    echo "✓ Pool address: $POOL_ADDR"
    echo ""

    # Update pool_server.py with the address
    sed -i "s/YOUR_POOL_ADDRESS_HERE/$POOL_ADDR/" pool_server.py

    echo "✓ Pool configured!"
    echo ""
fi

# Check Python
if ! command -v python3 &> /dev/null; then
    echo "❌ Python 3 not found! Please install Python 3"
    exit 1
fi

echo "Starting Retardio Mining Pool..."
echo ""
echo "Pool will be available at:"
echo "  stratum+tcp://YOUR_SERVER_IP:3333"
echo ""
echo "Press Ctrl+C to stop"
echo ""

# Start pool server
python3 pool_server.py
