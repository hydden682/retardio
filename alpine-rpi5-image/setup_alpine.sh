#!/bin/sh
#
# Quick setup for Alpine RPi5 after fresh Alpine install
# Run this if you're starting from stock Alpine
#

set -e

echo "Installing Retardio on Alpine Linux..."

# Install dependencies
apk update
apk add --no-cache \
    build-base cmake ninja git python3 \
    boost-dev libressl-dev libevent-dev \
    sqlite-dev miniupnpc-dev libnatpmp-dev

# Create retardio user
adduser -D -h /home/retardio -s /bin/sh retardio 2>/dev/null || true

# Clone repository
cd /tmp
git clone https://github.com/hydden682/retardio.git -b 29.x-knots
cd retardio

# Build
mkdir -p build && cd build
cmake -G Ninja .. \
    -DBUILD_GUI=OFF \
    -DWITH_ZMQ=OFF \
    -DENABLE_WALLET=ON \
    -DCMAKE_BUILD_TYPE=Release

ninja -j2
ninja install

# Create config
mkdir -p /home/retardio/.retardio
RPC_PASS=$(head -c 32 /dev/urandom | base64 | tr -dc 'a-zA-Z0-9' | head -c 32)

cat > /home/retardio/.retardio/retardio.conf << EOF
chain=regtest
server=1
rpcuser=retardiorpc
rpcpassword=$RPC_PASS
rpcallowip=127.0.0.1
rpcport=22555
dbcache=384
maxmempool=75
maxconnections=32
listen=1
port=22556
debug=0
printtoconsole=0
EOF

chown -R retardio:retardio /home/retardio

# Create init script
cat > /etc/init.d/retardiod << 'INITEOF'
#!/sbin/openrc-run
name="retardiod"
command="/usr/local/bin/retardiod"
command_args="-daemon -conf=/home/retardio/.retardio/retardio.conf"
command_user="retardio"
pidfile="/run/retardiod.pid"
depend() { need net; }
INITEOF

chmod +x /etc/init.d/retardiod
rc-update add retardiod default

echo ""
echo "=============================================="
echo "  Retardio installed successfully!"
echo "=============================================="
echo ""
echo "RPC Password: $RPC_PASS"
echo ""
echo "Start with: rc-service retardiod start"
echo ""
