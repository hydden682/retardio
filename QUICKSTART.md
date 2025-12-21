# Retardio Quick Start Guide

Get your Retardio node up and mining in minutes!

## Table of Contents
- [Prerequisites](#prerequisites)
- [Quick Start (Solo Mining)](#quick-start-solo-mining)
- [Quick Start (Pool Setup)](#quick-start-pool-setup)
- [Important Files](#important-files)
- [Common Commands](#common-commands)

---

## Prerequisites

Before you begin, ensure you have:

**For building on Linux:**
```bash
sudo apt-get install build-essential libtool autotools-dev automake pkg-config \
    libevent-dev libboost-all-dev libsqlite3-dev libminiupnpc-dev libzmq3-dev python3
```

**For Windows:**
- Use WSL (Windows Subsystem for Linux) with Ubuntu, OR
- Visual Studio 2019+ with C++ development tools

---

## Quick Start (Solo Mining)

Follow these 6 steps to start mining Retardio:

### Step 1: Mine Genesis Block (First Time Only)

```bash
cd retardio-coin
python mine_genesis.py
```

**Expected output:**
```
Mining genesis block for Retardio...
✓ Found valid genesis block!
Nonce: 123456789
Hash: 000000abc123...

Update chainparams.cpp genesis line to:
genesis = CreateGenesisBlock(1734566400, 123456789, 0x1e0fffff, 1, 239726 * COIN / 100);
```

**Update the code:**
1. Edit `src/kernel/chainparams.cpp` line 136 with the nonce value
2. Uncomment lines 139-141 and add the genesis hash and merkle root

### Step 2: Build Retardio

```bash
./autogen.sh
./configure --without-gui
make -j$(nproc)
```

**Time:** 5-15 minutes depending on your CPU

### Step 3: Configure Node

```bash
# Copy example config
mkdir -p ~/.retardio
cp retardio.conf.example ~/.retardio/retardio.conf

# Edit config (IMPORTANT: Change the RPC password!)
nano ~/.retardio/retardio.conf
```

**Minimal config:**
```ini
server=1
rpcuser=retardiouser
rpcpassword=CHANGE_THIS_PASSWORD
rpcport=18332
port=18333
txindex=1
```

### Step 4: Start Node

**Linux/Mac:**
```bash
chmod +x start_node.sh
./start_node.sh
```

**Windows:**
```batch
start_node.bat
```

**Verify it's running:**
```bash
./src/retardio-cli -datadir=~/.retardio getblockchaininfo
```

### Step 5: Create Wallet & Get Address

```bash
# Create wallet
./src/retardio-cli -datadir=~/.retardio createwallet "mining"

# Generate mining address (will start with 'F')
./src/retardio-cli -datadir=~/.retardio getnewaddress "mining" "legacy"
```

**Example address:** `FaDf8jKmN3pQrS9tV2wX4yZ5bC6dE7fG8h`

### Step 6: Start Mining!

**Mine 100 blocks to bootstrap the chain:**
```bash
./src/retardio-cli -datadir=~/.retardio generatetoaddress 100 FaDf8jKmN3pQrS9tV2wX4yZ5bC6dE7fG8h
```

**Or use continuous mining:**
```bash
chmod +x mine_continuous.sh
./mine_continuous.sh FaDf8jKmN3pQrS9tV2wX4yZ5bC6dE7fG8h
```

**Check your balance:**
```bash
./src/retardio-cli -datadir=~/.retardio getbalance
```

**Note:** Mined coins require 100 confirmations (100 blocks) before you can spend them!

---

## Quick Start (Pool Setup)

For setting up a mining pool to allow multiple miners to collaborate:

### Prerequisites

```bash
sudo apt-get install nodejs npm redis-server git
```

### Automated Setup (Linux)

```bash
chmod +x setup_pool.sh
./setup_pool.sh
```

This script will:
1. Install dependencies (Node.js, Redis)
2. Clone and configure NOMP (Node Open Mining Portal)
3. Set up Retardio pool configuration
4. Create startup scripts

### Manual Pool Setup

**1. Install NOMP:**
```bash
git clone https://github.com/zone117x/node-open-mining-portal.git
cd node-open-mining-portal
npm update && npm install
```

**2. Configure for Retardio:**
```bash
# Copy coin config
cp ../pool-configs/retardio-coin.json coins/retardio.json

# Copy pool config
cp ../pool-configs/retardio-pool.json pool_configs/retardio.json
```

**3. Edit pool config:**
Edit `pool_configs/retardio.json`:
- Change `address` to your pool payout address
- Change `rewardRecipients` address for pool fees
- Update `rpcuser` and `rpcpassword` to match your node

**4. Start the pool:**
```bash
node init.js
```

### Mining to Pool

**Using cpuminer:**
```bash
./cpuminer -a sha256d \
    -o stratum+tcp://YOUR_POOL_IP:3032 \
    -u YOUR_RETARDIO_ADDRESS \
    -p x
```

**Pool port:**
- **3032** - Universal port (all miners, auto-adjusts difficulty 1-16384)

---

## Important Files

### Configuration Files
- **retardio.conf.example** - Example node configuration
- **~/.retardio/retardio.conf** - Your node configuration (after copying example)
- **pool-configs/retardio-pool.json** - Mining pool configuration
- **pool-configs/retardio-coin.json** - Coin configuration for pool

### Scripts
- **start_node.sh** / **start_node.bat** - Start Retardio node
- **stop_node.sh** / **stop_node.bat** - Stop Retardio node
- **mine_genesis.py** - Mine the genesis block (run once)
- **mine_continuous.sh** / **mine_continuous.bat** - Continuous solo mining
- **setup_pool.sh** - Automated pool setup (Linux only)

### Documentation
- **QUICKSTART.md** - This file (quick reference)
- **MINING_SETUP.md** - Comprehensive mining guide
- **RETARDIO_FORK_GUIDE.md** - Complete fork documentation
- **CHANGES_SUMMARY.md** - Summary of all changes from Bitcoin

### Source Code (Key Modified Files)
- **src/kernel/chainparams.cpp** - Network consensus parameters
- **src/validation.cpp** - Block reward calculation (DigiByte emission)

---

## Common Commands

### Node Management

```bash
# Start node
./start_node.sh

# Stop node
./stop_node.sh

# Check if node is running
./src/retardio-cli -datadir=~/.retardio getblockchaininfo

# View debug log
tail -f ~/.retardio/debug.log
```

### Wallet Operations

```bash
# Create new wallet
./src/retardio-cli -datadir=~/.retardio createwallet "wallet_name"

# Load existing wallet
./src/retardio-cli -datadir=~/.retardio loadwallet "wallet_name"

# Generate new address
./src/retardio-cli -datadir=~/.retardio getnewaddress

# Check balance
./src/retardio-cli -datadir=~/.retardio getbalance

# Send coins
./src/retardio-cli -datadir=~/.retardio sendtoaddress "FaDf..." 10.5

# List transactions
./src/retardio-cli -datadir=~/.retardio listtransactions
```

### Mining Commands

```bash
# Mine 1 block
./src/retardio-cli -datadir=~/.retardio generatetoaddress 1 "FaDf..."

# Mine 100 blocks
./src/retardio-cli -datadir=~/.retardio generatetoaddress 100 "FaDf..."

# Get mining info
./src/retardio-cli -datadir=~/.retardio getmininginfo

# Get network hashrate
./src/retardio-cli -datadir=~/.retardio getnetworkhashps
```

### Blockchain Information

```bash
# Get current block count
./src/retardio-cli -datadir=~/.retardio getblockcount

# Get block hash by height
./src/retardio-cli -datadir=~/.retardio getblockhash 100

# Get block details
./src/retardio-cli -datadir=~/.retardio getblock "000000abc123..."

# Get transaction details
./src/retardio-cli -datadir=~/.retardio gettransaction "txid..."

# Get blockchain info (comprehensive)
./src/retardio-cli -datadir=~/.retardio getblockchaininfo
```

### Network Commands

```bash
# Get connected peers
./src/retardio-cli -datadir=~/.retardio getpeerinfo

# Add a peer node
./src/retardio-cli -datadir=~/.retardio addnode "192.168.1.100:18333" "add"

# Remove a peer
./src/retardio-cli -datadir=~/.retardio addnode "192.168.1.100:18333" "remove"

# Get network info
./src/retardio-cli -datadir=~/.retardio getnetworkinfo

# Get node connection count
./src/retardio-cli -datadir=~/.retardio getconnectioncount
```

---

## Network Information

### Chain Parameters
- **Algorithm:** SHA-256 (same as Bitcoin)
- **Block Time:** 30 seconds (can be changed to 15s)
- **Difficulty Adjustment:** Every 120 blocks (~1 hour)
- **Starting Reward:** 2,397.26 RET
- **Reward Reduction:** 1% every 87,600 blocks (12 times per year)
- **Max Supply:** ~21 billion RET (same as DigiByte)

### Network Settings
- **P2P Port:** 18333
- **RPC Port:** 18332
- **Network Magic:** 0xfecabeef
- **Address Prefix:** F (base58: 35)
- **Bech32 Prefix:** ret

### Emission Schedule
| Time | Block | Reward (RET) | % of Start |
|------|-------|--------------|------------|
| Genesis | 0 | 2,397.26 | 100% |
| 1 reduction | 87,600 | 2,373.29 | 99% |
| 1 year | 1,051,200 | 2,148.85 | 90% |
| 2 years | 2,102,400 | 1,931.26 | 81% |
| 5 years | 5,256,000 | 1,484.99 | 62% |
| 10 years | 10,512,000 | 893.26 | 37% |

---

## Troubleshooting

### Node won't start
```bash
# Check debug log
tail -100 ~/.retardio/debug.log

# Verify port is not in use
netstat -tuln | grep 18333

# Try with different port
./src/retardiod -datadir=~/.retardio -port=18334 -daemon
```

### Can't connect to RPC
```bash
# Verify credentials in retardio.conf
cat ~/.retardio/retardio.conf | grep rpc

# Test RPC connection
curl --user retardiouser:password --data-binary '{"jsonrpc": "1.0", "id":"test", "method": "getblockcount", "params": [] }' -H 'content-type: text/plain;' http://127.0.0.1:18332/
```

### Mining too slow
- **Expected:** With CPU mining, you should find blocks every few seconds to minutes
- **If slower:** Difficulty may have adjusted up. Wait for next difficulty adjustment (120 blocks)
- **Solution:** Use pool mining with multiple miners, or add GPU/ASIC miners

### No peers connecting
- **This is normal!** Retardio is a brand new chain with no existing network
- **Solution:** Set up multiple nodes manually and connect them:
  ```bash
  # On Node B, connect to Node A
  ./src/retardio-cli -datadir=~/.retardio addnode "NODE_A_IP:18333" "add"
  ```

---

## Next Steps

1. **Mine initial blocks** - Get 100+ blocks to bootstrap the chain
2. **Set up multiple nodes** - Run nodes on different machines
3. **Connect nodes** - Use `addnode` to create your network
4. **Set up pool** - Allow multiple miners to collaborate
5. **Add features:**
   - Block explorer
   - Web wallet
   - Exchange integration
   - Mobile wallet

---

## Getting Help

### Documentation Files
1. **QUICKSTART.md** (this file) - Quick reference
2. **MINING_SETUP.md** - Detailed mining setup
3. **RETARDIO_FORK_GUIDE.md** - Complete fork guide
4. **CHANGES_SUMMARY.md** - What was changed from Bitcoin

### Checking Logs
```bash
# Main debug log
tail -f ~/.retardio/debug.log

# Pool logs (if running NOMP)
tail -f node-open-mining-portal/logs/debug.log
```

### Key Metrics to Monitor
```bash
# Current block height
./src/retardio-cli -datadir=~/.retardio getblockcount

# Network difficulty
./src/retardio-cli -datadir=~/.retardio getdifficulty

# Your balance
./src/retardio-cli -datadir=~/.retardio getbalance

# Mempool size
./src/retardio-cli -datadir=~/.retardio getmempoolinfo
```

---

## Summary: Getting Started in 3 Commands

```bash
# 1. Mine genesis (first time only)
python mine_genesis.py
# (Update chainparams.cpp with nonce, rebuild)

# 2. Build and start
./autogen.sh && ./configure && make -j$(nproc) && ./start_node.sh

# 3. Mine blocks
./src/retardio-cli -datadir=~/.retardio createwallet "mining"
./src/retardio-cli -datadir=~/.retardio generatetoaddress 100 $(./src/retardio-cli -datadir=~/.retardio getnewaddress)
```

**That's it! You're now mining Retardio!** 🚀
