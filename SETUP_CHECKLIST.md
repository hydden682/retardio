# Retardio Setup Checklist

Follow this checklist to set up Retardio from scratch. Check off each item as you complete it.

## Phase 1: Genesis Block & Build

### [ ] 1.1 Mine Genesis Block
```bash
cd retardio-coin
python mine_genesis.py
```
- [ ] Script completes successfully
- [ ] Note down the **nonce** value
- [ ] Note down the **genesis hash**
- [ ] Note down the **merkle root** (should be: `4a5e1e4baab89f3a32518a88c31bc87f618f76673e2cc77ab2127b7afdeda33b`)

### [ ] 1.2 Update Source Code
Edit `src/kernel/chainparams.cpp`:

- [ ] **Line 136:** Update with your nonce
  ```cpp
  genesis = CreateGenesisBlock(1734566400, YOUR_NONCE_HERE, 0x1e0fffff, 1, 239726 * COIN / 100);
  ```

- [ ] **Lines 139-141:** Uncomment and add your genesis hash
  ```cpp
  assert(consensus.hashGenesisBlock == uint256{"0xYOUR_GENESIS_HASH_HERE"});
  assert(genesis.hashMerkleRoot == uint256{"0x4a5e1e4baab89f3a32518a88c31bc87f618f76673e2cc77ab2127b7afdeda33b"});
  ```

### [ ] 1.3 Install Build Dependencies

**Linux/Ubuntu:**
```bash
sudo apt-get update
sudo apt-get install build-essential libtool autotools-dev automake pkg-config \
    bsdmainutils python3 libevent-dev libboost-system-dev libboost-filesystem-dev \
    libboost-test-dev libboost-thread-dev libsqlite3-dev libminiupnpc-dev \
    libzmq3-dev libqrencode-dev
```

**Windows:**
- [ ] Install WSL with Ubuntu, OR
- [ ] Install Visual Studio 2019+ with C++ tools

### [ ] 1.4 Build Retardio
```bash
./autogen.sh
./configure --without-gui
make -j$(nproc)
```

- [ ] Build completes without errors
- [ ] Binaries exist: `src/retardiod` and `src/retardio-cli`
- [ ] Test version: `./src/retardiod --version`

**Expected time:** 5-15 minutes

---

## Phase 2: Node Configuration

### [ ] 2.1 Create Data Directory
```bash
mkdir -p ~/.retardio
```

### [ ] 2.2 Create Configuration File
```bash
cp retardio.conf.example ~/.retardio/retardio.conf
```

### [ ] 2.3 Edit Configuration
Edit `~/.retardio/retardio.conf`:

- [ ] Set `server=1`
- [ ] Set `rpcuser=retardiouser` (or your choice)
- [ ] **IMPORTANT:** Change `rpcpassword` to a secure password
- [ ] Set `rpcport=18332`
- [ ] Set `port=18333`
- [ ] Set `txindex=1`

**Minimal config:**
```ini
server=1
rpcuser=retardiouser
rpcpassword=YOUR_SECURE_PASSWORD_HERE
rpcport=18332
port=18333
txindex=1
listen=1
```

---

## Phase 3: Start Node

### [ ] 3.1 Make Scripts Executable (Linux/Mac)
```bash
chmod +x start_node.sh stop_node.sh mine_continuous.sh
```

### [ ] 3.2 Start the Node

**Linux/Mac:**
```bash
./start_node.sh
```

**Windows:**
```batch
start_node.bat
```

### [ ] 3.3 Verify Node is Running
```bash
./src/retardio-cli -datadir=~/.retardio getblockchaininfo
```

Expected output should show:
- [ ] `"chain": "main"`
- [ ] `"blocks": 0` (initially)
- [ ] `"bestblockhash"` matches your genesis hash
- [ ] No errors

### [ ] 3.4 Check Debug Log (Optional)
```bash
tail -f ~/.retardio/debug.log
```
- [ ] No critical errors
- [ ] Sees "init message: Done loading"

---

## Phase 4: Wallet Setup & Solo Mining

### [ ] 4.1 Create Wallet
```bash
./src/retardio-cli -datadir=~/.retardio createwallet "mining"
```
- [ ] Wallet created successfully

### [ ] 4.2 Generate Mining Address
```bash
./src/retardio-cli -datadir=~/.retardio getnewaddress "mining" "legacy"
```
- [ ] Address starts with 'F'
- [ ] **Save this address!** Example: `FaDf8jKmN3pQrS9tV2wX4yZ5bC6dE7fG8h`

### [ ] 4.3 Mine Initial Blocks
```bash
./src/retardio-cli -datadir=~/.retardio generatetoaddress 100 YOUR_F_ADDRESS
```
- [ ] Successfully mines 100 blocks
- [ ] Check block count: `./src/retardio-cli -datadir=~/.retardio getblockcount` returns `100`

