#!/bin/bash
#
# RETARDIO COMPLETE VPS SETUP
# Run this on a fresh Ubuntu 22.04 VPS
#
# Usage: curl -sSL https://raw.githubusercontent.com/hydden682/retardio/29.x-knots/vps_complete_setup.sh | bash
#

set -e

echo ""
echo "=============================================="
echo "  RETARDIO COMPLETE VPS SETUP"
echo "=============================================="
echo ""

# Get public IP (force IPv4)
PUBLIC_IP=$(curl -4 -s ifconfig.me)
echo "Your Public IP: $PUBLIC_IP"
echo ""

# Generate secure random credentials
RPC_USER="retardio"
RPC_PASSWORD=$(openssl rand -hex 24)
POOL_API_KEY=$(openssl rand -hex 32)
POOL_DOMAIN="retardiopool.xyz"
CHAIN_DOMAIN="retardiochain.com"

echo "Generated secure credentials (SAVE THESE):"
echo "  RPC Password: $RPC_PASSWORD"
echo "  Pool API Key: $POOL_API_KEY"
echo ""

# Update system
echo "[1/8] Updating system..."
sudo apt update && sudo apt upgrade -y

# Install dependencies
echo "[2/8] Installing dependencies..."
sudo apt install -y git build-essential libtool autotools-dev automake pkg-config \
    libssl-dev libevent-dev bsdmainutils python3 python3-pip libboost-all-dev \
    libdb-dev libdb++-dev nginx ufw sqlite3

# Update libstdc++ for pre-built binaries compatibility
echo "Updating C++ standard library..."
sudo add-apt-repository -y ppa:ubuntu-toolchain-r/test
sudo apt update
sudo apt install -y libstdc++6

pip3 install flask flask-cors requests

# Clone repo
echo "[3/8] Cloning Retardio..."
cd ~
if [ ! -d "retardio-coin" ]; then
    git clone https://github.com/hydden682/retardio.git retardio-coin
fi
cd retardio-coin

# Get node binaries
echo "[4/8] Setting up Retardio node..."
mkdir -p build/bin

# Try to download pre-built binaries from GitHub releases
RELEASE_URL="https://github.com/hydden682/retardio/releases/download/v1.1.0/retardio-linux-x86_64.tar.gz"
if curl -sL --fail "$RELEASE_URL" -o /tmp/retardio-binaries.tar.gz 2>/dev/null; then
    echo "Downloading pre-built binaries..."
    tar -xzf /tmp/retardio-binaries.tar.gz -C build/bin/
    chmod +x build/bin/retardiod build/bin/retardio-cli
    rm /tmp/retardio-binaries.tar.gz
else
    echo ""
    echo "================================================================"
    echo "  PRE-BUILT BINARIES NOT AVAILABLE"
    echo "================================================================"
    echo ""
    echo "No pre-built Linux binaries found. You have two options:"
    echo ""
    echo "OPTION 1: Build on a larger VPS (4GB+ RAM required)"
    echo "  sudo apt install -y autoconf automake"
    echo "  cd ~/retardio-coin"
    echo "  ./autogen.sh"
    echo "  ./configure --without-gui --disable-tests --disable-bench"
    echo "  make -j\$(nproc)"
    echo ""
    echo "OPTION 2: Build locally and upload binaries"
    echo "  Build on your local machine, then:"
    echo "  scp retardiod retardio-cli root@$PUBLIC_IP:~/retardio-coin/build/bin/"
    echo ""
    echo "After getting binaries, run this script again."
    echo "================================================================"
    exit 1
fi

# Create data directory
echo "[5/8] Setting up node..."
mkdir -p ~/.retardio/data

cat > ~/.retardio/data/retardio.conf << EOF
server=1
daemon=1
rpcuser=$RPC_USER
rpcpassword=$RPC_PASSWORD
rpcallowip=127.0.0.1
rpcport=18332
port=18333
listen=1
txindex=1
EOF

