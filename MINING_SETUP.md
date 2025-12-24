# Retardio Mining Setup Guide

Complete guide for setting up Retardio nodes and mining pools.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Step 1: Mine the Genesis Block](#step-1-mine-the-genesis-block)
3. [Step 2: Build Retardio](#step-2-build-retardio)
4. [Step 3: Configure Your Node](#step-3-configure-your-node)
5. [Step 4: Start Your Node](#step-4-start-your-node)
6. [Step 5: Solo Mining](#step-5-solo-mining)
7. [Step 6: Setting Up a Mining Pool](#step-6-setting-up-a-mining-pool)
8. [Step 7: Mining with Pool](#step-7-mining-with-pool)
9. [Troubleshooting](#troubleshooting)

---

## Prerequisites

### System Requirements
- **OS**: Linux (Ubuntu 20.04+), macOS, or Windows 10/11
- **RAM**: 4GB minimum, 8GB recommended
- **Disk**: 10GB free space
- **CPU**: Multi-core processor (for compilation)

### Required Software

**Linux/Mac:**
```bash
# Ubuntu/Debian
sudo apt-get update
sudo apt-get install build-essential libtool autotools-dev automake pkg-config bsdmainutils python3
sudo apt-get install libevent-dev libboost-system-dev libboost-filesystem-dev libboost-test-dev libboost-thread-dev
sudo apt-get install libsqlite3-dev
sudo apt-get install libminiupnpc-dev libzmq3-dev libqrencode-dev
```

**Windows:**
- Visual Studio 2019 or later with C++ development tools
- Or use WSL (Windows Subsystem for Linux)

---

## Step 1: Mine the Genesis Block

Before you can run the network, you MUST mine the genesis block.

### 1.1 Run Genesis Miner

```bash
cd retardio-coin
python mine_genesis.py
```

This will output something like:
```
Mining genesis block for Retardio...
Emission: 2,397.26 RET starting, 12 reductions/year (EXACT DigiByte)
Max supply: 21 billion RET (same as DGB)

Nonce: 123456789
Hash: 000000abc123...
Time taken: 45.32 seconds

Update chainparams.cpp genesis line to:
genesis = CreateGenesisBlock(1734566400, 123456789, 0x1e0fffff, 1, 239726 * COIN / 100);

Genesis hash: 000000abc123...
```

### 1.2 Update chainparams.cpp

Edit `src/kernel/chainparams.cpp` at line 136:

**Before:**
```cpp
genesis = CreateGenesisBlock(1734566400, 0, 0x1e0fffff, 1, 239726 * COIN / 100);
```

**After (use YOUR nonce):**
```cpp
genesis = CreateGenesisBlock(1734566400, 123456789, 0x1e0fffff, 1, 239726 * COIN / 100);
```

### 1.3 Uncomment Hash Assertions

At lines 139-141, uncomment and add YOUR hashes:

```cpp
assert(consensus.hashGenesisBlock == uint256{"0x000000abc123..."});
assert(genesis.hashMerkleRoot == uint256{"0x4a5e1e4baab89f3a32518a88c31bc87f618f76673e2cc77ab2127b7afdeda33b"});
```

---

## Step 2: Build Retardio

### 2.1 Linux/Mac Build

```bash
cd retardio-coin

# Generate configure script
./autogen.sh

# Configure (basic build without GUI)
./configure --without-gui

# Or with GUI (requires Qt)
# ./configure

# Compile (use -j for parallel compilation)
make -j$(nproc)

# Optional: Run tests
make check
```

### 2.2 Windows Build

**Option A: Using WSL (Recommended)**
1. Install WSL with Ubuntu
2. Follow Linux build instructions above

**Option B: Native Windows Build**
1. Open Visual Studio Command Prompt
2. Follow Retardio Windows build guide
3. Or use depends system:
```bash
cd depends
make HOST=x86_64-w64-mingw32
cd ..
./autogen.sh
./configure --prefix=`pwd`/depends/x86_64-w64-mingw32
make
```

### 2.3 Verify Build

```bash
# Check if binaries exist
ls -lh src/retardiod
ls -lh src/retardio-cli

# Test version
./src/retardiod --version
```

---

## Step 3: Configure Your Node

### 3.1 Create Data Directory

```bash
# Linux/Mac
mkdir -p ~/.retardio

# Windows
mkdir %USERPROFILE%\.retardio
```

### 3.2 Create Configuration File

Copy the example config:

```bash
# Linux/Mac
cp retardio.conf.example ~/.retardio/retardio.conf

# Windows
copy retardio.conf.example %USERPROFILE%\.retardio\retardio.conf
```

### 3.3 Edit Configuration

Edit `~/.retardio/retardio.conf` (or `%USERPROFILE%\.retardio\retardio.conf` on Windows):

**Minimal configuration:**
```
# RPC Settings (REQUIRED)
server=1
rpcuser=retardiouser
rpcpassword=CHANGE_THIS_TO_SECURE_PASSWORD

# Network
listen=1
port=18333
rpcport=18332

# Performance
dbcache=450
maxmempool=300

# Transaction index (useful for pool)
txindex=1
```

**IMPORTANT:** Change `rpcpassword` to something secure!

---

## Step 4: Start Your Node

### 4.1 Using Scripts

**Linux/Mac:**
```bash
chmod +x start_node.sh stop_node.sh
./start_node.sh
```

**Windows:**
```batch
start_node.bat
```

### 4.2 Manual Start

**Linux/Mac:**
```bash
./src/retardiod -datadir=~/.retardio -daemon
```

**Windows:**
```batch
src\retardiod.exe -datadir=%USERPROFILE%\.retardio
```

### 4.3 Check Node Status

```bash
# Get blockchain info
./src/retardio-cli -datadir=~/.retardio getblockchaininfo

# Get network info
./src/retardio-cli -datadir=~/.retardio getnetworkinfo

# Get peer info
./src/retardio-cli -datadir=~/.retardio getpeerinfo
```

You should see:
```json
{
  "chain": "main",
  "blocks": 0,
  "headers": 0,
  "bestblockhash": "000000abc123...",
  "difficulty": 0.000244140625,
  "mediantime": 1734566400,
  "verificationprogress": 1,
  "initialblockdownload": false,
  "chainwork": "...",
  "size_on_disk": 293,
  "pruned": false
}
```

---

## Step 5: Solo Mining

Solo mining means your node generates blocks directly without a pool.

### 5.1 Generate a Wallet

```bash
# Create new wallet
./src/retardio-cli -datadir=~/.retardio createwallet "mining_wallet"

# Generate a new address
./src/retardio-cli -datadir=~/.retardio getnewaddress "mining" "legacy"
```

This will output an address starting with 'F', like:
```
FaDf8jKmN3pQrS9tV2wX4yZ5bC6dE7fG8h
```

### 5.2 Start Mining Blocks

```bash
# Mine 1 block to your address
./src/retardio-cli -datadir=~/.retardio generatetoaddress 1 FaDf8jKmN3pQrS9tV2wX4yZ5bC6dE7fG8h

# Mine 100 blocks (initial blockchain)
./src/retardio-cli -datadir=~/.retardio generatetoaddress 100 FaDf8jKmN3pQrS9tV2wX4yZ5bC6dE7fG8h
```

**Output:**
```json
[
  "000000a1b2c3d4e5f6...",
  "000000a1b2c3d4e5f7...",
  ...
]
```

### 5.3 Check Your Balance

```bash
# Check wallet balance
./src/retardio-cli -datadir=~/.retardio getbalance

# List transactions
./src/retardio-cli -datadir=~/.retardio listtransactions
```

After mining 100 blocks, you should have:
- Block 0: 2,397.26 RET
- Block 1: 2,397.26 RET
- ...
- Block 99: 2,397.26 RET

But note that coinbase rewards require 100 confirmations before they can be spent!

### 5.4 Continuous Solo Mining

Create a mining script `mine_continuous.sh`:

```bash
#!/bin/bash
RETARDIO_CLI="./src/retardio-cli"
DATADIR="$HOME/.retardio"
ADDRESS="FaDf8jKmN3pQrS9tV2wX4yZ5bC6dE7fG8h"  # Change this!

echo "Starting continuous mining to $ADDRESS"
echo "Press Ctrl+C to stop"

while true; do
    BLOCK=$($RETARDIO_CLI -datadir="$DATADIR" generatetoaddress 1 "$ADDRESS")
    HEIGHT=$($RETARDIO_CLI -datadir="$DATADIR" getblockcount)
    echo "[$(date)] Mined block $HEIGHT: $BLOCK"
    sleep 1
done
```

Make it executable and run:
```bash
chmod +x mine_continuous.sh
./mine_continuous.sh
```

---

## Step 6: Setting Up a Mining Pool

For collaborative mining, you'll want to set up a stratum mining pool.

### 6.1 Pool Architecture

A typical mining pool consists of:
1. **Retardio Node** - Full node with RPC enabled
2. **Stratum Server** - Handles miner connections and work distribution
3. **Pool Database** - Tracks shares and payouts (Redis, MySQL, etc.)
4. **Pool Frontend** - Web interface for miners (optional)

### 6.2 Choose Pool Software

Popular options for SHA-256 pools:

#### Option A: NOMP (Node Open Mining Portal)
- **Language:** Node.js
- **Repo:** https://github.com/zone117x/node-open-mining-portal
- **Pros:** Well-documented, supports multiple coins
- **Cons:** Older codebase, may need updates

#### Option B: Node-Stratum-Pool
- **Language:** Node.js
- **Repo:** https://github.com/zone117x/node-stratum-pool
- **Pros:** Lightweight, modular
- **Cons:** Requires more manual setup

#### Option C: MPOS + Stratum Mining
- **Language:** PHP + Python
- **Repos:**
  - MPOS: https://github.com/MPOS/php-mpos
  - Stratum: https://github.com/Crypto-Expert/stratum-mining
- **Pros:** Mature, full-featured
- **Cons:** Complex setup

### 6.3 Install NOMP (Recommended for Beginners)

#### Prerequisites
```bash
# Install Node.js 16+ and Redis
sudo apt-get install nodejs npm redis-server git

# Start Redis
sudo systemctl start redis-server
sudo systemctl enable redis-server
```

#### Install NOMP
```bash
# Clone NOMP
git clone https://github.com/zone117x/node-open-mining-portal.git
cd node-open-mining-portal

# Install dependencies
npm update
npm install
```

### 6.4 Configure NOMP for Retardio

#### Create Pool Config

Create `pool_configs/retardio.json`:

```json
{
    "enabled": true,
    "coin": "retardio.json",

    "address": "FaDf8jKmN3pQrS9tV2wX4yZ5bC6dE7fG8h",

    "rewardRecipients": {
        "FbCdEfGhIjKlMnOpQrStUvWxYz12345678": 0.5
    },

    "paymentProcessing": {
        "enabled": true,
        "paymentInterval": 30,
        "minimumPayment": 0.1,
        "daemon": {
            "host": "127.0.0.1",
            "port": 18332,
            "user": "retardiouser",
            "password": "your_rpc_password"
        }
    },

    "ports": {
        "3032": {
            "diff": 8,
            "varDiff": {
                "minDiff": 1,
                "maxDiff": 16384,
                "targetTime": 15,
                "retargetTime": 90,
                "variancePercent": 30
            }
        }
    },

    "daemons": [
        {
            "host": "127.0.0.1",
            "port": 18332,
            "user": "retardiouser",
            "password": "your_rpc_password"
        }
    ],

    "p2p": {
        "enabled": false,
        "host": "127.0.0.1",
        "port": 18333,
        "disableTransactions": true
    },

    "mposMode": {
        "enabled": false,
        "host": "127.0.0.1",
        "port": 3306,
        "user": "me",
        "password": "mypass",
        "database": "retardio",
        "checkPassword": true,
        "autoCreateWorker": false
    }
}
```

#### Create Coin Config

Create `coins/retardio.json`:

```json
{
    "name": "Retardio",
    "symbol": "RET",
    "algorithm": "sha256",

    "peerMagic": "fecabeef",
    "peerMagicTestnet": "fecabeef",

    "txMessages": false,

    "rewardRecipients": {
    }
}
```

### 6.5 Start NOMP

```bash
cd node-open-mining-portal

# Start the pool
npm start
```

You should see:
```
[MASTER] Spawned 1 pool(s) on 1 thread(s)
[POOL]   retardio thread spawned
[POOL]   retardio stratum pool server listening on port 3032
```

---

## Step 7: Mining with Pool

### 7.1 Choose Mining Software

For SHA-256 (Retardio uses same algorithm as Bitcoin):

**CPU Mining:**
- **cpuminer-multi**: https://github.com/tpruvot/cpuminer-multi
- **minerd**: Basic CPU miner

**GPU Mining:**
- **cgminer**: https://github.com/ckolivas/cgminer (AMD)
- **bfgminer**: https://github.com/luke-jr/bfgminer

**ASIC Mining:**
- Any SHA-256 ASIC will work (but is massively overpowered for a new network)

### 7.2 Install cpuminer-multi (CPU Mining)

```bash
# Install dependencies
sudo apt-get install build-essential libcurl4-openssl-dev libssl-dev libjansson-dev automake

# Clone and build
git clone https://github.com/tpruvot/cpuminer-multi.git
cd cpuminer-multi
./autogen.sh
./configure CFLAGS="-O3 -march=native"
make
```

### 7.3 Start Mining

#### Solo Mining (Direct to Node)
```bash
./cpuminer -a sha256d \
    -o http://127.0.0.1:18332 \
    -u retardiouser \
    -p your_rpc_password \
    --coinbase-addr=FaDf8jKmN3pQrS9tV2wX4yZ5bC6dE7fG8h
```

#### Pool Mining (via Stratum)
```bash
./cpuminer -a sha256d \
    -o stratum+tcp://127.0.0.1:3032 \
    -u FaDf8jKmN3pQrS9tV2wX4yZ5bC6dE7fG8h \
    -p x
```

### 7.4 Monitor Mining

**Watch miner output:**
```
[2024-12-18 12:34:56] thread 0: 123456 hashes, 45.2 khash/s
[2024-12-18 12:34:56] thread 1: 123456 hashes, 44.8 khash/s
[2024-12-18 12:34:57] accepted: 1/1 (100.00%), 90.0 khash/s (yay!!!)
```

**Check node:**
```bash
# Get current block height
./src/retardio-cli -datadir=~/.retardio getblockcount

# Watch blocks in real-time
watch -n 1 './src/retardio-cli -datadir=~/.retardio getblockcount'

# Monitor debug log
tail -f ~/.retardio/debug.log
```

---

## Troubleshooting

### Node Won't Start

**Check debug.log:**
```bash
tail -100 ~/.retardio/debug.log
```

**Common issues:**
- Port already in use: Change `port=` in retardio.conf
- Permission denied: Check file permissions on data directory
- Database corruption: Delete `~/.retardio/blocks` and `~/.retardio/chainstate`, restart

### Can't Connect to RPC

**Verify config:**
```bash
cat ~/.retardio/retardio.conf | grep rpc
```

**Test connection:**
```bash
curl --user retardiouser:your_password --data-binary '{"jsonrpc": "1.0", "id":"test", "method": "getblockchaininfo", "params": [] }' -H 'content-type: text/plain;' http://127.0.0.1:18332/
```

### Mining Not Finding Blocks

**For solo mining:**
- Initial difficulty is low but not zero
- With CPU mining at ~100 kH/s, you should find blocks every few minutes
- Check that your address is correct
- Verify node is running: `getblockchaininfo`

**For pool mining:**
- Check pool is connected to node
- Verify stratum port is open
- Check miner is connected to correct pool address/port
- Look at pool logs for errors

### Peers Not Connecting

**This is EXPECTED for a new chain!**
- No other nodes exist yet
- You must manually connect nodes using:
```bash
# On node A, get your IP
hostname -I

# On node B, connect to node A
./src/retardio-cli -datadir=~/.retardio addnode "NODE_A_IP:18333" "add"
```

---

## Next Steps

### 1. Establish Network

- Set up multiple nodes on different machines
- Connect them using `addnode` commands
- Set up DNS seeds once you have stable nodes

### 2. Set Up Block Explorer

- Install Insight explorer
- Or use Electrum server + Electrum wallet

### 3. Create Exchange Listings

- Once network is stable, approach exchanges
- Provide technical specs and genesis block info

### 4. Secure the Network

- Monitor hashrate
- Implement checkpoints as chain matures
- Consider additional 51% attack protection

### 5. Build Community

- Create website and social media
- Write whitepaper/documentation
- Engage miners and users

---

## Quick Reference

### Common Commands

```bash
# Node management
./start_node.sh                    # Start node
./stop_node.sh                     # Stop node
./src/retardio-cli getinfo         # Quick status

# Wallet operations
./src/retardio-cli getnewaddress             # Generate address
./src/retardio-cli getbalance                # Check balance
./src/retardio-cli sendtoaddress ADDR AMT    # Send coins

# Mining
./src/retardio-cli generatetoaddress 1 ADDR  # Mine 1 block
./src/retardio-cli getmininginfo             # Mining stats

# Network
./src/retardio-cli getpeerinfo               # Connected peers
./src/retardio-cli addnode IP:PORT "add"     # Add peer
./src/retardio-cli getnetworkinfo            # Network info

# Blockchain
./src/retardio-cli getblockcount             # Current height
./src/retardio-cli getblockhash HEIGHT       # Get block hash
./src/retardio-cli getblock HASH             # Get block details
./src/retardio-cli gettxout TXID VOUT        # Check UTXO
```

### File Locations

```
~/.retardio/                    # Data directory
├── retardio.conf               # Configuration file
├── wallet.dat                  # Wallet file
├── blocks/                     # Blockchain data
├── chainstate/                 # UTXO database
└── debug.log                   # Debug log
```

### Network Information

- **Chain:** Retardio (mainnet)
- **Algorithm:** SHA-256 (double SHA-256)
- **Block Time:** 30 seconds (configurable to 15s)
- **Difficulty Adjustment:** Every 120 blocks (~1 hour)
- **Starting Reward:** 2,397.26 RET
- **Reduction:** 1% every 87,600 blocks (12/year)
- **Max Supply:** ~21 billion RET
- **Address Prefix:** F (base58: 35)
- **Bech32 Prefix:** ret
- **P2P Port:** 18333
- **RPC Port:** 18332
- **Magic Bytes:** 0xfecabeef

---

Good luck with your Retardio network!
