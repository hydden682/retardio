# 🚀 ONE COMMAND SETUP - Retardio Complete Package

## The Absolute Easiest Way

I've created an **all-in-one script** that sets up EVERYTHING automatically:
- ✅ Rebuilds the node
- ✅ Fixes networking
- ✅ Patches mining RPC
- ✅ Configures everything
- ✅ Connects to peers
- ✅ Syncs blockchain
- ✅ Installs stratum pool
- ✅ Creates helper scripts

---

## Just Run This ONE Command:

### Linux/Mac/WSL:
```bash
./retardio_master_setup.sh
```

### Windows (Double-Click):
```
(Coming soon: RetardioInstaller.exe)
```

---

## What You'll Be Asked

The script asks **5 simple questions**:

1. **"Install missing dependencies?"**
   - Answer: `y`

2. **"Do you have a peer IP to add?"**
   - Answer: `y` and enter your friend's IP
   - Or `n` to skip

3. **"Open port 18333 in firewall?"**
   - Answer: `y`

4. **"Mine initial 100 blocks for testing?"**
   - Answer: `y` for testing
   - Or `n` if syncing from peers

5. **"Install ckpool stratum server?"**
   - Answer: `y` for mining pool
   - Or `n` to skip

**That's it!** Then wait 10-15 minutes while it builds.

---

## After Installation

You'll have these quick commands:

```bash
./cli getblockchaininfo   # Check node
./status.sh               # Full status
./mine.sh 10              # Mine 10 blocks
```

And:
- ✅ Node running on port 18333
- ✅ RPC on port 18332
- ✅ Stratum pool on port 3333 (if installed)
- ✅ Wallet with mining address
- ✅ Everything configured and ready!

---

## Creating a Package to Share

Want to share this with friends? Create a distributable package:

### Step 1: Create Package
```bash
./create_installer.sh
```

This creates:
- `retardio_installer_v1.0.0.tar.gz` - Complete installer package

### Step 2: Share Package

Send the `.tar.gz` file to anyone via:
- Email
- USB drive
- Cloud storage
- GitHub release

### Step 3: They Extract and Run

```bash
tar -xzf retardio_installer_v1.0.0.tar.gz
cd retardio_installer/
./retardio_master_setup.sh
```

**Done!** They have a complete setup in 10 minutes.

---

## Creating a Windows Executable (Optional)

For Windows users who don't have WSL, you can create an `.exe`:

### Method 1: Using bat2exe (Simplest)

1. Download bat2exe: http://bat2exe.net/
2. Create the package: `./create_installer.sh`
3. Open `retardio_installer/INSTALL_WINDOWS.bat` in bat2exe
4. Compile to `RetardioInstaller.exe`
5. Share the `.exe` file

Users double-click `RetardioInstaller.exe` and everything installs automatically!

### Method 2: Using IExpress (Built into Windows)

1. Create package: `./create_installer.sh`
2. Run `iexpress` from Windows search
3. Choose "Create new Self Extraction Directive file"
4. Select "Extract files and run installation command"
5. Add all files from `retardio_installer/`
6. Set run command: `INSTALL_WINDOWS.bat`
7. Save as `RetardioInstaller.exe`

### Method 3: Professional Installer (NSIS)

For a professional-looking Windows installer:

1. Install NSIS: https://nsis.sourceforge.io/
2. Create this script (`retardio.nsi`):

```nsis
!include "MUI2.nsh"

Name "Retardio Node Installer"
OutFile "RetardioInstaller.exe"
InstallDir "$PROGRAMFILES\Retardio"

!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH

!insertmacro MUI_LANGUAGE "English"

Section "Install"
  SetOutPath $INSTDIR
  File /r "retardio_installer\*.*"

  DetailPrint "Running Retardio setup..."
  ExecWait '"wsl" bash -c "cd $INSTDIR && ./retardio_master_setup.sh"'

  WriteUninstaller "$INSTDIR\Uninstall.exe"

  CreateShortcut "$DESKTOP\Retardio.lnk" "$INSTDIR\INSTALL_WINDOWS.bat"
SectionEnd

Section "Uninstall"
  Delete "$INSTDIR\*.*"
  RMDir /r "$INSTDIR"
  Delete "$DESKTOP\Retardio.lnk"
SectionEnd
```

3. Compile: Right-click `retardio.nsi` → "Compile NSIS Script"
4. Share `RetardioInstaller.exe`

---

## Comparison: Before vs After

### Before (Manual - 2 Hours)
```bash
# Fix chainparamsseeds.h
# Install 20+ dependencies
# Build node (configure, make)
# Patch mining.cpp manually
# Rebuild node
# Create config file (50 lines)
# Configure firewall
# Start node
# Create wallet
# Get address
# Clone ckpool
# Build ckpool
# Configure ckpool
# Start ckpool
# Create helper scripts
# ... 30+ commands total
```

### After (Automated - 10 Minutes)
```bash
./retardio_master_setup.sh
# Answer 5 questions
# Wait 10 minutes
# Done!
```

---

## What Gets Installed

### System Components
- Retardio node (retardiod)
- Retardio CLI (retardio-cli)
- ckpool stratum server (optional)

### Configuration Files
- `~/.retardio/retardio.conf` - Node config
- `~/.retardio/mining_address.txt` - Your mining address
- `~/ckpool/retardio.conf` - Pool config (if installed)