### [ ] 4.4 Verify Block Rewards
```bash
./src/retardio-cli -datadir=~/.retardio getbalance
```
- [ ] Balance shows 0.00 (blocks need 100 confirmations)

### [ ] 4.5 Mine 100 More Blocks
```bash
./src/retardio-cli -datadir=~/.retardio generatetoaddress 100 YOUR_F_ADDRESS
```
- [ ] Now at block 200
- [ ] Balance should show ~2,397 RET (first block's reward is now mature)

### [ ] 4.6 Test Continuous Mining (Optional)
```bash
./mine_continuous.sh YOUR_F_ADDRESS
```
- [ ] Script runs and mines blocks continuously
- [ ] Press Ctrl+C to stop
- [ ] Shows mining statistics

---

## Phase 5: Pool Setup (Optional)

Only complete this section if you want to run a mining pool.

### [ ] 5.1 Install Pool Dependencies
```bash
sudo apt-get install nodejs npm redis-server git
```

### [ ] 5.2 Start Redis
```bash
sudo systemctl start redis-server
sudo systemctl enable redis-server
redis-cli ping  # Should respond with PONG
```
- [ ] Redis responds with `PONG`

### [ ] 5.3 Run Pool Setup Script
```bash
chmod +x setup_pool.sh
./setup_pool.sh
```

OR manually:

### [ ] 5.4 Clone NOMP (Manual Method)
```bash
git clone https://github.com/zone117x/node-open-mining-portal.git
cd node-open-mining-portal
npm update
npm install
```

### [ ] 5.5 Configure NOMP for Retardio
```bash
# Copy configs
cp ../pool-configs/retardio-coin.json coins/retardio.json
cp ../pool-configs/retardio-pool.json pool_configs/retardio.json
```

### [ ] 5.6 Edit Pool Configuration
Edit `pool_configs/retardio.json`:

- [ ] Change `address` to your pool payout address (must start with F)
- [ ] Change fee address in `rewardRecipients`
- [ ] Update `rpcuser` to match your node
- [ ] Update `rpcpassword` to match your node

### [ ] 5.7 Start Mining Pool
```bash
cd node-open-mining-portal
node init.js
```

Expected output:
- [ ] "Spawned 1 pool(s) on 1 thread(s)"
- [ ] "retardio stratum pool server listening on port 3032"
- [ ] No errors

---

## Phase 6: Mining Software Setup (Optional)

### [ ] 6.1 Install cpuminer (CPU Mining)
```bash
git clone https://github.com/tpruvot/cpuminer-multi.git
cd cpuminer-multi
./autogen.sh
./configure CFLAGS="-O3 -march=native"
make
```

### [ ] 6.2 Test Solo Mining
```bash
./cpuminer -a sha256d \
    -o http://127.0.0.1:18332 \
    -u retardiouser \
    -p YOUR_RPC_PASSWORD \
    --coinbase-addr=YOUR_F_ADDRESS
```
- [ ] Miner connects successfully
- [ ] Shows hashrate
- [ ] Finds blocks

### [ ] 6.3 Test Pool Mining
```bash
./cpuminer -a sha256d \
    -o stratum+tcp://127.0.0.1:3032 \
    -u YOUR_F_ADDRESS \
    -p x
```
- [ ] Miner connects to pool
- [ ] Submits shares
- [ ] Shows accepted shares

---

## Phase 7: Network Setup (Multi-Node)

### [ ] 7.1 Set Up Second Node
On a different machine:
- [ ] Repeat Phases 1-3 (Genesis block should use SAME nonce and hash!)
- [ ] Start node

### [ ] 7.2 Connect Nodes
On Node B:
```bash
./src/retardio-cli -datadir=~/.retardio addnode "NODE_A_IP:18333" "add"
```

On Node A:
```bash
./src/retardio-cli -datadir=~/.retardio getpeerinfo
```
- [ ] Shows connected peer
- [ ] Peer count > 0

### [ ] 7.3 Test Block Propagation
On Node A:
```bash
./src/retardio-cli -datadir=~/.retardio generatetoaddress 1 YOUR_ADDRESS
```

On Node B:
```bash
./src/retardio-cli -datadir=~/.retardio getblockcount
```
- [ ] Block count increases
- [ ] Blocks sync between nodes

---

## Phase 8: Verification & Testing

### [ ] 8.1 Verify Consensus Parameters
```bash
./src/retardio-cli -datadir=~/.retardio getblockchaininfo
```
Check:
- [ ] Block time: ~30 seconds average
- [ ] Difficulty adjusts every 120 blocks
- [ ] Addresses start with 'F'

### [ ] 8.2 Verify Block Rewards
```bash
./src/retardio-cli -datadir=~/.retardio getblock $(./src/retardio-cli -datadir=~/.retardio getblockhash 0) 2
```
- [ ] Coinbase reward = 2,397.26 RET (239726000000 satoshis)

### [ ] 8.3 Test Difficulty Adjustment
- [ ] Mine at least 240 blocks
- [ ] Check difficulty at block 120: `./src/retardio-cli getdifficulty`
- [ ] Verify difficulty changed from initial value

### [ ] 8.4 Test Transaction
```bash
# Generate another address
./src/retardio-cli -datadir=~/.retardio getnewaddress

# Send coins
./src/retardio-cli -datadir=~/.retardio sendtoaddress "FnewAddress..." 10.0
```
- [ ] Transaction created
- [ ] Transaction in mempool: `./src/retardio-cli getmempoolinfo`
- [ ] Mine a block to confirm
- [ ] Balance updated correctly

### [ ] 8.5 Test Wallet Backup
```bash
./src/retardio-cli -datadir=~/.retardio backupwallet "~/.retardio/wallet_backup.dat"
```
- [ ] Backup created successfully

---

## Phase 9: Production Readiness

### [ ] 9.1 Security Checklist
- [ ] RPC password is strong and unique
- [ ] Firewall rules configured (allow 18333, block 18332 from internet)
- [ ] Wallet encrypted: `./src/retardio-cli encryptwallet "passphrase"`
- [ ] Regular backups scheduled
- [ ] Debug logging reduced (set `debug=0` in config)

### [ ] 9.2 Performance Tuning
- [ ] Increased `dbcache` in retardio.conf (e.g., `dbcache=1000`)
- [ ] Increased `maxmempool` if needed
- [ ] Using SSD for blockchain data (recommended)

### [ ] 9.3 Monitoring Setup
- [ ] Log rotation configured
- [ ] Disk space monitoring
- [ ] Process monitoring (systemd service or similar)
- [ ] Alert system for node issues

### [ ] 9.4 Documentation
- [ ] Network details documented
- [ ] Genesis block info recorded
- [ ] Node setup procedure documented
- [ ] Recovery procedures documented

---

## Phase 10: Going Live

### [ ] 10.1 DNS Seed Nodes (Future)
- [ ] Set up DNS seeds once network is stable
- [ ] Add DNS seeds to `chainparams.cpp`
- [ ] Rebuild and redistribute

### [ ] 10.2 Checkpoints (Future)
- [ ] Add checkpoints for major block heights
- [ ] Update `chainparams.cpp` with checkpoint data

### [ ] 10.3 Community
- [ ] Create website
- [ ] Set up social media
- [ ] Write whitepaper/documentation
- [ ] Create block explorer
- [ ] Engage with miners

### [ ] 10.4 Exchange Integration (Future)
- [ ] Provide technical specifications
- [ ] Submit to coin listing sites
- [ ] Approach exchanges for listing

---

## Quick Status Check

At any point, verify your setup:

```bash
# Node status
./src/retardio-cli -datadir=~/.retardio getblockchaininfo

# Wallet balance
./src/retardio-cli -datadir=~/.retardio getbalance

# Mining status
./src/retardio-cli -datadir=~/.retardio getmininginfo

# Network peers
./src/retardio-cli -datadir=~/.retardio getpeerinfo

# Current block
./src/retardio-cli -datadir=~/.retardio getblockcount
```

---

## Troubleshooting Reference

### Node won't start
1. Check `~/.retardio/debug.log`
2. Verify port 18333 is available
3. Check file permissions on data directory

### RPC connection failed
1. Verify `retardio.conf` has correct credentials
2. Check node is running: `ps aux | grep retardiod`
3. Test connection: `curl --user user:pass --data-binary '{"method":"getblockcount"}' http://127.0.0.1:18332/`

### Mining not working
1. Verify wallet has addresses
2. Check node is synced
3. Verify difficulty isn't too high
4. Check miner is using correct algorithm (sha256d)

### Pool not starting
1. Verify Redis is running: `redis-cli ping`
2. Check pool config file syntax (valid JSON)
3. Verify node RPC credentials match
4. Check pool logs for errors

---

## Completion Checklist Summary

Once you've completed all phases:

- [x] Genesis block mined
- [x] Code built successfully
- [x] Node running and synced
- [x] Wallet created and mining
- [x] Blocks being mined successfully
- [x] Block rewards correct (2,397.26 RET)
- [x] Difficulty adjusting properly
- [x] Transactions working
- [ ] Pool operational (if applicable)
- [ ] Multiple nodes connected (if applicable)

**Congratulations!** Your Retardio network is now operational! 🎉

---

## Next: See Documentation

- **QUICKSTART.md** - Quick reference guide
- **MINING_SETUP.md** - Comprehensive mining guide
- **RETARDIO_FORK_GUIDE.md** - Technical fork documentation
- **CHANGES_SUMMARY.md** - Summary of changes from Bitcoin
