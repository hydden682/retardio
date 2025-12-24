#!/bin/bash
#
# Create Retardio All-in-One Package
# This creates a self-contained installer package
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGE_DIR="${SCRIPT_DIR}/retardio_installer"
VERSION="1.0.0"

echo "Creating Retardio All-in-One Installer Package..."
echo ""

# Create package directory
rm -rf "$PACKAGE_DIR"
mkdir -p "$PACKAGE_DIR"

# Copy essential files
echo "[1/5] Copying setup scripts..."
cp "${SCRIPT_DIR}/retardio_master_setup.sh" "$PACKAGE_DIR/"
cp "${SCRIPT_DIR}/src/chainparamsseeds.h" "$PACKAGE_DIR/" 2>/dev/null || echo "Warning: chainparamsseeds.h not found"

# Create README
echo "[2/5] Creating README..."
cat > "${PACKAGE_DIR}/README.txt" << 'EOF'
╔══════════════════════════════════════════════════════╗
║                                                      ║
║         RETARDIO ALL-IN-ONE INSTALLER                ║
║                                                      ║
╚══════════════════════════════════════════════════════╝

QUICK START:
============

1. Extract this entire folder somewhere (e.g., C:\retardio or ~/retardio)

2. Open terminal in this folder

3. Run the installer:

   Linux/Mac/WSL:
   --------------
   chmod +x retardio_master_setup.sh
   ./retardio_master_setup.sh

   Windows (WSL):
   --------------
   wsl bash retardio_master_setup.sh

4. Answer the questions:
   - Enter your friend's IP address when asked
   - Choose yes to install ckpool for mining
   - Wait for build to complete (5-15 minutes)

5. Done! Your node is running and mining pool is ready!


WHAT IT DOES:
=============
✓ Builds the Retardio node from source
✓ Patches networking to connect peers
✓ Patches RPC for solo mining
✓ Creates secure configuration
✓ Connects to peer nodes
✓ Starts and syncs blockchain
✓ Installs ckpool stratum server
✓ Creates helper scripts


SYSTEM REQUIREMENTS:
====================
- Linux, macOS, or Windows with WSL
- 4GB RAM minimum (8GB recommended)
- 10GB free disk space
- Internet connection
- Build tools (script will install if missing)


AFTER INSTALLATION:
===================
Quick commands:
  ./cli getblockchaininfo    - Check node status
  ./status.sh                - Full status report
  ./mine.sh 10               - Mine 10 blocks

Stratum pool:
  - Runs on port 3333
  - Point miners to: stratum+tcp://YOUR_IP:3333

Share your IP with friends so they can connect!


TROUBLESHOOTING:
================
If build fails:
  - Make sure you have internet connection
  - Let script install dependencies
  - Check you have 10GB free space

If peers won't connect:
  - Open port 18333 in firewall
  - Verify you entered correct IP
  - Wait 30 seconds and check ./cli getconnectioncount

For help: Check the debug log at ~/.retardio/debug.log


TECHNICAL INFO:
===============
Network Ports:
  18333 - P2P (must be open in firewall)
  18332 - RPC (localhost only)
  3333  - Stratum mining pool

Configuration:
  ~/.retardio/retardio.conf

Data directory:
  ~/.retardio/

Mining address:
  Saved to ~/.retardio/mining_address.txt


SHARING WITH FRIENDS:
=====================
1. Send them this entire folder (zip it up)
2. They extract and run retardio_master_setup.sh
3. When asked for peer IP, they enter YOUR IP
4. Both nodes will connect automatically!


Happy mining! 🚀
EOF

# Create Windows launcher
echo "[3/5] Creating Windows launcher..."
cat > "${PACKAGE_DIR}/INSTALL_WINDOWS.bat" << 'EOFBAT'
@echo off
echo.
echo ================================================
echo   RETARDIO INSTALLER - Windows
echo ================================================
echo.
echo This will launch the Retardio installer using WSL.
echo.
echo Requirements:
echo   - Windows 10/11 with WSL installed
echo   - Ubuntu or Debian in WSL
echo.
pause
echo.
echo Checking for WSL...

wsl --version >nul 2>&1
if %errorlevel% neq 0 (
    echo.
    echo ERROR: WSL not found!
    echo.
    echo Please install WSL first:
    echo   1. Open PowerShell as Administrator
    echo   2. Run: wsl --install
    echo   3. Restart computer
    echo   4. Run this installer again
    echo.
    pause
    exit /b 1
)

echo WSL found!
echo.
echo Starting installer...
echo.

wsl bash -c "cd '%cd%' && chmod +x retardio_master_setup.sh && ./retardio_master_setup.sh"

echo.
echo.
echo Installation complete!
echo.
pause
EOFBAT

# Create version file
echo "[4/5] Creating version file..."
cat > "${PACKAGE_DIR}/VERSION" << EOF
Retardio All-in-One Installer
Version: ${VERSION}
Build Date: $(date)
Package Contents:
  - Retardio node source code patches
  - Master setup script
  - ckpool stratum server (auto-download)
  - Helper scripts
  - Documentation
