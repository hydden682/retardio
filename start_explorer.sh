#!/bin/bash

echo "╔══════════════════════════════════════════════════════╗"
echo "║   Starting Retardio Block Explorer                  ║"
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
echo "Starting block explorer server on http://localhost:3002/"
echo ""

# Start the Python server
python3 block_explorer_server.py
