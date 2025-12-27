#!/bin/bash
#
# Retardio Pool - Complete Setup Script
# Run this on your VPS to set up the mining pool
#

set -e

echo "=============================================="
echo "  RETARDIO POOL - COMPLETE SETUP"
echo "=============================================="

# Configuration
POOL_DIR="$HOME/retardio-pool"
RETARDIO_DIR="$HOME/retardio-coin"
DATA_DIR="$HOME/.retardio/data"

# Install dependencies
echo "[1/6] Installing dependencies..."
sudo apt update
sudo apt install -y python3 python3-pip nginx

pip3 install flask flask-cors

# Create pool directory
echo "[2/6] Setting up pool directory..."
mkdir -p "$POOL_DIR"
cp "$RETARDIO_DIR/pool_v8.py" "$POOL_DIR/pool.py"
cp -r "$RETARDIO_DIR/pool_ui" "$POOL_DIR/"

# Update paths in pool.py for this system
sed -i "s|/home/hydden682/retardio-coin/build/bin/retardio-cli|$RETARDIO_DIR/build/bin/retardio-cli|g" "$POOL_DIR/pool.py"
sed -i "s|/home/hydden682/.retardio/data|$DATA_DIR|g" "$POOL_DIR/pool.py"

# Create systemd service for pool
echo "[3/6] Creating pool service..."
sudo tee /etc/systemd/system/retardio-pool.service > /dev/null <<EOF
[Unit]
Description=Retardio Mining Pool
After=network.target

[Service]
Type=simple
User=$USER
WorkingDirectory=$POOL_DIR
ExecStart=/usr/bin/python3 $POOL_DIR/pool.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Create systemd service for pool UI
echo "[4/6] Creating pool UI service..."
sudo tee /etc/systemd/system/retardio-pool-ui.service > /dev/null <<EOF
[Unit]
Description=Retardio Pool Dashboard
After=network.target

[Service]
Type=simple
User=$USER
WorkingDirectory=$POOL_DIR/pool_ui
ExecStart=/usr/bin/python3 $POOL_DIR/pool_ui/app.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Configure nginx as reverse proxy (optional, for port 80 access)
echo "[5/6] Configuring nginx..."
sudo tee /etc/nginx/sites-available/retardio-pool > /dev/null <<EOF
server {
    listen 80;
    server_name _;

    location / {
        proxy_pass http://127.0.0.1:5555;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }
}
EOF

sudo ln -sf /etc/nginx/sites-available/retardio-pool /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t && sudo systemctl reload nginx

# Open firewall ports
echo "[6/6] Configuring firewall..."
sudo ufw allow 3333/tcp comment "Retardio Stratum Pool"
sudo ufw allow 5555/tcp comment "Retardio Pool Dashboard"
sudo ufw allow 80/tcp comment "HTTP"
sudo ufw --force enable

# Enable and start services
sudo systemctl daemon-reload
sudo systemctl enable retardio-pool retardio-pool-ui
sudo systemctl start retardio-pool retardio-pool-ui

# Get public IP
PUBLIC_IP=$(curl -s ifconfig.me)

echo ""
echo "=============================================="
echo "  SETUP COMPLETE!"
echo "=============================================="
echo ""
echo "Your pool is now running!"
echo ""
echo "STRATUM ADDRESS (for miners):"
echo "  stratum+tcp://$PUBLIC_IP:3333"
echo ""
echo "DASHBOARD URL:"
echo "  http://$PUBLIC_IP"
echo "  http://$PUBLIC_IP:5555"
echo ""
echo "Commands:"
echo "  sudo systemctl status retardio-pool      # Check pool status"
echo "  sudo systemctl status retardio-pool-ui   # Check UI status"
echo "  sudo journalctl -fu retardio-pool        # View pool logs"
echo ""
echo "Share the dashboard URL with your miners!"
echo "=============================================="
