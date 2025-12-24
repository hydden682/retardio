# Retardio Node Connection Guide

## Why Nodes Weren't Connecting

The issue was that [src/chainparamsseeds.h](src/chainparamsseeds.h) contained **hardcoded Bitcoin mainnet seed nodes**. When Retardio nodes started, they tried to connect to Bitcoin's network instead of each other!

### What Was Fixed

1. **Cleared Bitcoin seed nodes** - Removed all Bitcoin mainnet seed IPs from chainparamsseeds.h
2. **Created connection scripts** - Added helper scripts to easily connect nodes
3. **This guide** - Documentation on how to properly connect Retardio nodes

## How to Connect Nodes

Since Retardio is a new network with no DNS seeds or hardcoded seed nodes, you must **manually connect nodes** to each other.

### Prerequisites

1. **Both nodes must be running** with the same genesis block
2. **Firewall must allow** port 18333 (P2P port)
3. **Know the IP address** of the peer node you want to connect to

---

## Method 1: Using Configuration File (Permanent)

Edit your `retardio.conf` file (located at `~/.retardio/retardio.conf` or `%USERPROFILE%\.retardio\bitcoin.conf` on Windows):

### Option A: addnode (Recommended)

Add this line for each peer you want to connect to:

```ini
addnode=192.168.1.100:18333
addnode=10.0.0.50:18333
addnode=your-friend-ip:18333
```

This tells your node to connect to these peers on startup and maintain the connection.

### Option B: connect (Only Connect to Specific Nodes)

```ini
connect=192.168.1.100:18333
connect=10.0.0.50:18333
```

**Warning:** Using `connect=` makes your node ONLY connect to the specified nodes and ignore all other peers. Use `addnode=` unless you specifically want this behavior.

After editing the config, **restart your node**:

**Linux/Mac:**
```bash
./stop_node.sh
./start_node.sh
```

**Windows:**
```batch
stop_node.bat
start_node.bat
```

---

## Method 2: Using RPC Commands (Temporary)

Add nodes while the node is running (connection is lost on restart):

**Linux/Mac:**
```bash
./build/bin/retardio-cli -datadir=~/.retardio addnode "192.168.1.100:18333" "add"
```

**Windows (Command Prompt):**
```cmd
build\bin\retardio-cli.exe -datadir=%USERPROFILE%\.retardio addnode "192.168.1.100:18333" "add"
```

**Windows (WSL):**
```bash
wsl bash -c "cd /mnt/c/Users/15187/retardio-coin/build/bin && ./retardio-cli -datadir=/mnt/c/Users/15187/.retardio addnode '192.168.1.100:18333' 'add'"
```

---

## Method 3: Using Helper Scripts (Easiest)

We've created helper scripts to make this easier!

**Linux/Mac:**
```bash
chmod +x connect_nodes.sh
./connect_nodes.sh
```

**Windows:**
```batch
connect_nodes.bat
```

The script will guide you through:
- Adding peer nodes
- Viewing current connections
- Checking network info

---

## Verifying Connections

### Check Connection Count

**Linux/Mac:**
```bash
./build/bin/retardio-cli -datadir=~/.retardio getconnectioncount
```

**Windows (WSL):**
```bash
wsl bash -c "cd /mnt/c/Users/15187/retardio-coin/build/bin && ./retardio-cli -datadir=/mnt/c/Users/15187/.retardio getconnectioncount"
```

Expected output: A number > 0 (e.g., `2` means 2 peers connected)

### View Peer Details

**Linux/Mac:**
```bash
./build/bin/retardio-cli -datadir=~/.retardio getpeerinfo
```

**Windows (WSL):**
```bash
wsl bash -c "cd /mnt/c/Users/15187/retardio-coin/build/bin && ./retardio-cli -datadir=/mnt/c/Users/15187/.retardio getpeerinfo"
```

This shows detailed information about each connected peer including:
- IP address and port
- Connection direction (inbound/outbound)
- Version/subversion
- Ping time
- Bytes sent/received

### Check Network Info

```bash
./build/bin/retardio-cli -datadir=~/.retardio getnetworkinfo
```

Shows your node's network configuration and status.

---

## Firewall Configuration

Your firewall must allow **incoming connections on port 18333** for other nodes to connect to you.

### Linux (UFW)
```bash
sudo ufw allow 18333/tcp
```

### Linux (iptables)
```bash
sudo iptables -A INPUT -p tcp --dport 18333 -j ACCEPT
sudo iptables-save
```

### Windows Firewall
1. Open "Windows Defender Firewall with Advanced Security"
2. Click "Inbound Rules" → "New Rule"
3. Select "Port" → Next
4. TCP, Specific local ports: `18333` → Next
5. Allow the connection → Next
6. Apply to all profiles → Next
7. Name: "Retardio P2P" → Finish

### Router Port Forwarding (For Internet Connections)

If you want nodes across the internet to connect:
1. Log into your router
2. Forward port `18333` to your node's local IP
3. Use your public IP address when telling others to connect

Find your public IP: https://whatismyipaddress.com/

---

## Common Network Scenarios

### Scenario 1: Two Nodes on Same LAN

**Node A (192.168.1.100):**
```ini
# In retardio.conf
addnode=192.168.1.101:18333
```

**Node B (192.168.1.101):**
```ini
# In retardio.conf
addnode=192.168.1.100:18333
```

Both nodes will connect to each other automatically on startup.

### Scenario 2: Multiple Nodes on Different Networks

**Your Node:**
```ini
# In retardio.conf
addnode=friend1-public-ip:18333
addnode=friend2-public-ip:18333
addnode=vps-server-ip:18333
```

**Friends' Nodes:**
```ini
# In their retardio.conf
addnode=your-public-ip:18333
```

