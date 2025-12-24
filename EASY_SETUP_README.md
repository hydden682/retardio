# Easy Setup - Automatic Node Configuration

## The Simple Way to Get Your Node Running!

Instead of manually rebuilding, configuring, and connecting your node, just run **one script** that does everything automatically.

---

## Quick Start

### Windows (WSL or Git Bash)

Open WSL or Git Bash terminal and run:

```bash
cd /mnt/c/Users/15187/retardio-coin
./easy_setup.sh
```

### Windows (Command Prompt)

Open Command Prompt and run:

```cmd
cd C:\Users\15187\retardio-coin
easy_setup.bat
```

### Linux/Mac

```bash
cd ~/retardio-coin
./easy_setup.sh
```

---

## What It Does Automatically

The setup script will:

1. ✅ **Check if rebuild is needed** - Detects if chainparamsseeds.h changed
2. ✅ **Rebuild your node** - Compiles the code with the networking fix (5-15 min)
3. ✅ **Create configuration** - Generates retardio.conf with secure random password
4. ✅ **Add peer nodes** - Prompts you to add your friend's IP address
5. ✅ **Configure firewall** - Opens port 18333 for connections
6. ✅ **Create wallet** - Sets up a mining wallet automatically
7. ✅ **Generate mining address** - Creates and saves your mining address
8. ✅ **Start the node** - Launches retardiod in background
9. ✅ **Verify connection** - Checks peer count and network status
10. ✅ **Create shortcuts** - Makes `retardio-cli.sh` or `retardio-cli.bat` for easy access

---

## Example Run

```
╔════════════════════════════════════════════╗
║                                            ║
║      RETARDIO EASY SETUP WIZARD            ║
║                                            ║
║  This will automatically:                  ║
║  • Rebuild your node (if needed)          ║
║  • Configure your node                     ║
║  • Connect to peer nodes                   ║
║  • Start your node                         ║
║                                            ║
╚════════════════════════════════════════════╝

==> Step 1: Checking if rebuild is needed...
⚠ chainparamsseeds.h was updated. Rebuild required.

==> Step 2: Building Retardio (this may take 5-15 minutes)...
⚠ Compiling (this is the slow part)...
[===== Build progress =====]
✓ Build completed successfully!

==> Step 3: Setting up data directory...
✓ Created /home/user/.retardio

==> Step 4: Configuring retardio.conf...
✓ Configuration file created
  RPC Password: aB3dEfG9hIjKlMnOpQrStUvWxYz12345
  (saved to /home/user/.retardio/retardio.conf)

==> Step 5: Configure peer nodes...
Do you have a peer node IP address to add? (y/N): y
Enter peer IP address (or 'done' to finish): 192.168.1.100
Enter peer port (default 18333):
✓ Added peer: 192.168.1.100:18333
Add another peer? (y/N): n

==> Step 6: Firewall configuration...
✓ Port 18333 allowed in UFW

==> Step 7: Wallet setup...
✓ Wallet 'mining' created
✓ Mining address: F7j1mx5CQz5YMhybN9TSav1hjcNRoUQGWU

IMPORTANT: Save this address!
  F7j1mx5CQz5YMhybN9TSav1hjcNRoUQGWU

==> Step 8: Checking network status...

Network Status:
  Connected peers: 1
  Current block: 0

✓ Connected to 1 peer(s)!

==> Your IP addresses (share these with peers):
Local IPs:
  192.168.1.50

Public IP:
  203.0.113.45

==> Setup Complete! 🎉

Your Retardio node is now running!
```

---

## After Setup

Once setup completes, you can use these shortcuts:

### Check Node Status

**Linux/Mac/WSL:**
```bash
./retardio-cli.sh getblockchaininfo
./retardio-cli.sh getconnectioncount
./retardio-cli.sh getbalance
```

**Windows:**
```cmd
retardio-cli.bat getblockchaininfo
retardio-cli.bat getconnectioncount
retardio-cli.bat getbalance
```

### Mine Blocks

```bash
# Your mining address is saved to ~/.retardio/mining_address.txt
./retardio-cli.sh generatetoaddress 10 YOUR_MINING_ADDRESS
```

### Stop Node

```bash
./retardio-cli.sh stop
```

---

## Sharing with Your Friend

For your friend to connect to you:

1. **Share this easy_setup script with them**
   - Send them [easy_setup.sh](easy_setup.sh) or [easy_setup.bat](easy_setup.bat)
   - They also need the updated [src/chainparamsseeds.h](src/chainparamsseeds.h)

2. **Share your IP address**
   - The script shows your IP at the end
   - They'll enter it when the script asks "Do you have a peer node IP address to add?"

3. **They run the same script**
   ```bash
   ./easy_setup.sh
   ```
   - When prompted for peer IP, they enter YOUR IP
   - When you run it, you enter THEIR IP

4. **Both nodes will connect automatically!**

---

## What Gets Created

After running the setup script:

