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

cd "$HOME"

# Get public IP (force IPv4)
PUBLIC_IP=$(curl -4 -s ifconfig.me)
echo "Your Public IP: $PUBLIC_IP"
echo ""

# Generate secure random credentials
# Fixed credentials (prevent rotation)
RPC_USER="retardio"
RPC_PASSWORD="ab117d1f9a7d670f67786ca7ec4a13625f90aba7ca77b600"
POOL_API_KEY="50196ee94fa0b382692d6fe856273d2d40f73f7dadb9acd088987cebfa619ce4"
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

# Install Node.js 20.x
echo "Installing Node.js 20..."
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs

pip3 install flask flask-cors requests gunicorn

# Clone repo
echo "[3/8] Cloning Retardio..."
cd ~
# Always ensure we have a fresh clone to match the new repo structure
if [ -d "retardio-coin" ]; then
    echo "Removing existing retardio-coin directory to ensure fresh clone..."
    rm -rf retardio-coin
fi
git clone -b 29.x-knots https://github.com/hydden682/retardio.git retardio-coin
cd retardio-coin

# Get node binaries
echo "[4/8] Setting up Retardio node..."
# Use packages/node/build/bin if we build locally, or just use build/bin relative to repo
mkdir -p packages/node/build/bin

# Try to download pre-built binaries from GitHub releases
RELEASE_URL="https://github.com/hydden682/retardio/releases/download/v1.1.0/retardio-linux-x86_64.tar.gz"
if curl -sL --fail "$RELEASE_URL" -o /tmp/retardio-binaries.tar.gz 2>/dev/null; then
    echo "Downloading pre-built binaries..."
    tar -xzf /tmp/retardio-binaries.tar.gz -C packages/node/build/bin/
    chmod +x packages/node/build/bin/retardiod packages/node/build/bin/retardio-cli
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
    echo "  scp retardiod retardio-cli root@$PUBLIC_IP:~/retardio-coin/packages/node/build/bin/"
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
ExecStart=$HOME/retardio-coin/packages/node/build/bin/retardiod -datadir=$HOME/.retardio/data -daemon
ExecStop=$HOME/retardio-coin/packages/node/build/bin/retardio-cli -datadir=$HOME/.retardio/data stop
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
WorkingDirectory=$HOME/retardio-coin/packages/pool
Environment="POOL_UI_URL=http://127.0.0.1:5555"
Environment="POOL_UI_API_KEY=$POOL_API_KEY"
ExecStart=/usr/bin/python3 $HOME/retardio-coin/packages/pool/pool_v8.py
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
WorkingDirectory=$HOME/retardio-coin/packages/pool/pool_ui
Environment="POOL_API_KEY=$POOL_API_KEY"
ExecStart=/usr/bin/python3 $HOME/retardio-coin/packages/pool/pool_ui/app.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Block Explorer service (Next.js)
sudo tee /etc/systemd/system/retardio-explorer.service > /dev/null << EOF
[Unit]
Description=Retardio Block Explorer
After=retardio-node.service

[Service]
Type=simple
User=$USER
WorkingDirectory=$HOME/retardio-coin/packages/explorer-next
Environment="PORT=8082"
Environment="NODE_ENV=production"
Environment="RPC_USER=$RPC_USER"
Environment="RPC_PASSWORD=$RPC_PASSWORD"
Environment="RPC_HOST=127.0.0.1"
Environment="RPC_PORT=18332"
ExecStart=/usr/bin/npm start
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Install Explorer Dependencies & Build
echo "[6a/8] Building Block Explorer..."
cd ~/retardio-coin/packages/explorer-next
# Check if we are on a small VPS and need to limit memory for build
export NODE_OPTIONS="--max-old-space-size=2048"
npm install
npm run build

# Update pool config with correct paths
sed -i "s|/home/hydden682|$HOME|g" ~/retardio-coin/packages/pool/pool_v8.py

# Setup nginx
echo "[7/8] Configuring web server..."

# Setup SSL Certificates
echo "Setting up SSL certificates..."
sudo mkdir -p /etc/nginx/ssl
# Check and copy certificates
if [ -f "$HOME/retardiochain.com.pem" ] && [ -f "$HOME/retardiochain.com.key" ]; then
    echo "Certificates found in home directory. Installing..."
    sudo cp "$HOME/retardiochain.com.pem" /etc/nginx/ssl/retardiochain.com.pem
    sudo cp "$HOME/retardiochain.com.key" /etc/nginx/ssl/retardiochain.com.key
elif [ -f "retardiochain.com.pem" ] && [ -f "retardiochain.com.key" ]; then
    echo "Certificates found in current directory. Installing..."
    sudo cp retardiochain.com.pem /etc/nginx/ssl/retardiochain.com.pem
    sudo cp retardiochain.com.key /etc/nginx/ssl/retardiochain.com.key
else
    echo "WARNING: SSL Certificates not found! HTTPS will fail."
    echo "Please upload 'retardiochain.com.pem' and 'retardiochain.com.key' to $HOME"