# Save credentials to a secure file
cat > ~/.retardio/credentials << EOF
# Retardio Credentials - KEEP THIS FILE SECURE
RPC_USER=$RPC_USER
RPC_PASSWORD=$RPC_PASSWORD
POOL_API_KEY=$POOL_API_KEY
EOF
chmod 600 ~/.retardio/credentials

# Create systemd services
echo "[6/8] Creating services..."

# Node service
sudo tee /etc/systemd/system/retardio-node.service > /dev/null << EOF
[Unit]
Description=Retardio Node
After=network.target

[Service]
Type=forking
User=$USER
ExecStart=$HOME/retardio-coin/build/bin/retardiod -datadir=$HOME/.retardio/data -daemon
ExecStop=$HOME/retardio-coin/build/bin/retardio-cli -datadir=$HOME/.retardio/data stop
Restart=on-failure
RestartSec=30

[Install]
WantedBy=multi-user.target
EOF

# Pool service
sudo tee /etc/systemd/system/retardio-pool.service > /dev/null << EOF
[Unit]
Description=Retardio Mining Pool
After=retardio-node.service

[Service]
Type=simple
User=$USER
WorkingDirectory=$HOME/retardio-coin
ExecStart=/usr/bin/python3 $HOME/retardio-coin/pool_v8.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Pool UI service
sudo tee /etc/systemd/system/retardio-pool-ui.service > /dev/null << EOF
[Unit]
Description=Retardio Pool Dashboard
After=network.target

[Service]
Type=simple
User=$USER
WorkingDirectory=$HOME/retardio-coin/pool_ui
Environment="POOL_API_KEY=$POOL_API_KEY"
ExecStart=/usr/bin/python3 $HOME/retardio-coin/pool_ui/app.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Block Explorer service
sudo tee /etc/systemd/system/retardio-explorer.service > /dev/null << EOF
[Unit]
Description=Retardio Block Explorer
After=retardio-node.service

[Service]
Type=simple
User=$USER
WorkingDirectory=$HOME/retardio-coin/explorer
Environment="PORT=3002"
ExecStart=/usr/bin/python3 $HOME/retardio-coin/explorer/app.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Update pool config with correct paths
sed -i "s|/home/hydden682|$HOME|g" ~/retardio-coin/pool_v8.py

# Setup nginx
echo "[7/8] Configuring web server..."

# Create downloads directory with configured files
mkdir -p ~/retardio-coin/www/downloads

# Create configured all-in-one HTML
sed "s/retardiopool.xyz/$POOL_DOMAIN/g; s/retardiochain.com/$CHAIN_DOMAIN/g" \
    ~/retardio-coin/retardio_all_in_one.html > ~/retardio-coin/www/downloads/Retardio.html

