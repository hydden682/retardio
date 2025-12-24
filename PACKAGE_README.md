
# Creating the All-in-One Retardio Package

## Quick Method - Create Installer Package

### Step 1: Create the Package

Run the package creator script:

```bash
./create_installer.sh
```

This creates:
- `retardio_installer/` folder with all necessary files
- `retardio_installer_v1.0.0.tar.gz` compressed archive

### Step 2: Distribute

**Share the archive with anyone:**
```bash
# Copy to USB drive, email, etc.
cp retardio_installer_v1.0.0.tar.gz /path/to/share/
```

### Step 3: Users Extract and Run

**Recipients do:**

```bash
# Extract
tar -xzf retardio_installer_v1.0.0.tar.gz
cd retardio_installer/

# Run installer
chmod +x retardio_master_setup.sh
./retardio_master_setup.sh
```

**That's it!** Everything is set up automatically.

---

## What's Included in the Package

The installer package contains:

1. **retardio_master_setup.sh** - Main setup script that does everything
2. **chainparamsseeds.h** - Fixed network configuration
3. **README.txt** - Quick start guide
4. **INSTALL_WINDOWS.bat** - Windows launcher
5. **INSTALLATION_GUIDE.md** - Complete installation manual
6. **VERSION** - Package version info

---

## What the Installer Does Automatically

When users run `retardio_master_setup.sh`, it automatically:

### 1. Environment Setup
- ✅ Checks system requirements
- ✅ Installs missing dependencies (with permission)
- ✅ Verifies disk space

### 2. Build Process
- ✅ Builds Retardio node from source
- ✅ Patches network code (clears Bitcoin seeds)
- ✅ Patches mining RPC (enables solo mining)
- ✅ Compiles optimized binaries

### 3. Configuration
- ✅ Creates `.retardio` data directory
- ✅ Generates `retardio.conf` with secure random password
- ✅ Configures RPC, network ports, and performance settings
- ✅ Adds peer nodes (asks for IPs)

### 4. Network Setup
- ✅ Opens firewall ports (18333 for P2P, 3333 for stratum)
- ✅ Configures node to accept incoming connections
- ✅ Shows your IP addresses to share with peers

### 5. Node Startup
- ✅ Starts retardiod daemon
- ✅ Creates mining wallet
- ✅ Generates mining address
- ✅ Saves address to file

### 6. Blockchain Sync
- ✅ Waits for peer connections
- ✅ Starts blockchain sync
- ✅ Can mine initial blocks if needed

### 7. Stratum Pool (Optional)
- ✅ Downloads and builds ckpool
- ✅ Configures ckpool for Retardio
- ✅ Creates pool start script
- ✅ Optionally starts pool immediately

### 8. Helper Scripts
- ✅ Creates `./cli` shortcut for retardio-cli
- ✅ Creates `./mine.sh` for easy mining
- ✅ Creates `./status.sh` for quick status check

---

## Installation Flow

```
User downloads: retardio_installer_v1.0.0.tar.gz
        ↓
Extracts to: retardio_installer/
        ↓
Runs: ./retardio_master_setup.sh
        ↓
Answers a few questions:
  - "Install dependencies?" → Yes
  - "Add peer IP?" → Enter friend's IP
  - "Open firewall?" → Yes
  - "Mine initial blocks?" → Yes (for testing)
  - "Install ckpool?" → Yes (for mining pool)
  - "Start ckpool?" → Yes
        ↓
Waits 5-15 minutes for build
        ↓
Done! Everything is running:
  ✓ Node syncing on port 18333
  ✓ RPC on port 18332
  ✓ Stratum pool on port 3333
  ✓ Wallet created
  ✓ Mining address saved
```

---

## User Experience

### Before (Manual Setup)
```bash
# 1. Clone repo
git clone https://github.com/user/retardio-coin
cd retardio-coin

# 2. Fix chainparamsseeds.h
# ... edit file manually ...

# 3. Install dependencies
sudo apt-get install ... (20+ packages)

# 4. Build
mkdir build && cd build
cmake ..
make -j$(nproc)

# 5. Configure
mkdir ~/.retardio
cat > ~/.retardio/retardio.conf << EOF
# ... 50 lines of config ...
EOF

# 6. Patch mining.cpp
# ... manual patch ...

# 7. Rebuild
make -j$(nproc)

# 8. Start node
./retardiod -daemon

# 9. Create wallet
./retardio-cli createwallet mining

# 10. Get address
./retardio-cli getnewaddress

# 11. Install ckpool
git clone https://github.com/ckolivas/ckpool
cd ckpool
./autogen.sh
./configure
make

# 12. Configure ckpool
# ... create config file ...

# 13. Start ckpool
./ckpool -c config.conf

# Total time: 1-2 hours
# Complexity: HIGH
# Error prone: Very
```

