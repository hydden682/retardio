# Quick Test - 5 Minute Validation

## Fastest Way to Test Everything Works

### Step 1: Run Automated Tests (2 min)

```bash
chmod +x test_setup.sh
./test_setup.sh
```

**Expected Output:**
```
╔══════════════════════════════════════════════════════╗
║              ✓ ALL TESTS PASSED! ✓                   ║
╚══════════════════════════════════════════════════════╝

Your Retardio setup is ready to use!
```

If this passes, skip to Step 5 (everything works!).

If it fails, continue to manual tests below.

---

### Step 2: Test Node (30 sec)

```bash
# Run setup if not done yet
./retardio_master_setup.sh

# Skip prompts with these answers:
# Install dependencies? y
# Peer IP? n
# Open firewall? y
# Mine blocks? y
# Install ckpool? y
# Start ckpool? y
```

Wait 10-15 minutes for build to complete.

---

### Step 3: Verify Node Works (30 sec)

```bash
# Check node is running
ps aux | grep retardiod

# Check blockchain
./cli getblockchaininfo

# Check blocks
./cli getblockcount

# Should show 100 or more
```

✅ If all commands work, node is good!

---

### Step 4: Test Mining Pool (1 min)

```bash
# Check ckpool running
ps aux | grep ckpool

# Test connection
telnet localhost 3333
# Press Ctrl+] then type "quit"

# Check logs
tail -20 ~/ckpool/ckpool.log
```

✅ If ckpool accepts connection, pool is good!

---

### Step 5: Test Network (2 min - requires friend)

**On your machine:**
```bash
# Get your IP
ip addr show | grep "inet " | grep -v "127.0.0.1"

# Share IP with friend
```

**Friend adds you:**
```bash
./cli addnode "YOUR_IP:18333" "add"

# Check connection
./cli getconnectioncount
# Should show: 1
```

**You mine a block:**
```bash
./mine.sh 1
```

**Friend checks:**
```bash
./cli getblockcount
# Should increase within 5 seconds!
```

✅ If friend's block count increases, networking works!

---

## Summary - What to Test

| Test | Command | Pass Criteria |
|------|---------|---------------|
| **Automated** | `./test_setup.sh` | "ALL TESTS PASSED" |
| **Node** | `./cli getblockchaininfo` | Returns JSON |
| **Blocks** | `./cli getblockcount` | Returns number > 0 |
| **Pool** | `telnet localhost 3333` | Connects |
| **Network** | `./cli getconnectioncount` | Returns > 0 |
| **Sync** | Mine block on one node, check other | Block counts match |

---

## One-Liner Full Test

Test everything in one command:

```bash
./test_setup.sh && \
  ./cli getblockchaininfo && \
  ./cli getconnectioncount && \
  ps aux | grep -E "retardiod|ckpool" && \
  echo "✅ ALL WORKING!"
```

If you see "✅ ALL WORKING!" at the end, everything is perfect!

---

## Quick Troubleshooting

**Problem: Test script fails**
→ Read the error, usually missing dependencies
→ Answer `y` when setup asks to install dependencies

**Problem: Node not running**
→ Run: `./retardio_master_setup.sh`

**Problem: Pool not running**
→ Run: `cd ~/ckpool && ./start_pool.sh`

**Problem: No peers**
→ Add peer: `./cli addnode "IP:18333" "add"`
→ Check firewall: `sudo ufw allow 18333`

---

## Expected Timeline

| Phase | Time |
|-------|------|
| Run automated tests | 2 min |
| Run master setup (if needed) | 10-15 min |
| Verify node works | 30 sec |
| Test pool | 1 min |
| Test with friend | 2 min |
| **Total** | **15-20 min** |

---

## Success Looks Like This

```bash
$ ./test_setup.sh
[... tests running ...]
Total Tests: 35
Passed: 35
Failed: 0
✓ ALL TESTS PASSED! ✓

$ ./cli getblockchaininfo
{
  "chain": "main",
  "blocks": 100,
  ...
}

$ ./cli getconnectioncount
2

$ ps aux | grep retardiod
user    1234  retardiod -daemon

$ ps aux | grep ckpool
user    5678  ckpool -c retardio.conf
```

**All commands return successfully = Everything works!** ✅

---

**Start testing now:**
```bash
./test_setup.sh
```
