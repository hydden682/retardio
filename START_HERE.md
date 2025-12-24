# 🚀 START HERE - Connect Your Retardio Nodes

## The Problem Was Fixed!

Your nodes couldn't talk because they had Bitcoin's seed nodes hardcoded. **This has been fixed.**

## The Super Easy Way (Recommended!)

### Just Run One Script:

**Windows (WSL):**
```bash
wsl bash -c "cd /mnt/c/Users/15187/retardio-coin && ./easy_setup.sh"
```

**Windows (Git Bash):**
```bash
cd /mnt/c/Users/15187/retardio-coin
./easy_setup.sh
```

**Linux/Mac:**
```bash
cd ~/retardio-coin
./easy_setup.sh
```

That's it! The script will:
- ✅ Rebuild your node automatically
- ✅ Create config file with secure password
- ✅ Ask for your friend's IP and add it
- ✅ Open firewall port 18333
- ✅ Create wallet and mining address
- ✅ Start your node
- ✅ Show you connection status

**Takes 5-10 minutes, mostly build time.**

---

## For Your Friend

1. **Send them these files:**
   - [easy_setup.sh](easy_setup.sh) (or [easy_setup.bat](easy_setup.bat) for Windows)
   - [src/chainparamsseeds.h](src/chainparamsseeds.h)

2. **They put chainparamsseeds.h in their `src/` folder**

3. **They run the same script:**
   ```bash
   ./easy_setup.sh
   ```

4. **When asked for peer IP, they enter YOUR IP**

5. **Done! Your nodes connect automatically!**

---

## After Both Nodes Are Set Up

### Check Connection

```bash
./retardio-cli.sh getconnectioncount
```

Should show `1` or higher.

### Test Block Sync

**On your node:**
```bash
./retardio-cli.sh generatetoaddress 1 YOUR_ADDRESS
```

**On friend's node:**
```bash
./retardio-cli.sh getblockcount
```

Should increase by 1!

### View Peer Info

```bash
./retardio-cli.sh getpeerinfo
```

Shows your connected peer's IP, version, etc.

---

## What If Script Doesn't Work?

### Fallback: Manual Method

If the automatic script fails, follow these:

1. **Rebuild:** [REBUILD_INSTRUCTIONS.md](REBUILD_INSTRUCTIONS.md)
2. **Connect:** [NODE_CONNECTION_GUIDE.md](NODE_CONNECTION_GUIDE.md)

Or use the interactive helper:
```bash
./connect_nodes.sh
```

---

## Quick Command Reference

Once setup is complete:

```bash
# Check status
./retardio-cli.sh getblockchaininfo

# Check peers
./retardio-cli.sh getconnectioncount

# Mine blocks
./retardio-cli.sh generatetoaddress 10 YOUR_ADDRESS

# Check balance
./retardio-cli.sh getbalance

# Stop node
./retardio-cli.sh stop
```

---

## Firewall Reminder

Port **18333** must be open on BOTH nodes.

**Linux:**
```bash
sudo ufw allow 18333/tcp
```

**Windows:**
- Windows Defender Firewall
- Advanced Settings → Inbound Rules → New Rule
- Port 18333 TCP → Allow

---

## Documentation Tree

```
START_HERE.md  ← You are here!
    ↓
EASY_SETUP_README.md  ← How the auto script works
    ↓
NODE_CONNECTION_GUIDE.md  ← Manual method (if needed)
    ↓
REBUILD_INSTRUCTIONS.md  ← If rebuild fails
```

---

## Expected Result

After running `easy_setup.sh` on both nodes:

```
Your Retardio Node:
  Connected peers: 1
  Current block: 0

Friend's Node:
  Connected peers: 1
  Current block: 0
```

**Now you can:**
- ✅ Mine blocks that sync between nodes
- ✅ Send transactions
- ✅ Set up stratum mining pool
- ✅ Build block explorer
- ✅ Add more nodes to network

---

## Next: Stratum Mining Pool

Once nodes are connected, set up ckpool for ESP32/ASIC mining:

1. Fix the getblocktemplate RPC check (see [SOLO_MINING_STATUS.md](SOLO_MINING_STATUS.md))
2. Configure ckpool with your node's RPC
3. Point your ESP32 miners to the pool

---

## Need Help?

1. **Quick start:** Just run `./easy_setup.sh`
2. **Detailed guide:** [EASY_SETUP_README.md](EASY_SETUP_README.md)
3. **Manual method:** [NODE_CONNECTION_GUIDE.md](NODE_CONNECTION_GUIDE.md)
4. **Rebuild issues:** [REBUILD_INSTRUCTIONS.md](REBUILD_INSTRUCTIONS.md)
5. **Debug logs:** `tail -f ~/.retardio/debug.log`

---

## TL;DR - The Absolute Quickest Way

### You:
```bash
./easy_setup.sh
# Enter friend's IP when asked
```

### Your Friend:
```bash
./easy_setup.sh
# Enter your IP when asked
```

### Both of You:
```bash
./retardio-cli.sh getconnectioncount
# Should show: 1
```

**Done! Start mining!** 🎉

---

**The easy_setup.sh script does EVERYTHING automatically. Just run it and answer the questions!**