EOF

# Create installation instructions
echo "[5/5] Creating installation guide..."
cat > "${PACKAGE_DIR}/INSTALLATION_GUIDE.md" << 'EOFMD'
# Retardio All-in-One Installation Guide

## Overview

This package contains everything needed to set up a complete Retardio mining node with stratum pool support.

## Package Contents

- `retardio_master_setup.sh` - Main installation script
- `chainparamsseeds.h` - Network configuration
- `README.txt` - Quick start guide
- `INSTALL_WINDOWS.bat` - Windows launcher
- This guide

## Installation Methods

### Method 1: Linux/macOS (Recommended)

1. Open terminal
2. Navigate to this directory
3. Run:
   ```bash
   chmod +x retardio_master_setup.sh
   ./retardio_master_setup.sh
   ```

### Method 2: Windows with WSL

**Option A: Using the Launcher**
1. Double-click `INSTALL_WINDOWS.bat`
2. Follow prompts

**Option B: Manual WSL**
1. Open WSL terminal
2. Navigate to package directory:
   ```bash
   cd /mnt/c/path/to/retardio_installer
   ```
3. Run:
   ```bash
   chmod +x retardio_master_setup.sh
   ./retardio_master_setup.sh
   ```

### Method 3: Windows (Native Build)

*Coming soon - currently use WSL method above*

## What the Installer Does

The master setup script automatically:

1. **Checks environment** - Verifies dependencies
2. **Installs dependencies** - Asks to install missing packages
3. **Builds Retardio node** - Compiles from source (5-15 min)
4. **Patches networking** - Clears Retardio seed nodes
5. **Patches mining RPC** - Enables solo mining without peers
6. **Configures node** - Creates secure config file
7. **Adds peer nodes** - Connects to your friends
8. **Opens firewall** - Configures ports 18333 and 3333
9. **Starts node** - Launches retardiod daemon
10. **Creates wallet** - Sets up mining wallet
11. **Generates address** - Creates and saves mining address
12. **Installs ckpool** - Downloads and builds stratum server
13. **Configures ckpool** - Sets up mining pool
14. **Creates shortcuts** - Helper scripts for easy use

## System Requirements

### Minimum
- 4GB RAM
- 10GB free disk space
- Ubuntu 20.04+ or Debian 10+ (or WSL equivalent)
- Internet connection

### Recommended
- 8GB RAM
- 20GB free SSD space
- Ubuntu 22.04 or later
- Stable internet connection

## Step-by-Step Installation

### Step 1: Extract Package

Extract this entire folder to a location on your computer:
- Linux/Mac: `~/retardio` or `/opt/retardio`
- Windows: `C:\retardio`

### Step 2: Run Installer

Follow the appropriate method above for your OS.

### Step 3: Answer Questions

The installer will ask:

**Q: Install missing dependencies?**
- Answer: `y` (yes)
- This installs build tools and libraries

**Q: Do you have a peer node IP to add?**
- Answer: `y` if you have a friend's IP
- Enter their IP address
- Or answer `n` to skip (can add later)

**Q: Open port 18333 in firewall?**
- Answer: `y` (required for networking)

**Q: Mine initial 100 blocks?**
- Answer: `y` for testing
- Or `n` if blockchain will sync from peers

**Q: Install ckpool stratum server?**
- Answer: `y` to enable mining pool
- Or `n` to skip mining pool setup

**Q: Start ckpool now?**
- Answer: `y` to start immediately
- Or `n` to start manually later

### Step 4: Wait for Build

The build process takes 5-15 minutes depending on your CPU.

Progress is shown in real-time.

### Step 5: Installation Complete!

When you see:
```
╔══════════════════════════════════════════════════════╗
║              🎉  ALL DONE! 🎉                        ║
╚══════════════════════════════════════════════════════╝
```

Your installation is complete!

## Post-Installation

### Check Node Status

```bash
./status.sh
```

Shows:
- Block height
- Connected peers
- Wallet balance
- Mining address

### Mine Blocks

```bash
./mine.sh 10
```

Mines 10 blocks to your address.

### Check Peers

```bash
./cli getconnectioncount
```

Should return > 0 if connected to peers.

### Start Mining Pool

If ckpool was installed:

```bash
cd ~/ckpool
./start_pool.sh
```

Miners can connect to: `stratum+tcp://YOUR_IP:3333`

## Networking Setup

### Port Forwarding (For Internet Peers)

If connecting over internet, forward these ports on your router:
- 18333 (TCP) - P2P networking
- 3333 (TCP) - Stratum mining (optional)

### Firewall Rules

The installer automatically configures firewall, but verify:

**Linux (UFW):**
```bash
sudo ufw status
```

Should show:
```
18333/tcp    ALLOW    Anywhere
3333/tcp     ALLOW    Anywhere
```