# Create landing page
cat > ~/retardio-coin/www/index.html << 'HTMLEOF'
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Retardio - Solo Mining Pool</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: 'Segoe UI', sans-serif;
            background: linear-gradient(135deg, #0a0a1a, #1a1a3e);
            min-height: 100vh;
            color: #fff;
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
            padding: 40px 20px;
        }
        h1 {
            font-size: 72px;
            background: linear-gradient(135deg, #00d4ff, #00ff88);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            margin-bottom: 20px;
        }
        p { color: rgba(255,255,255,0.7); font-size: 20px; margin-bottom: 40px; }
        .buttons { display: flex; gap: 20px; flex-wrap: wrap; justify-content: center; }
        .btn {
            display: inline-block;
            padding: 18px 40px;
            background: linear-gradient(135deg, #00d4ff, #0099ff);
            border-radius: 12px;
            color: #fff;
            text-decoration: none;
            font-size: 18px;
            font-weight: 600;
            transition: all 0.3s;
        }
        .btn:hover { transform: translateY(-3px); box-shadow: 0 10px 30px rgba(0,212,255,0.3); }
        .btn-secondary { background: rgba(255,255,255,0.1); border: 1px solid rgba(255,255,255,0.2); }
        .stats { margin-top: 60px; display: flex; gap: 40px; }
        .stat { text-align: center; }
        .stat-value { font-size: 36px; font-weight: bold; color: #00d4ff; }
        .stat-label { color: rgba(255,255,255,0.5); margin-top: 5px; }
    </style>
</head>
<body>
    <h1>RETARDIO</h1>
    <p>Solo Mining Pool - Keep 100% of your blocks</p>
    <div class="buttons">
        <a href="/downloads/Retardio.html" class="btn">Start Mining</a>
        <a href="/dashboard" class="btn btn-secondary">Pool Dashboard</a>
        <a href="/explorer" class="btn btn-secondary">Block Explorer</a>
    </div>
    <div class="stats">
        <div class="stat">
            <div class="stat-value" id="blocks">-</div>
            <div class="stat-label">Blocks Mined</div>
        </div>
        <div class="stat">
            <div class="stat-value" id="height">-</div>
            <div class="stat-label">Block Height</div>
        </div>
    </div>
    <script>
        fetch('/api/stats').then(r => r.json()).then(d => {
            document.getElementById('blocks').textContent = d.total_blocks || 0;
            if (d.network && d.network.block_height) {
                document.getElementById('height').textContent = d.network.block_height;
            }
        }).catch(() => {});
        // Also try explorer API for block height
        fetch('/explorer/api/status').then(r => r.json()).then(d => {
            if (d.blocks) document.getElementById('height').textContent = d.blocks;
        }).catch(() => {});
    </script>
</body>
</html>
HTMLEOF

# Nginx config
sudo tee /etc/nginx/sites-available/retardio << EOF
# HTTP Redirect to HTTPS (Optional - uncomment if using SSL)
# server {
#     listen 80;
#     server_name $CHAIN_DOMAIN www.$CHAIN_DOMAIN $POOL_DOMAIN www.$POOL_DOMAIN $PUBLIC_IP;
#     return 301 https://\$host\$request_uri;
# }

server {
    listen 80;
    # listen 443 ssl;
    server_name $CHAIN_DOMAIN www.$CHAIN_DOMAIN $PUBLIC_IP;
    
    # SSL Configuration (Uncomment and ensure certs are at these paths)
    # ssl_certificate /etc/nginx/ssl/retardio.crt;
    # ssl_certificate_key /etc/nginx/ssl/retardio.key;
    # ssl_protocols TLSv1.2 TLSv1.3;
    # ssl_cipher_list ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384;

    root \$HOME/retardio-coin/www;
    index index.html;

    # Main site
    location / {
        try_files \$uri \$uri/ =404;
    }

    # Pool dashboard (now under explorer for consistency)
    location /dashboard {
        proxy_pass http://127.0.0.1:5555/;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    # Pool API
    location /api/ {
        proxy_pass http://127.0.0.1:5555/api/;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    # Block explorer
    location /explorer {
        proxy_pass http://127.0.0.1:3002/;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    # Explorer API
    location /explorer/api/ {
        proxy_pass http://127.0.0.1:3002/api/;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    # Downloads
    location /downloads {
        alias \$HOME/retardio-coin/www/downloads;
        autoindex on;
    }
}

server {
    listen 80;
    # listen 443 ssl;
    server_name $POOL_DOMAIN www.$POOL_DOMAIN;

    # SSL Configuration (Uncomment and ensure certs are at these paths)
    # ssl_certificate /etc/nginx/ssl/retardio.crt;
    # ssl_certificate_key /etc/nginx/ssl/retardio.key;

    # Redirect all pool domain HTTP traffic to the dashboard on chain domain
    # or just serve the dashboard directly if preferred.
    # For now, let's serve the dashboard/API directly on this domain too.
    location / {
        proxy_pass http://127.0.0.1:5555/;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    location /api/ {
        proxy_pass http://127.0.0.1:5555/api/;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

sudo ln -sf /etc/nginx/sites-available/retardio /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default

# Fix permissions for nginx to access www directory
chmod 755 $HOME
chmod -R 755 $HOME/retardio-coin/www

sudo nginx -t && sudo systemctl reload nginx

# Configure firewall
echo "[8/8] Configuring firewall..."
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 3333/tcp
sudo ufw allow 18333/tcp
sudo ufw --force enable

# Enable and start services
sudo systemctl daemon-reload
sudo systemctl enable retardio-node retardio-pool retardio-pool-ui retardio-explorer
sudo systemctl start retardio-node

# Wait for node to start
echo ""
echo "Waiting for node to start..."
sleep 10

sudo systemctl start retardio-pool retardio-pool-ui retardio-explorer

# Register local node with explorer
echo ""
echo "Registering node with block explorer..."
sleep 5
curl -s -X POST http://127.0.0.1:3002/api/nodes/register \
    -H "Content-Type: application/json" \
    -d "{\"host\": \"127.0.0.1\", \"port\": 18332, \"rpc_user\": \"$RPC_USER\", \"rpc_pass\": \"$RPC_PASSWORD\"}" || true

# Create auto-update script
echo "Creating auto-update script..."
cat > ~/retardio-update.sh << 'UPDATEEOF'
#!/bin/bash
# Retardio Auto-Update Script
# Pulls latest from GitHub and updates web files

cd ~/retardio-coin

# Fetch and check for updates
git fetch origin 29.x-knots

LOCAL=$(git rev-parse HEAD)
REMOTE=$(git rev-parse origin/29.x-knots)

if [ "$LOCAL" != "$REMOTE" ]; then
    echo "$(date): Updates found, pulling..."
    git pull origin 29.x-knots

    # Get current config
    PUBLIC_IP=$(curl -4 -s ifconfig.me)
    RPC_PASSWORD=$(grep rpcpassword ~/.retardio/data/retardio.conf | cut -d'=' -f2)

    # Update the all-in-one HTML
    sed "s/retardiopool.xyz/$POOL_DOMAIN/g; s/retardiochain.com/$CHAIN_DOMAIN/g" \
        retardio_all_in_one.html > www/downloads/Retardio.html

    # Update wallet standalone
    cp wallet_standalone.html www/downloads/wallet.html

    echo "$(date): Update complete!"
else
    echo "$(date): Already up to date"
fi
UPDATEEOF
chmod +x ~/retardio-update.sh

# Run initial update
~/retardio-update.sh

# Add cron job for hourly updates (if not already exists)
CRON_CMD="0 * * * * $HOME/retardio-update.sh >> $HOME/retardio-update.log 2>&1"
(crontab -l 2>/dev/null | grep -v "retardio-update.sh"; echo "$CRON_CMD") | crontab -
echo "Auto-update cron job installed (runs hourly)"

echo ""
echo "=============================================="
echo "  SETUP COMPLETE!"
echo "=============================================="
echo ""
echo "Your Retardio ecosystem is now running!"
echo ""
echo "PUBLIC URLS:"
echo "  Website:     http://$PUBLIC_IP"
echo "  Dashboard:   http://$PUBLIC_IP/dashboard"
echo "  Explorer:    http://$PUBLIC_IP/explorer"
echo "  Downloads:   http://$PUBLIC_IP/downloads"
echo ""
echo "MINING POOL:"
echo "  Address:     stratum+tcp://$PUBLIC_IP:3333"
echo "  Password:    x"
echo ""
echo "COMMANDS:"
echo "  Check node:    sudo systemctl status retardio-node"
echo "  Check pool:    sudo systemctl status retardio-pool"
echo "  View logs:     sudo journalctl -fu retardio-pool"
echo "  Node CLI:      ~/retardio-coin/build/bin/retardio-cli -datadir=~/.retardio/data getblockchaininfo"
echo ""
echo "Share http://$PUBLIC_IP with your community!"
echo "=============================================="
