# Retardio Complete Testing Guide

## How to Test Everything

This guide shows you how to thoroughly test the entire Retardio setup from start to finish.

---

## Quick Automated Test

Run the automated test suite:

```bash
chmod +x test_setup.sh
./test_setup.sh
```

This automatically tests:
- ✅ All scripts exist and are valid
- ✅ File permissions correct
- ✅ chainparamsseeds.h properly cleared
- ✅ Build system configured
- ✅ Binaries built (if present)
- ✅ Documentation complete
- ✅ Package creation works
- ✅ Node operation (if running)

---

## Manual Testing - Complete Walkthrough

### Test 1: Clean Environment Test

**Purpose:** Test that setup works from scratch

**Steps:**

1. **Create a test VM or container:**
   ```bash
   # Using Docker
   docker run -it ubuntu:22.04 /bin/bash

   # Or use a fresh VM
   ```

2. **Clone the repo:**
   ```bash
   git clone https://github.com/hydden682/retardio.git
   cd retardio
   ```

3. **Run master setup:**
   ```bash
   chmod +x retardio_master_setup.sh
   ./retardio_master_setup.sh
   ```

4. **Answer prompts:**
   - Install dependencies? `y`
   - Peer IP? `n` (skip for solo test)
   - Open firewall? `y`
   - Mine initial blocks? `y`
   - Install ckpool? `y`
   - Start ckpool? `y`

5. **Wait for completion** (10-15 minutes)

**Expected Result:**
```
╔══════════════════════════════════════════════════════╗
║              🎉  ALL DONE! 🎉                        ║
╚══════════════════════════════════════════════════════╝

Your Retardio network is fully operational!
```

**Verify:**
```bash
# Node running
ps aux | grep retardiod
# Should show retardiod process

# CLI works
./cli getblockchaininfo
# Should return blockchain info

# Has blocks
./cli getblockcount
# Should show: 100 (if you mined initial blocks)

# Wallet exists
./cli getbalance
# Should show balance

# ckpool running
ps aux | grep ckpool
# Should show ckpool process
```

✅ **PASS** if all checks succeed

---

### Test 2: Two-Node Network Test

**Purpose:** Test that two nodes can connect and sync

**You'll need:** Two computers or two VMs

**Node 1 Setup:**

1. **Run setup:**
   ```bash
   ./retardio_master_setup.sh
   ```

2. **Skip adding peers** (for now)

3. **Find your IP:**
   ```bash
   ip addr show | grep "inet " | grep -v "127.0.0.1"
   ```
   Note your IP (e.g., 192.168.1.50)

4. **Mine some blocks:**
   ```bash
   ./mine.sh 50
   ```

5. **Check block count:**
   ```bash
   ./cli getblockcount
   # Should show: 50
   ```

**Node 2 Setup:**

1. **Run setup on second machine:**
   ```bash
   ./retardio_master_setup.sh
   ```

2. **When asked for peer IP:**
   Enter Node 1's IP (e.g., 192.168.1.50)

3. **Wait for setup to complete**

**Verification:**

**On Node 2:**
```bash
# Check connections
./cli getconnectioncount
# Should show: 1

# Check block count
./cli getblockcount
# Should show: 50 (synced from Node 1!)

# Check peer info
./cli getpeerinfo
# Should show Node 1's IP
```

**On Node 1:**
```bash
# Check connections
./cli getconnectioncount
# Should show: 1

# Add Node 2 manually if not connected
./cli addnode "NODE2_IP:18333" "add"
```

**Test Block Propagation:**

**On Node 1:**
```bash
./mine.sh 1
```

**On Node 2** (within 5 seconds):
```bash
./cli getblockcount
# Should show: 51 (increased by 1!)
```

✅ **PASS** if blocks sync between nodes

---

### Test 3: Stratum Pool Test

**Purpose:** Test that ckpool works and accepts connections

**Prerequisites:** Node must be running

**Steps:**

1. **Check ckpool is running:**
   ```bash
   ps aux | grep ckpool
   ```

2. **If not running, start it:**
   ```bash
   cd ~/ckpool
   ./start_pool.sh
   ```

3. **Check logs:**
   ```bash
   tail -f ~/ckpool/ckpool.log
   ```

   Should show:
   ```
   ckpool starting
   Proxy difficulty set to 1
   Stratifier ready
   ```

4. **Test connection:**
   ```bash
   telnet localhost 3333
   ```

   Should connect successfully. Type `Ctrl+]` then `quit` to exit.

5. **Test with mining software** (if available):
   ```bash
   # Example with cpuminer
   cpuminer -a sha256d \
     -o stratum+tcp://127.0.0.1:3333 \
     -u YOUR_MINING_ADDRESS \
     -p x
   ```

   Should show:
   ```
   [2024-12-XX] Stratum connection established
   [2024-12-XX] Difficulty set to 1
   ```

6. **Mine with built-in miner instead:**
   ```bash
   ./mine.sh 5
   ```

   Check balance:
   ```bash
   ./cli getbalance
   ```

   Should show rewards from mined blocks.

✅ **PASS** if pool accepts connections and mining works

---

### Test 4: Package Distribution Test

**Purpose:** Test that the installer package works on a clean system

**Steps:**

1. **Create the package:**
   ```bash
   ./create_installer.sh
   ```

2. **Verify package created:**
   ```bash
   ls -lh retardio_installer_v1.0.0.tar.gz
   # Should show file ~2MB
   ```

3. **Copy to clean system:**
   ```bash
   # Copy to USB, email, or test VM
   scp retardio_installer_v1.0.0.tar.gz user@testvm:/tmp/
   ```

4. **On clean system, extract:**
   ```bash
   cd /tmp
   tar -xzf retardio_installer_v1.0.0.tar.gz
   cd retardio_installer/
   ```

5. **Verify contents:**
   ```bash
   ls -la
   ```

   Should have:
   - retardio_master_setup.sh
   - README.txt
   - INSTALLATION_GUIDE.md
   - INSTALL_WINDOWS.bat
   - etc.

6. **Run installer:**
   ```bash
   ./retardio_master_setup.sh
   ```

7. **Verify full setup completes**

✅ **PASS** if installer works on clean system

---

## Test Checklist

Use this checklist to ensure complete testing:

- [ ] ✅ Automated test suite passes
- [ ] ✅ Clean install works
- [ ] ✅ Two nodes connect and sync
- [ ] ✅ Blocks propagate between nodes
- [ ] ✅ Stratum pool accepts connections
- [ ] ✅ Mining works (solo)
- [ ] ✅ Transactions send and confirm
- [ ] ✅ Package creates successfully
- [ ] ✅ Package installs on clean system
- [ ] ✅ Helper scripts work
- [ ] ✅ RPC patch enables solo mining
- [ ] ✅ All documentation accessible

---

## Final Validation

Before declaring everything working:

```bash
# Run automated tests
./test_setup.sh

# Check all services
ps aux | grep -E "retardiod|ckpool"

# Verify connectivity
./cli getconnectioncount

# Verify sync
./cli getblockcount

# Verify balance
./cli getbalance

# Check pool
tail -20 ~/ckpool/ckpool.log
```

**All should return successful results.**

---

**Run `./test_setup.sh` now to validate everything!** 🚀