**Windows:**
- Check Windows Defender Firewall
- Inbound rules should allow ports 18333 and 3333

### Find Your IP Address

**Local Network:**
```bash
ip addr show | grep "inet "
```

**Public IP:**
```bash
curl ifconfig.me
```

Share this with peers so they can connect to you.

## Connecting Multiple Nodes

### Your Node Setup

1. Run installer
2. When asked for peer IP, enter friend's IP
3. Wait for connection

### Friend's Node Setup

1. Send them this installer package
2. They run installer
3. They enter YOUR IP when asked
4. Both nodes connect automatically!

### Verify Connection

Both nodes should show:
```bash
./cli getconnectioncount
# Returns: 1 (or higher)
```

### Test Block Sync

**On your node:**
```bash
./mine.sh 1
```

**On friend's node:**
```bash
./cli getblockcount
```

Block count should increase within seconds!

## Troubleshooting

### Build Fails

**Error: Missing dependencies**
- Answer `y` when asked to install dependencies
- Ensure internet connection is working

**Error: Out of disk space**
- Free up at least 10GB
- Delete unnecessary files

**Error: Permission denied**
- Run: `chmod +x retardio_master_setup.sh`
- Try with sudo if needed

### No Peers Connecting

**Check firewall:**
```bash
sudo ufw status
```

**Verify port is open:**
```bash
nc -zv FRIEND_IP 18333
```

**Check config:**
```bash
cat ~/.retardio/retardio.conf | grep addnode
```

Should show: `addnode=FRIEND_IP:18333`

**Add peers manually:**
Edit `~/.retardio/retardio.conf` and add:
```
addnode=192.168.1.100:18333
```

Then restart:
```bash
./cli stop
sleep 5
./build/bin/retardiod -datadir=~/.retardio
```

### Mining Pool Not Working

**Check ckpool is running:**
```bash
ps aux | grep ckpool
```

**Check ckpool logs:**
```bash
tail -f ~/ckpool/ckpool.log
```

**Restart ckpool:**
```bash
pkill ckpool
cd ~/ckpool
./start_pool.sh
```

### Can't Connect to Stratum

**Verify pool is listening:**
```bash
netstat -tlnp | grep 3333
```

Should show ckpool listening on port 3333.

**Test connection:**
```bash
telnet localhost 3333
```

Should connect successfully.

## Advanced Configuration

### Modify Node Config

Edit: `~/.retardio/retardio.conf`

Common changes:
```ini
maxconnections=200    # Allow more peers
dbcache=1000          # Increase cache for faster sync
```

Restart node after changes:
```bash
./cli stop && sleep 5 && ./build/bin/retardiod -datadir=~/.retardio
```

### Modify Pool Config

Edit: `~/ckpool/retardio.conf`

Change mining address:
```json
"btcaddress" : "YOUR_ADDRESS_HERE"
```

Restart ckpool after changes.

### Add DNS Seeds (Advanced)

Once you have stable nodes, you can add them as DNS seeds in the source code.

This is advanced - see Retardio documentation.

## Uninstallation

To remove Retardio:

```bash
# Stop node
./cli stop

# Stop pool
pkill ckpool

# Remove files
rm -rf ~/.retardio
rm -rf ~/ckpool
rm -rf ~/retardio_installer
```

## Getting Help

**Check logs:**
- Node: `~/.retardio/debug.log`
- ckpool: `~/ckpool/ckpool.log`

**Common issues:**
- Firewall blocking: Open port 18333
- Wrong IP: Verify with `ip addr show`
- Blockchain not syncing: Check peer connections

## What's Next?

After successful installation:

1. **Mine blocks** - Build up your blockchain
2. **Connect more nodes** - Grow your network
3. **Set up ESP32 miners** - Point them to port 3333
4. **Build block explorer** - Web UI for blockchain
5. **Create community** - Share with friends!

## Package Information

**Version:** See VERSION file
**Support:** Check README.txt
**License:** MIT (same as Retardio)

## Credits

- Based on Retardio Core / Retardio Knots
- ckpool by Con Kolivas
- Retardio customizations

---

**Happy mining!** 🚀
EOFMD

# Create archive
echo ""
echo "Package created at: ${PACKAGE_DIR}/"
echo ""
echo "Creating compressed archive..."

cd "$SCRIPT_DIR"
tar -czf "retardio_installer_v${VERSION}.tar.gz" -C "$PACKAGE_DIR" .

if [ -f "retardio_installer_v${VERSION}.tar.gz" ]; then
    echo ""
    echo "✓ Archive created: retardio_installer_v${VERSION}.tar.gz"
    echo ""
    echo "Package size: $(du -h retardio_installer_v${VERSION}.tar.gz | cut -f1)"
    echo ""
    echo "To distribute:"
    echo "  1. Share: retardio_installer_v${VERSION}.tar.gz"
    echo "  2. Users extract it"
    echo "  3. Users run: ./retardio_master_setup.sh"
    echo ""
    echo "Done!"
fi
