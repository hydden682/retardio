# Retardio Node Setup for Raspberry Pi 5 (4GB)

Complete guide to run a Retardio full node on Raspberry Pi 5.

## Hardware Requirements

- **Raspberry Pi 5 (4GB RAM)**
- **microSD Card**: 32GB+ (Class 10/A2 recommended) OR
- **External SSD**: 256GB+ (recommended for better performance)
- **Power Supply**: Official RPi5 27W USB-C PSU
- **Cooling**: Active or passive cooling recommended
- **Network**: Ethernet or WiFi

## Quick Start (One Command)

```bash
curl -sSL https://raw.githubusercontent.com/hydden682/retardio/29.x-knots/setup_rpi5.sh | bash
```

Or download and run manually:

```bash
wget https://raw.githubusercontent.com/hydden682/retardio/29.x-knots/setup_rpi5.sh
chmod +x setup_rpi5.sh
./setup_rpi5.sh
```

---

## Manual Installation

### Step 1: Prepare Raspberry Pi OS

1. Flash **Raspberry Pi OS Lite (64-bit)** using Raspberry Pi Imager
2. Enable SSH in imager settings
3. Boot and connect via SSH

```bash
sudo apt update && sudo apt upgrade -y
```

### Step 2: Install Dependencies

```bash
sudo apt install -y \
  build-essential libtool autotools-dev automake pkg-config \
  libssl-dev libevent-dev bsdmainutils python3 \
  libboost-all-dev libsqlite3-dev libminiupnpc-dev \
  libnatpmp-dev libzmq3-dev systemtap-sdt-dev \
  cmake ninja-build git
```

### Step 3: Clone and Build

```bash
cd ~
git clone https://github.com/hydden682/retardio.git -b 29.x-knots
cd retardio

# Build (takes 30-60 minutes on RPi5)
mkdir build && cd build
cmake -G Ninja .. \
  -DBUILD_GUI=OFF \
  -DWITH_ZMQ=OFF \
  -DENABLE_WALLET=ON \
  -DCMAKE_BUILD_TYPE=Release

ninja -j2
```

### Step 4: Install

```bash
sudo ninja install
```

### Step 5: Create Data Directory

```bash
mkdir -p ~/.retardio
```

### Step 6: Create Configuration

```bash
cat > ~/.retardio/retardio.conf << 'EOF'
# Retardio Node Configuration - Optimized for RPi5 4GB

# Network (regtest for testing, main for production)
chain=regtest

# RPC Settings
server=1
rpcuser=retardiorpc
rpcpassword=CHANGE_THIS_PASSWORD
rpcallowip=127.0.0.1
rpcport=22555

# Performance (optimized for 4GB RAM)
dbcache=512
maxmempool=100
maxconnections=40
maxuploadtarget=1000

# Pruning (optional - saves disk space)
# prune=2000

# Listening
listen=1
port=22556

# Logging
debug=0
printtoconsole=0
EOF
```

**⚠️ IMPORTANT**: Change `rpcpassword` to a secure random password!

### Step 7: Create Systemd Service

```bash
sudo tee /etc/systemd/system/retardiod.service << 'EOF'
[Unit]
Description=Retardio Daemon
After=network.target

[Service]
Type=forking
User=pi
ExecStart=/usr/local/bin/retardiod -daemon -conf=/home/pi/.retardio/retardio.conf
ExecStop=/usr/local/bin/retardio-cli stop
Restart=on-failure
RestartSec=30
TimeoutStopSec=300
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable retardiod
```

### Step 8: Start the Node

```bash
sudo systemctl start retardiod
```

### Step 9: Verify

```bash
# Check service status
sudo systemctl status retardiod

# Check blockchain info
retardio-cli getblockchaininfo

# Check network info
retardio-cli getnetworkinfo

# Check peer connections
retardio-cli getpeerinfo
```

---

## Useful Commands

| Command | Description |
|---------|-------------|
| `retardio-cli getblockchaininfo` | Blockchain sync status |
| `retardio-cli getnetworkinfo` | Network and version info |
| `retardio-cli getpeerinfo` | Connected peers |
| `retardio-cli getmininginfo` | Mining status |
| `retardio-cli getnewaddress` | Generate new address |
| `retardio-cli getbalance` | Wallet balance |
| `sudo systemctl restart retardiod` | Restart node |
| `sudo journalctl -u retardiod -f` | View logs |

---

## Connecting to the Network

To connect to another Retardio node:

```bash
retardio-cli addnode "IP:22556" "add"
```

To connect to the main seed node (if available):

```bash
retardio-cli addnode "seed.retardio.net:22556" "add"
```

---

## Firewall Setup

```bash
sudo ufw allow 22556/tcp  # P2P port
sudo ufw allow 22555/tcp  # RPC port (only if needed externally)
sudo ufw enable
```

---

## Performance Tips for 4GB RAM

1. **Use external SSD** instead of microSD for blockchain data
2. **Enable swap** (already enabled by default on RPi OS)
3. **Limit connections** to ~40 peers
4. **Consider pruning** if disk space is limited
5. **Monitor memory**: `htop` or `free -h`

---

## Troubleshooting

### Node won't start

```bash
sudo journalctl -u retardiod -n 50
```

### Out of memory

- Reduce `dbcache` to 256
- Reduce `maxmempool` to 50
- Enable pruning

### Slow sync

- Use SSD instead of microSD
- Increase `dbcache` if RAM allows
- Check network connection

---

## Mining (Optional)

To solo mine on your RPi5 node:

```bash
# Generate mining address
retardio-cli getnewaddress "mining"

# Mine 1 block (regtest only)
retardio-cli generatetoaddress 1 "YOUR_ADDRESS"
```

For continuous mining, use the pool setup or external miner.