### After (Automated Package)
```bash
# 1. Extract
tar -xzf retardio_installer_v1.0.0.tar.gz
cd retardio_installer/

# 2. Run
./retardio_master_setup.sh

# Answer 5 simple questions
# Wait 10 minutes

# Total time: 10 minutes
# Complexity: LOW
# Error prone: Minimal
```

---

## Distribution Methods

### Method 1: Direct Download
Upload `retardio_installer_v1.0.0.tar.gz` to:
- GitHub Releases
- Your website
- File sharing service

Users download and extract.

### Method 2: USB Drive
Copy archive to USB drive:
```bash
cp retardio_installer_v1.0.0.tar.gz /media/usb/
```

Share USB drive with friends.

### Method 3: Git Repository
Push installer to a repo:
```bash
git init retardio_installer
cd retardio_installer
# Add files
git add .
git commit -m "Retardio installer v1.0.0"
git remote add origin https://github.com/user/retardio-installer
git push -u origin main
```

Users clone and run:
```bash
git clone https://github.com/user/retardio-installer
cd retardio-installer
./retardio_master_setup.sh
```

### Method 4: One-Liner Install (Advanced)
Create a bootstrap script:
```bash
curl -fsSL https://your-site.com/install.sh | bash
```

---

## For Windows Users

### Create Windows Executable (Optional)

You can convert the batch file to an .exe for easier distribution:

**Option 1: Using bat2exe (Simple)**
1. Download bat2exe from: http://bat2exe.net/
2. Load `INSTALL_WINDOWS.bat`
3. Compile to .exe
4. Share the .exe file

**Option 2: Using IExpress (Built into Windows)**
1. Run `iexpress` from Windows Run dialog
2. Create self-extracting package
3. Include all installer files
4. Set `INSTALL_WINDOWS.bat` as run command
5. Compile to .exe

**Option 3: Using NSIS Installer**
Create a proper Windows installer with NSIS:
```nsis
; retardio-installer.nsi
OutFile "RetardioInstaller.exe"
InstallDir "$PROGRAMFILES\Retardio"

Section "Install"
  SetOutPath $INSTDIR
  File /r "retardio_installer\*.*"
  ExecWait "$INSTDIR\INSTALL_WINDOWS.bat"
SectionEnd
```

Compile with NSIS to create `RetardioInstaller.exe`.

### Windows Users Just Need:
1. Double-click `RetardioInstaller.exe`
2. Wait for installation
3. Done!

---

## Testing the Package

Before distributing, test on a clean system:

```bash
# 1. Create test environment (VM or container)
docker run -it ubuntu:22.04 /bin/bash

# 2. Copy installer
# (copy retardio_installer_v1.0.0.tar.gz into container)

# 3. Extract and run
tar -xzf retardio_installer_v1.0.0.tar.gz
cd retardio_installer/
./retardio_master_setup.sh

# 4. Verify:
#    - Build succeeds
#    - Node starts
#    - Wallet creates
#    - ckpool installs
#    - Helper scripts work
```

---

## Package Size

Approximate sizes:
- Uncompressed: ~5 MB (just scripts and configs)
- Compressed archive: ~2 MB
- After build: ~500 MB (includes binaries and blockchain)

**Downloads during installation:**
- ckpool source (~1 MB)
- Build dependencies (~100-500 MB depending on system)

---

## Updating the Package

To create a new version:

1. Update scripts as needed
2. Increment version in `create_installer.sh`:
   ```bash
   VERSION="1.1.0"
   ```
3. Run packager:
   ```bash
   ./create_installer.sh
   ```
4. Distribute new archive:
   ```
   retardio_installer_v1.1.0.tar.gz
   ```

---

## Customization

### Add Your Seed Nodes

Edit `retardio_master_setup.sh` and add default peers:

```bash
# Around line 250, add:
cat >> "$CONF_FILE" << EOF
# Default seed nodes
addnode=seed1.retardio.network:18333
addnode=seed2.retardio.network:18333
EOF
```

### Change Default Ports

Edit configuration section:
```bash
# Network
port=18333        # Change to your port
# ...
# Stratum
"proxy" : "127.0.0.1:3333",  # Change stratum port
```

### Pre-configure Pool Settings

Edit ckpool config section to set your defaults.

---

## Support Documentation

The package includes:
- `README.txt` - Quick start (250 lines)
- `INSTALLATION_GUIDE.md` - Complete guide (500+ lines)
- Built-in help in installer script

Users should have everything they need to install and run successfully.

---

## Summary

**Create package:**
```bash
./create_installer.sh
```

**Distribute:**
```bash
# Share this file:
retardio_installer_v1.0.0.tar.gz
```

**Users install:**
```bash
tar -xzf retardio_installer_v1.0.0.tar.gz
cd retardio_installer/
./retardio_master_setup.sh
```

**Result:**
- ✅ Full node running
- ✅ Blockchain syncing
- ✅ Wallet created
- ✅ Stratum pool ready
- ✅ Helper scripts available
- ✅ Ready to mine!

**One script. Ten minutes. Everything working.** 🚀