### Helper Scripts
- `./cli` - Quick access to retardio-cli
- `./mine.sh [blocks]` - Mine blocks easily
- `./status.sh` - Show full node status

### Data Directories
- `~/.retardio/` - Blockchain data
- `~/ckpool/` - Pool data (if installed)

---

## Network Setup

### Ports Used
- **18333** - P2P networking (must be open)
- **18332** - RPC (localhost only)
- **3333** - Stratum mining (must be open if using pool)

### Firewall Configuration
The script automatically configures your firewall, but verify:

```bash
# Linux
sudo ufw status

# Should show:
18333/tcp    ALLOW
3333/tcp     ALLOW
```

### Connecting Peers

To connect with friends:

**You run:**
```bash
./retardio_master_setup.sh
# When asked for peer IP, enter friend's IP
```

**Friend runs:**
```bash
./retardio_master_setup.sh
# When asked for peer IP, they enter YOUR IP
```

**Both nodes connect automatically!**

Verify with:
```bash
./cli getconnectioncount
# Should return: 1 or higher
```

---

## Mining Setup

### Solo Mining (Built-in)
```bash
./mine.sh 10  # Mine 10 blocks
```

Blocks go directly to your mining address.

### Pool Mining (With ckpool)

If you installed ckpool:

**Start pool:**
```bash
cd ~/ckpool
./start_pool.sh
```

**Connect miners:**
Point your ESP32/ASIC miners to:
```
stratum+tcp://YOUR_IP:3333
```

**Check pool status:**
```bash
tail -f ~/ckpool/ckpool.log
```

---

## Sharing Your Setup

### Option 1: Share the Installer Package

1. Create package:
   ```bash
   ./create_installer.sh
   ```

2. Share this file:
   ```
   retardio_installer_v1.0.0.tar.gz
   ```

3. Recipients extract and run:
   ```bash
   tar -xzf retardio_installer_v1.0.0.tar.gz
   cd retardio_installer/
   ./retardio_master_setup.sh
   ```

### Option 2: Share Just the Master Script

Send them:
- `retardio_master_setup.sh`
- `src/chainparamsseeds.h`

They put chainparamsseeds.h in their `src/` folder and run the script.

### Option 3: Share Windows Executable

Create `RetardioInstaller.exe` (see above) and share it.

Windows users just double-click and everything installs!

---

## Troubleshooting

### Build Fails
- Make sure you have internet connection
- Let script install dependencies (answer `y`)
- Ensure 10GB+ free disk space

### No Peers Connecting
- Verify firewall port 18333 is open
- Check you entered correct IP address
- Wait 30 seconds and try: `./cli getconnectioncount`

### Pool Won't Start
- Check ckpool logs: `tail -f ~/ckpool/ckpool.log`
- Verify node is running: `./cli getblockchaininfo`
- Restart pool: `cd ~/ckpool && ./start_pool.sh`

---

## Complete Workflow Example

### Your Setup
```bash
# Step 1: Run installer
./retardio_master_setup.sh

# Answer questions:
Install dependencies? y
Peer IP to add? 192.168.1.100
Open firewall? y
Mine initial blocks? y
Install ckpool? y
Start ckpool? y

# Wait 10 minutes...

# Step 2: Verify
./status.sh

# Output:
=== Retardio Node Status ===
Blockchain Info:
  "chain": "main",
  "blocks": 100,
  "difficulty": 1.0,
Network:
  Peers: 1
Wallet:
  Balance: 239726.00 RET
Mining Address:
  F7j1mx5CQz5YMhybN9TSav1hjcNRoUQGWU

# Done! ✓
```

### Friend's Setup
```bash
# Step 1: Extract your shared package
tar -xzf retardio_installer_v1.0.0.tar.gz
cd retardio_installer/

# Step 2: Run installer
./retardio_master_setup.sh

# Answer questions:
Peer IP to add? 192.168.1.50  # Your IP
Install ckpool? n  # They don't need pool

# Wait 10 minutes...

# Step 3: Verify connection
./cli getconnectioncount
# Output: 1

# Step 4: Verify sync
./cli getblockcount
# Output: 100 (same as your node)

# Done! ✓
```

---

## Summary

### To Set Up Your Node:
```bash
./retardio_master_setup.sh
```

### To Create Distributable Package:
```bash
./create_installer.sh
```

### To Share With Friends:
Send them:
```
retardio_installer_v1.0.0.tar.gz
```

Or create Windows .exe:
```
RetardioInstaller.exe
```

### Result:
- ✅ **One script** does everything
- ✅ **10 minutes** total setup time
- ✅ **No technical knowledge** needed
- ✅ **Complete node** with mining pool
- ✅ **Easy to share** with friends
- ✅ **Windows support** via executable

---

## Files Created

| File | Purpose |
|------|---------|
| [retardio_master_setup.sh](retardio_master_setup.sh) | **Main installer - Run this!** |
| [create_installer.sh](create_installer.sh) | Creates distributable package |
| [PACKAGE_README.md](PACKAGE_README.md) | Packaging instructions |
| [ONE_COMMAND_SETUP.md](ONE_COMMAND_SETUP.md) | This guide |

---

**The easiest Retardio setup possible. One command. Ten minutes. Everything working.** 🚀