```
~/.retardio/                          (or %USERPROFILE%\.retardio on Windows)
├── retardio.conf                     # Auto-generated configuration
├── mining_address.txt                # Your mining address
├── wallet.dat                        # Your wallet
├── blocks/                           # Blockchain data
├── chainstate/                       # UTXO database
└── debug.log                         # Debug log

retardio-coin/
├── retardio-cli.sh (or .bat)        # Quick access shortcut
└── build/
    └── bin/
        ├── retardiod                 # Node daemon (rebuilt)
        └── retardio-cli              # CLI tool (rebuilt)
```

---

## Troubleshooting

### Script says "Build required" but won't build

**On Windows**, the script can't build for you. Use WSL:

```bash
wsl bash -c "cd /mnt/c/Users/15187/retardio-coin && ./easy_setup.sh"
```

Or build manually first:
```bash
wsl bash -c "cd /mnt/c/Users/15187/retardio-coin/build && make -j$(nproc)"
```

Then run the Windows batch file:
```cmd
easy_setup.bat
```

### No peers connecting

1. Make sure your friend also ran the setup script
2. Check firewall: port 18333 must be open
3. Verify you entered the correct IP address
4. Wait 30 seconds and check again:
   ```bash
   ./retardio-cli.sh getconnectioncount
   ```

### Can't create wallet

Make sure the node is running:
```bash
# Check if running
ps aux | grep retardiod

# If not running, start it
./start_node.sh
```

### "Permission denied" on Linux/Mac

Make the script executable:
```bash
chmod +x easy_setup.sh
./easy_setup.sh
```

---

## Manual Steps (If Script Fails)

If the automatic script doesn't work, you can still do it manually:

1. **Rebuild:** See [REBUILD_INSTRUCTIONS.md](REBUILD_INSTRUCTIONS.md)
2. **Configure:** See [NODE_CONNECTION_GUIDE.md](NODE_CONNECTION_GUIDE.md)
3. **Connect:** Use [connect_nodes.sh](connect_nodes.sh) or [connect_nodes.bat](connect_nodes.bat)

---

## Comparison: Easy Setup vs Manual

### Easy Setup (This Script)
- ✅ **One command** - `./easy_setup.sh`
- ✅ **5 minutes** total (most time is building)
- ✅ **Automatic** everything
- ✅ **Beginner friendly**
- ✅ **No configuration knowledge needed**

### Manual Setup
- ❌ **10+ commands** to type
- ❌ **15-30 minutes** of manual work
- ❌ **Easy to make mistakes**
- ❌ **Need to understand config files**
- ❌ **More room for errors**

---

## Files Overview

| File | Purpose | Who Uses It |
|------|---------|-------------|
| [easy_setup.sh](easy_setup.sh) | Linux/Mac/WSL automatic setup | Everyone (recommended!) |
| [easy_setup.bat](easy_setup.bat) | Windows automatic setup | Windows users (after build) |
| [connect_nodes.sh](connect_nodes.sh) | Manual connection helper | Advanced users |
| [connect_nodes.bat](connect_nodes.bat) | Windows connection helper | Windows advanced users |
| [NODE_CONNECTION_GUIDE.md](NODE_CONNECTION_GUIDE.md) | Detailed manual guide | Reference/troubleshooting |
| [REBUILD_INSTRUCTIONS.md](REBUILD_INSTRUCTIONS.md) | Manual rebuild guide | If automatic build fails |

---

## Next Steps After Setup

1. ✅ **Verify peers connected** - `./retardio-cli.sh getconnectioncount` should return > 0
2. ✅ **Mine test blocks** - `./retardio-cli.sh generatetoaddress 10 YOUR_ADDRESS`
3. ✅ **Check synchronization** - Both nodes should have same block count
4. ✅ **Set up stratum pool** - For ESP32/ASIC mining
5. ✅ **Build block explorer** - Web interface for blockchain

---

## Why This Is Better

**Before (Manual):**
```bash
# 1. Clear seed nodes (done already)
# 2. Rebuild
cd build && make -j$(nproc)

# 3. Create config
mkdir -p ~/.retardio
cat > ~/.retardio/retardio.conf << EOF
server=1
rpcuser=user
rpcpassword=pass123
...
EOF

# 4. Add peers
echo "addnode=192.168.1.100:18333" >> ~/.retardio/retardio.conf

# 5. Configure firewall
sudo ufw allow 18333/tcp

# 6. Start node
./src/retardiod -daemon

# 7. Create wallet
./src/retardio-cli createwallet "mining"

# 8. Get address
./src/retardio-cli getnewaddress

# ... etc (10+ more steps)
```

**Now (Automatic):**
```bash
./easy_setup.sh
# Answer a few questions
# Done! ✓
```

---

## Perfect For

- ✅ First-time users
- ✅ Non-technical users
- ✅ Quick testing/demo
- ✅ Setting up multiple nodes quickly
- ✅ Sharing with friends (just send the script!)

---

## Summary

**Just run one script, answer a few questions, and you're mining!**

**Linux/Mac/WSL:**
```bash
./easy_setup.sh
```

**Windows:**
```cmd
easy_setup.bat
```

That's it! No need to understand config files, firewall rules, or manual commands. Everything is done automatically.

**Share this script with your friend and you'll both be connected in minutes!** 🚀
