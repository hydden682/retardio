# OXMAY - Retardio Network Testing Guide

Hey oxmay! Here's everything you need to test the Retardio network.

## Quick Links
- **Block Explorer**: https://retardio-blockexplorer.onrender.com
- **Current Network Status**: 1 node online, genesis block mined

## What's Ready
- Full Bitcoin-fork blockchain (Retardio)
- Public block explorer (like blockchain.com but for Retardio)
- GUI wallet (wallet_gui.html - open in browser)
- Mining capability

---

## Option 1: Quick Test (Just Browse)

Visit the block explorer: https://retardio-blockexplorer.onrender.com

You can see:
- Network status
- Block list (currently just genesis block)
- Transaction details
- Connected nodes

---

## Option 2: Run Your Own Node (Full Test)

### Step 1: Build the Node

**On Linux/Mac:**
```bash
git clone https://github.com/AustinKelsworthy/retardio-coin.git
cd retardio-coin

# Install dependencies (Ubuntu/Debian)
sudo apt-get update
sudo apt-get install -y build-essential libtool autotools-dev automake pkg-config \
    bsdmainutils python3 libssl-dev libevent-dev libboost-all-dev libsqlite3-dev

# Build
./autogen.sh
./configure --without-gui --disable-tests --disable-bench
make -j$(nproc)
```

**On Windows:**
Use WSL2 (Windows Subsystem for Linux) and follow the Linux instructions.

### Step 2: Set Up Data Directory

```bash
mkdir -p ~/.retardio/data

cat > ~/.retardio/data/retardio.conf << 'EOF'
# Retardio Node Configuration
server=1
daemon=1
listen=1
port=18333
rpcport=18332

# RPC credentials (change these!)
rpcuser=retardio
rpcpassword=yourpassword123

# Allow RPC connections
rpcallowip=127.0.0.1
rpcbind=127.0.0.1

datadir=~/.retardio/data
gen=0
maxconnections=50

# Connect to the main node
addnode=96.236.21.232:18333
EOF
```

### Step 3: Start the Node

```bash
./src/retardiod -datadir=$HOME/.retardio/data -daemon
```

### Step 4: Check Status

```bash
./src/retardio-cli -datadir=$HOME/.retardio/data getblockchaininfo
./src/retardio-cli -datadir=$HOME/.retardio/data getpeerinfo
```

---

## Option 3: Register Your Node with the Explorer

If you want your node to show up on the public block explorer:

### Easy Way (Port Forwarding)
1. Forward port 18332 (RPC) on your router to your machine
2. Register your node:
```bash
curl -X POST https://retardio-blockexplorer.onrender.com/api/nodes/register \
  -H "Content-Type: application/json" \
  -d '{
    "host": "YOUR_PUBLIC_IP",
    "port": 18332,
    "rpc_user": "retardio",
    "rpc_pass": "yourpassword123"
  }'
```

### Secure Way (Tailscale - Recommended)
1. Run the Tailscale setup script:
```bash
./scripts/setup_tailscale.sh
```
2. Share your Tailscale IP with us to add to the explorer

---

## Option 4: Test Mining

Once your node is synced:

```bash
# Create a wallet
./src/retardio-cli -datadir=$HOME/.retardio/data createwallet "mywallet"

# Get a mining address
./src/retardio-cli -datadir=$HOME/.retardio/data getnewaddress "mining" "legacy"

# Mine some blocks (solo mining)
./src/retardio-cli -datadir=$HOME/.retardio/data generatetoaddress 1 YOUR_ADDRESS
```

---

## Testing Checklist

- [ ] Can access block explorer at https://retardio-blockexplorer.onrender.com
- [ ] Can see genesis block (block 0)
- [ ] Built and ran a node locally
- [ ] Node synced the genesis block
- [ ] Node connected to peer (getpeerinfo shows connections)
- [ ] Created a wallet
- [ ] Generated a receiving address
- [ ] (Optional) Mined a block
- [ ] (Optional) Registered node with explorer

---

## Troubleshooting

**Node won't start:**
```bash
# Check the log
tail -50 ~/.retardio/data/debug.log
```

**Can't connect to peers:**
- Make sure port 18333 is not blocked by firewall
- Check that addnode is set correctly in config

**RPC not working:**
```bash
# Test RPC locally
curl --user retardio:yourpassword123 \
  --data-binary '{"jsonrpc":"1.0","id":"test","method":"getblockcount","params":[]}' \
  -H 'content-type: text/plain;' \
  http://127.0.0.1:18332/
```

---

## Network Info

- **Coin Name**: Retardio (RTD)
- **P2P Port**: 18333
- **RPC Port**: 18332
- **Block Time**: ~10 minutes (same as Bitcoin)
- **Initial Reward**: ~2397 RTD (genesis block)
- **Address Prefix**: Starts with 'R' or 'F'

---

## Questions?

Hit me up if anything doesn't work!

- Explorer: https://retardio-blockexplorer.onrender.com
- GitHub: https://github.com/AustinKelsworthy/retardio-coin