Make sure all nodes have port forwarding configured on their routers.

### Scenario 3: One Central "Seed" Node

Set up one stable node (e.g., VPS) that everyone connects to:

**Central Seed Node (Always Online):**
- No configuration needed, just run the node
- Make sure port 18333 is open
- Share your IP with everyone

**All Other Nodes:**
```ini
# In retardio.conf
addnode=central-seed-ip:18333
```

This creates a star topology where all nodes connect through the central seed.

---

## Troubleshooting

### Problem: Nodes won't connect

**Check 1: Firewall**
```bash
# Test if port is reachable from peer
telnet peer-ip 18333
```

**Check 2: Node is listening**
```bash
netstat -an | grep 18333
```
Should show: `0.0.0.0:18333` or `*:18333`

**Check 3: Correct network magic bytes**

Both nodes must have the same network magic bytes (0xfecabeef). Verify in [src/kernel/chainparams.cpp](src/kernel/chainparams.cpp):
```cpp
pchMessageStart[0] = 0xfe;
pchMessageStart[1] = 0xca;
pchMessageStart[2] = 0xbe;
pchMessageStart[3] = 0xef;
```

**Check 4: Same genesis block**

Both nodes must have the same genesis block hash. Check with:
```bash
./retardio-cli -datadir=~/.retardio getblockhash 0
```

If different, one node has a different genesis block configuration.

### Problem: Connection drops after a while

Add these to `retardio.conf` to maintain connections:
```ini
listen=1
maxconnections=125
timeout=5000
```

### Problem: "Connection refused"

- Node is not running on the peer
- Wrong IP address or port
- Firewall blocking the connection
- Node is still starting up (wait 30 seconds and retry)

### Problem: Shows 0 connections but addnode succeeded

Wait 10-30 seconds for the connection to establish, then check again:
```bash
./retardio-cli -datadir=~/.retardio getconnectioncount
```

If still 0, check the debug log:
```bash
tail -f ~/.retardio/debug.log
```

Look for connection errors or "Added connection to peer" messages.

---

## Building a Retardio Network

### Step-by-Step Network Setup

1. **Set up Node 1 (Your node)**
   ```bash
   ./start_node.sh
   ```

2. **Set up Node 2 (Friend's node)**
   - They build and start their node
   - They add your IP to their `retardio.conf`: `addnode=your-ip:18333`
   - They restart their node

3. **Verify connection**
   ```bash
   ./retardio-cli -datadir=~/.retardio getconnectioncount
   # Should show: 1
   ```

4. **Add Node 3**
   - Node 3 adds Node 1 and/or Node 2
   - Now you have a 3-node network!

5. **Test block propagation**
   ```bash
   # On Node 1, mine a block
   ./retardio-cli -datadir=~/.retardio generatetoaddress 1 YOUR_ADDRESS

   # On Node 2, check block count
   ./retardio-cli -datadir=~/.retardio getblockcount
   # Should increase by 1 within seconds!
   ```

### Network Topology Recommendations

**For 2-3 nodes:** Fully connected (each node connects to all others)

**For 4-10 nodes:** Star or partial mesh
- One central "seed" node
- All nodes connect to seed
- Some nodes also connect to each other

**For 10+ nodes:** Hierarchical
- Multiple seed nodes
- Regular nodes connect to 2-3 seeds
- Seeds connect to each other

---

## Adding Permanent Seed Nodes (Advanced)

Once you have stable nodes (VPS servers that are always online), you can hardcode them into the source code:

1. Get a list of stable node IPs
2. Run `contrib/seeds/generate-seeds.py` to convert them to BIP155 format
3. Add the output to [src/chainparamsseeds.h](src/chainparamsseeds.h)
4. Rebuild and redistribute

This makes new nodes automatically connect to your seed nodes without manual configuration.

---

## Quick Command Reference

**Add a peer:**
```bash
./retardio-cli -datadir=~/.retardio addnode "IP:18333" "add"
```

**Remove a peer:**
```bash
./retardio-cli -datadir=~/.retardio addnode "IP:18333" "remove"
```

**List all added nodes:**
```bash
./retardio-cli -datadir=~/.retardio getaddednodeinfo
```

**Check connections:**
```bash
./retardio-cli -datadir=~/.retardio getconnectioncount
./retardio-cli -datadir=~/.retardio getpeerinfo
```

**Check if node is accepting connections:**
```bash
./retardio-cli -datadir=~/.retardio getnetworkinfo | grep "localaddresses"
```

---

## Next Steps

After successfully connecting nodes:

1. ✅ **Test block propagation** - Mine blocks on one node, verify they appear on others
2. ✅ **Test transactions** - Send coins between nodes
3. ✅ **Set up mining pool** - Now that nodes can communicate, set up ckpool
4. ✅ **Add more nodes** - Grow your network
5. ✅ **Monitor connections** - Use `getpeerinfo` regularly to ensure network health

---

## Need Help?

If you're still having trouble connecting nodes:

1. Check the debug log: `~/.retardio/debug.log`
2. Make sure both nodes are on the **same network** (mainnet, not testnet)
3. Verify both nodes have been **rebuilt** after clearing chainparamsseeds.h
4. Check that **port 18333** is accessible from the peer
5. Ensure both nodes have the **same genesis block**

**Success looks like this:**
```bash
$ ./retardio-cli -datadir=~/.retardio getconnectioncount
2

$ ./retardio-cli -datadir=~/.retardio getpeerinfo
[
  {
    "addr": "192.168.1.100:18333",
    "services": "0000000000000409",
    "lastsend": 1734567890,
    "lastrecv": 1734567891,
    "conntime": 1734567800,
    "version": 70016,
    "subver": "/Satoshi:29.0.0/",
    ...
  }
]
```

Good luck building your Retardio network! 🚀
