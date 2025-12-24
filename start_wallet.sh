#!/bin/bash

echo "╔══════════════════════════════════════════════════════╗"
echo "║   Starting Retardio GUI Wallet                      ║"
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
echo "Starting GUI wallet on http://localhost:8080/"
echo ""
echo "Opening in your default browser..."
echo ""

# Start a simple HTTP server to serve the wallet GUI
cd "$(dirname "$0")"

# Try python3 first, then python
if command -v python3 &> /dev/null; then
    python3 -m http.server 8080 --bind 127.0.0.1 &
elif command -v python &> /dev/null; then
    python -m http.server 8080 --bind 127.0.0.1 &
else
    echo "❌ Python not found! Please install Python 3"
    exit 1
fi

SERVER_PID=$!

echo "Server PID: $SERVER_PID"
echo ""
echo "Wallet GUI running at: http://localhost:8080/wallet_gui.html"
echo ""
echo "Press Ctrl+C to stop"
echo ""

# Try to open in browser
if command -v xdg-open &> /dev/null; then
    xdg-open "http://localhost:8080/wallet_gui.html" 2>/dev/null
elif command -v open &> /dev/null; then
    open "http://localhost:8080/wallet_gui.html" 2>/dev/null
fi

# Wait for Ctrl+C
trap "kill $SERVER_PID 2>/dev/null; echo ''; echo 'Wallet GUI stopped.'; exit 0" INT
wait $SERVER_PID
