# Testing Retardio - All Options

## How to Test Your Setup

You have **3 testing options** depending on how thorough you want to be:

---

## Option 1: Quick Test (5 Minutes) ⚡

**For:** Quick validation that everything works

**File:** [QUICK_TEST.md](QUICK_TEST.md)

**Command:**
```bash
./test_setup.sh
```

**Tests:**
- ✅ Scripts exist and are valid
- ✅ Files have correct permissions
- ✅ Build system configured
- ✅ Binaries work
- ✅ Package creation
- ✅ Node responds

**Time:** 2-5 minutes

---

## Option 2: Automated Test (10 Minutes) 🤖

**For:** Complete automated validation

**File:** [test_setup.sh](test_setup.sh)

**Command:**
```bash
chmod +x test_setup.sh
./test_setup.sh
```

**Tests Everything:**
- File existence
- Script syntax
- Permissions
- Configuration
- Build system
- Binaries
- Documentation
- Package creation
- Node operation

**Time:** 5-10 minutes

**Output:**
```
╔══════════════════════════════════════════════════════╗
║              ✓ ALL TESTS PASSED! ✓                   ║
╚══════════════════════════════════════════════════════╝
```

---

## Option 3: Manual Complete Test (30+ Minutes) 📋

**For:** Thorough step-by-step testing

**File:** [TESTING_GUIDE.md](TESTING_GUIDE.md)

**Tests:**
1. Clean environment test
2. Two-node network test
3. Stratum pool test
4. Package distribution test
5. Windows installation test
6. RPC patch test
7. Helper scripts test
8. Stress test
9. Network propagation test
10. Transaction test

**Time:** 30-60 minutes

**Use when:**
- First time setup
- Before production deployment
- After major changes
- Debugging issues

---

## Which Test Should I Use?

### Just Built It?
→ Run **Quick Test** (Option 1)
```bash
./test_setup.sh
```

### About to Share with Others?
→ Run **Automated Test** (Option 2)
```bash
./test_setup.sh
```

### Going Live / Production?
→ Do **Manual Complete Test** (Option 3)
→ Read [TESTING_GUIDE.md](TESTING_GUIDE.md)

### Something Not Working?
→ Do **Manual Complete Test** (Option 3)
→ Follow step-by-step to find issue

---

## Test Commands Quick Reference

| What to Test | Command | Expected Result |
|--------------|---------|-----------------|
| **Everything (auto)** | `./test_setup.sh` | "ALL TESTS PASSED" |
| **Node running** | `ps aux \| grep retardiod` | Shows process |
| **Node responds** | `./cli getblockchaininfo` | Returns JSON |
| **Has blocks** | `./cli getblockcount` | Returns number |
| **Has peers** | `./cli getconnectioncount` | Returns > 0 |
| **Pool running** | `ps aux \| grep ckpool` | Shows process |
| **Pool accepts** | `telnet localhost 3333` | Connects |
| **Can mine** | `./mine.sh 1` | Mines 1 block |
| **Helper works** | `./status.sh` | Shows status |
| **Package works** | `./create_installer.sh` | Creates .tar.gz |

---

## Test Results

### All Tests Pass ✅

```bash
$ ./test_setup.sh
Total Tests: 35
Passed: 35
Failed: 0
✓ ALL TESTS PASSED! ✓
```

**You're ready to use Retardio!**

Next steps:
- Share installer with friends
- Connect nodes together
- Start mining!

---

### Some Tests Fail ❌

```bash
$ ./test_setup.sh
Total Tests: 35
Passed: 30
Failed: 5
✗ SOME TESTS FAILED ✗
```

**What to do:**
1. Read the failed test names
2. Check the specific issue
3. Fix and re-run

**Common failures:**
- "retardiod binary not found" → Run `./retardio_master_setup.sh`
- "Connection refused" → Check firewall: `sudo ufw allow 18333`
- "No peers connected" → Add peer: `./cli addnode "IP:18333" "add"`
- "ckpool not running" → Start: `cd ~/ckpool && ./start_pool.sh`

---

## Testing Checklist

Use this before declaring "everything works":

**Required Tests:**
- [ ] Automated test suite passes
- [ ] Node starts and responds
- [ ] Can query blockchain info
- [ ] Wallet exists and works
- [ ] Can mine blocks

**Network Tests** (if using multiple nodes):
- [ ] Nodes connect to each other
- [ ] Blocks sync between nodes
- [ ] Transactions propagate

**Pool Tests** (if using ckpool):
- [ ] ckpool starts successfully
- [ ] Pool accepts connections
- [ ] Pool communicates with node

**Package Tests** (if distributing):
- [ ] Package creates successfully
- [ ] Package extracts correctly
- [ ] Installer works on clean system

**Documentation Tests:**
- [ ] All .md files accessible
- [ ] Scripts are executable
- [ ] Examples work correctly

---

## Performance Benchmarks

**Expected performance after tests pass:**

| Operation | Time | Status |
|-----------|------|--------|
| Setup from scratch | 10-15 min | Normal |
| Test suite run | 2-5 min | Normal |
| Package creation | 10 sec | Normal |
| Node startup | 5 sec | Normal |
| RPC response | <100ms | Good |
| Block propagation | <5 sec | Good |
| Mining 1 block | 10-60 sec | Varies |
| Blockchain sync (100 blocks) | 30 sec | Normal |

If your times are significantly different, check:
- CPU performance
- Network speed
- Disk speed (SSD recommended)

---

## Files Created for Testing

| File | Purpose | Use When |
|------|---------|----------|
| [test_setup.sh](test_setup.sh) | Automated test runner | Always |
| [QUICK_TEST.md](QUICK_TEST.md) | 5-minute test guide | Quick check |
| [TESTING_GUIDE.md](TESTING_GUIDE.md) | Complete test manual | Thorough testing |
| [TEST_README.md](TEST_README.md) | This file | Overview |

---

## Getting Help

**Tests fail and you don't know why?**

1. **Check logs:**
   ```bash
   tail -100 ~/.retardio/debug.log
   ```

2. **Check test output:**
   ```bash
   ./test_setup.sh > test_output.txt 2>&1
   cat test_output.txt
   ```

3. **Run specific test manually:**
   ```bash
   # Example: Test node connection
   ./cli getblockchaininfo
   ```

4. **Read troubleshooting:**
   - [TESTING_GUIDE.md](TESTING_GUIDE.md) - Detailed troubleshooting
   - [NODE_CONNECTION_GUIDE.md](NODE_CONNECTION_GUIDE.md) - Network issues
   - [ONE_COMMAND_SETUP.md](ONE_COMMAND_SETUP.md) - Setup issues

---

## Test Summary

**Three ways to test:**

1. **Fast:** `./test_setup.sh` (5 min)
2. **Complete:** `./test_setup.sh` + manual verification (15 min)
3. **Thorough:** Follow [TESTING_GUIDE.md](TESTING_GUIDE.md) (60 min)

**Start with the fast test:**
```bash
chmod +x test_setup.sh
./test_setup.sh
```

**If it passes, you're done!** ✅

**If it fails, use the detailed guide:**
```bash
cat TESTING_GUIDE.md
```

---

## Start Testing Now

```bash
# Quick automated test
./test_setup.sh

# If that passes, you're ready!
# If not, read TESTING_GUIDE.md for detailed help
```

🚀 **Happy testing!**
