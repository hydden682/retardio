#!/bin/bash
# Tailscale Setup for Retardio Node (WSL2)
# This creates a secure tunnel without port forwarding

set -e

echo "=================================="
echo "Tailscale Setup for Retardio Node"
echo "=================================="
echo ""
echo "This will set up a secure tunnel to your node without"
echo "needing to open ports on your router."
echo ""

# Check if running in WSL
if ! grep -qi microsoft /proc/version 2>/dev/null; then
    echo "Note: This script is optimized for WSL2 but works on Linux too."
fi

# Install Tailscale
if ! command -v tailscale &> /dev/null; then
    echo "[1/4] Installing Tailscale..."
    curl -fsSL https://tailscale.com/install.sh | sh
else
    echo "[1/4] Tailscale already installed"
fi

# Start the daemon (WSL2 doesn't have systemd by default)
echo "[2/4] Starting Tailscale daemon..."
if pgrep tailscaled > /dev/null; then
    echo "       Tailscale daemon already running"
else
    sudo nohup tailscaled > /tmp/tailscaled.log 2>&1 &
    sleep 2
fi

# Authenticate
echo "[3/4] Authenticating with Tailscale..."
echo "       A browser window will open. Log in or create a free account."
echo ""
sudo tailscale up

# Get the Tailscale IP
echo ""
echo "[4/4] Getting your Tailscale IP..."
TAILSCALE_IP=$(tailscale ip -4 2>/dev/null || echo "unknown")

echo ""
echo "=================================="
echo "Setup Complete!"
echo "=================================="
echo ""
echo "Your Tailscale IP: $TAILSCALE_IP"
echo ""
echo "To register your node with the explorer, use this IP:"
echo "  Host: $TAILSCALE_IP"
echo "  Port: 18332"
echo ""
echo "IMPORTANT: After each WSL restart, run:"
echo "  sudo nohup tailscaled &"
echo "  sudo tailscale up"
echo ""
echo "Or add to your ~/.bashrc for auto-start:"
echo '  if ! pgrep tailscaled > /dev/null; then'
echo '      sudo nohup tailscaled > /tmp/tailscaled.log 2>&1 &'
echo '  fi'
echo ""