fi
sudo chmod 600 /etc/nginx/ssl/*.key
sudo chmod 644 /etc/nginx/ssl/*.pem

# Setup web directory
sudo mkdir -p /var/www/retardio/downloads
sudo mkdir -p /var/www/webflasher
sudo chown -R $USER:$USER /var/www/retardio
sudo chown -R $USER:$USER /var/www/webflasher

# Setup Webflash
cp ~/retardio-coin/packages/web/website/flasher.html /var/www/webflasher/index.html
# Copy assets to webflasher if needed (assuming assets are shared or in website dir)
if [ -d "~/retardio-coin/packages/web/website/assets" ]; then
    cp -r ~/retardio-coin/packages/web/website/assets /var/www/webflasher/
    cp -r ~/retardio-coin/packages/web/website/css /var/www/webflasher/
    cp -r ~/retardio-coin/packages/web/website/js /var/www/webflasher/
fi

# Setup Wallet (Use standalone generator as requested)
sudo mkdir -p /var/www/wallet
cp ~/retardio-coin/packages/web/wallet_standalone.html /var/www/wallet/index.html

# Create configured all-in-one HTML
sed "s/retardiopool.xyz/$POOL_DOMAIN/g; s/retardiochain.com/$CHAIN_DOMAIN/g" \
    ~/retardio-coin/packages/web/retardio_all_in_one.html > /var/www/retardio/downloads/Retardio.html

# Create landing page
cat > /var/www/retardio/index.html << 'HTMLEOF'
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
    listen 443 ssl;
    server_name $CHAIN_DOMAIN www.$CHAIN_DOMAIN dashboard.$CHAIN_DOMAIN $PUBLIC_IP;
    
    # SSL Configuration
    ssl_certificate /etc/nginx/ssl/retardiochain.com.pem;
    ssl_certificate_key /etc/nginx/ssl/retardiochain.com.key;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_cipher_list ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384;

    # Security Headers
    add_header Strict-Transport-Security "max-age=63072000; includeSubDomains; preload" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;

    root /var/www/retardio;
    index index.html;

    # Main site - Dashboard as Default
    location / {
        proxy_pass http://127.0.0.1:5555/;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
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
        proxy_pass http://127.0.0.1:8082/;
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
        alias /var/www/retardio/downloads;
        autoindex on;
    }
}

# Wallet subdomain - HTTP redirect to HTTPS
server {
    listen 80;
    server_name wallet.$CHAIN_DOMAIN;
    return 301 https://\$host\$request_uri;
}

server {
    listen 443 ssl;
    server_name wallet.$CHAIN_DOMAIN;

    ssl_certificate /etc/nginx/ssl/retardiochain.com.pem;
    ssl_certificate_key /etc/nginx/ssl/retardiochain.com.key;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384;

    # Security Headers
    add_header Strict-Transport-Security "max-age=63072000; includeSubDomains; preload" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;

    root /var/www/wallet;
    index index.html;

    location / {
        try_files \$uri \$uri/ =404;
    }
}

server {
    listen 80;
    listen 443 ssl;
    server_name $POOL_DOMAIN www.$POOL_DOMAIN;

    # SSL Configuration
    ssl_certificate /etc/nginx/ssl/retardiochain.com.pem;
    ssl_certificate_key /etc/nginx/ssl/retardiochain.com.key;

    # Ensure / also works for the dashboard on the pool domain
    location / {
        proxy_pass http://127.0.0.1:5555/;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    location /dashboard {
        proxy_pass http://127.0.0.1:5555/;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
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

server {
    listen 80;
    server_name webflash.$CHAIN_DOMAIN;
    return 301 https://\$host\$request_uri;
}

server {
    listen 443 ssl;
    server_name webflash.$CHAIN_DOMAIN;

    ssl_certificate /etc/nginx/ssl/retardiochain.com.pem;
    ssl_certificate_key /etc/nginx/ssl/retardiochain.com.key;
    ssl_protocols TLSv1.2 TLSv1.3;

    root /var/www/webflasher;
    index index.html;

    location / {
        try_files \$uri \$uri/ =404;
    }
}
EOF

sudo ln -sf /etc/nginx/sites-available/retardio /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default

# Fix permissions for nginx to access www directory
sudo chown -R www-data:www-data /var/www/retardio
sudo chmod -R 755 /var/www/retardio

sudo nginx -t && sudo systemctl reload nginx

# Configure firewall
echo "[8/8] Configuring firewall..."
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 3333/tcp
sudo ufw allow 18333/tcp
sudo ufw --force enable

# Enable and start services
sudo systemctl daemon-reload
sudo systemctl enable retardio-node retardio-pool retardio-pool-ui retardio-explorer
sudo systemctl restart retardio-node

# Wait for node to start
echo ""
echo "Waiting for node to start..."
sleep 10

sudo systemctl restart retardio-pool retardio-pool-ui retardio-explorer

# Register local node with explorer (Wait for Next.js to start)
echo ""
echo "Registering node with block explorer..."
sleep 20
# For the Next.js explorer, we might not need explicit registration if it pulls from RPC directly
# But if there's a hook, we keep it. The MockAPI currently creates fake data, 
# so we need to ensure the REAL API client is used in production.
# TODO: Ensure the Next.js app uses the real RPC creds from environment or config.
# For now, we assume the Next.js app is configured to talk to localhost:18332


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
        packages/web/retardio_all_in_one.html > /var/www/retardio/downloads/Retardio.html

    # Update Wallet (if present)
    if [ -d "packages/wallet" ]; then
        echo "Updating wallet..."
        sudo mkdir -p /var/www/wallet
        sudo cp packages/wallet/index.html /var/www/wallet/
        sudo cp packages/wallet/main.js /var/www/wallet/
        sudo cp packages/wallet/style.css /var/www/wallet/
        if [ -d "packages/wallet/pkg" ]; then
            sudo cp -r packages/wallet/pkg /var/www/wallet/
        fi
        sudo chown -R www-data:www-data /var/www/wallet
    fi

    # Update wallet standalone
    cp packages/web/wallet_standalone.html /var/www/retardio/downloads/wallet.html

    sudo chown -R www-data:www-data /var/www/retardio

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
echo "  Node CLI:      ~/retardio-coin/packages/node/build/bin/retardio-cli -datadir=~/.retardio/data getblockchaininfo"
echo ""
echo "Share http://$PUBLIC_IP with your community!"
echo "=============================================="
