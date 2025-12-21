# Retardio Peer Node Setup Instructions

**Give these instructions to your friend to set up a peer node.**

---

## Prerequisites

- Windows 10/11 with WSL (Windows Subsystem for Linux) installed
- At least 5GB free disk space
- Internet connection

## Step 1: Install WSL Ubuntu (if not already installed)

Open PowerShell as Administrator and run:
```powershell
wsl --install -d Ubuntu
```

Reboot if prompted. When Ubuntu starts, create a username and password.

## Step 2: Get the Retardio Source Code

Open Ubuntu terminal (search "Ubuntu" in Start menu) and run:

```bash
cd ~
git clone https://github.com/YOUR_USERNAME/retardio-coin.git
# OR if you're sending them files directly:
# They should extract retardio-coin folder to C:\Users\[their-username]\
```

## Step 3: Install Build Dependencies

```bash
sudo apt-get update
sudo apt-get install -y build-essential cmake pkg-config \
    libsqlite3-dev libboost-all-dev libevent-dev \
    libssl-dev libtool autotools-dev automake \
    bsdmainutils python3
```

Answer "Y" when prompted. This takes about 5 minutes.

## Step 4: Build Retardio

```bash
cd ~/retardio-coin  # or cd /mnt/c/Users/[their-username]/retardio-coin
mkdir -p build
cd build
cmake .. -DBUILD_GUI=OFF -DBUILD_TESTS=OFF
make -j$(nproc)
```

This will take 15-30 minutes. You should see:
```
[100%] Built target bitcoind
```

## Step 5: Create Configuration File

Create the Retardio data directory and config:

```bash
mkdir -p ~/.retardio
nano ~/.retardio/bitcoin.conf
```

Paste this configuration:
```
rpcport=18332
port=18333
rpcuser=retardiouser
rpcpassword=retardiopass123
server=1
rpcallowip=127.0.0.1
rpcbind=127.0.0.1

# Connect to the main node (REPLACE WITH YOUR_IP_ADDRESS)
addnode=YOUR_IP_ADDRESS:18333
```

**IMPORTANT**: Replace `YOUR_IP_ADDRESS` with your actual IP address (the friend needs to ask you for this).

Save and exit (Ctrl+X, then Y, then Enter).

## Step 6: Start the Node

```bash
cd ~/retardio-coin/build/bin
./bitcoind -datadir=~/.retardio -daemon
```

You should see:
```
Bitcoin Knots starting
```

## Step 7: Check Connection Status

Wait 30 seconds, then check:

```bash
./bitcoin-cli -datadir=~/.retardio getconnectioncount
```

Should show: `1` (connected to your node)

Check blockchain info:
```bash
./bitcoin-cli -datadir=~/.retardio getblockchaininfo
```

The node should start syncing blocks from your node!

## Step 8: Monitor Sync Progress

Check sync status:
```bash
./bitcoin-cli -datadir=~/.retardio getblockcount
```

This should match the block count on your node.

---

## Troubleshooting

### Connection count shows 0

1. Make sure your firewall allows port 18333:
   - Windows: Open "Windows Defender Firewall with Advanced Security"
   - Add Inbound Rule for port 18333 TCP
   - OR temporarily disable firewall to test

2. Make sure the IP address is correct:
   ```bash
   nano ~/.retardio/bitcoin.conf
   # Update the addnode line with the correct IP
   ```

3. Restart the node:
   ```bash
   ./bitcoin-cli -datadir=~/.retardio stop
   sleep 3
   ./bitcoind -datadir=~/.retardio -daemon
   ```

### Node won't start

Check debug log:
```bash
tail -50 ~/.retardio/debug.log
```

Look for errors and send them to your friend (the person who gave you these instructions).

---

## For You (Main Node Owner)

### Find Your IP Address

**Internal IP (for same network):**
```powershell
ipconfig
```
Look for "IPv4 Address" under your active network adapter (usually 192.168.x.x).

**External IP (for internet connection):**
Visit https://whatismyipaddress.com/

### Open Firewall Port 18333

**Windows Firewall:**
1. Open "Windows Defender Firewall with Advanced Security"
2. Click "Inbound Rules" → "New Rule"
3. Choose "Port" → Next
4. TCP, port 18333 → Next
5. Allow the connection → Next
6. Apply to all profiles → Next
7. Name: "Retardio P2P" → Finish

**Router Port Forwarding (if friend is on different network):**
1. Log into your router admin panel (usually 192.168.1.1 or 192.168.0.1)
2. Find "Port Forwarding" section
3. Forward external port 18333 → your computer's IP:18333
4. Save settings

### Verify Peer Connection

Once your friend's node starts:

```bash
wsl bash -c "cd /mnt/c/Users/15187/retardio-coin/build/bin && ./retardio-cli -datadir=/mnt/c/Users/15187/.retardio getpeerinfo"
```

Should show their node connected!

### Test ckpool After Peer Connects

Once you have 1+ peers:

```bash
wsl bash -c "cd /mnt/c/Users/15187/ckpool && src/ckpool -B -c retardio.conf"
```

Should now work! ckpool will start accepting mining connections on port 3333.

---

## Quick Reference Commands

**Start node:**
```bash
cd ~/retardio-coin/build/bin && ./bitcoind -datadir=~/.retardio -daemon
```

**Stop node:**
```bash
./bitcoin-cli -datadir=~/.retardio stop
```

**Check status:**
```bash
./bitcoin-cli -datadir=~/.retardio getblockchaininfo
```

**Check connections:**
```bash
./bitcoin-cli -datadir=~/.retardio getpeerinfo
```

**Check block count:**
```bash
./bitcoin-cli -datadir=~/.retardio getblockcount
```

---

**That's it! Your friend's node should now be peering with yours and syncing the Retardio blockchain!**
