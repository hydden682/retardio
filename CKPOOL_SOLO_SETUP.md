# ckpool Solo Mining Setup for Retardio

## What is ckpool?

**ckpool** is the gold standard for solo mining pools:
- ✅ **True solo mining** - Block finder gets 100% of reward (2397.26 RET)
- ✅ **Extremely efficient** - Handles massive hashrates with minimal resources
- ✅ **Battle-tested** - Powers major solo mining pools
- ✅ **No database** - No Redis, no MySQL, just pure stratum
- ✅ **Written in C** - Fast and lightweight

**Author:** Con Kolivas (creator of cgminer, bfgminer)

---

## Installation

### Linux/Mac

```bash
# Install dependencies
sudo apt-get install build-essential yasm libssl-dev libzmq3-dev libevent-dev libpq-dev

# Clone ckpool
git clone https://bitbucket.org/ckolivas/ckpool.git
cd ckpool

# Build
./autogen.sh
./configure
make

# Install (optional)
sudo make install
```

### Result

You'll have these binaries:
- **ckpool** - The main pool server
- **ckpmsg** - Pool messaging tool
- **notifier** - Block notification tool

---

## Configuration

### Create ckpool.conf

```json
{
    "ckpool": {
        "btcd": [
            {
                "url": "127.0.0.1:18332",
                "auth": "retardiouser",
                "pass": "YOUR_RPC_PASSWORD",
                "notify": true,
                "timeout": 60
            }
        ],
        "btcaddress": "YOUR_FALLBACK_ADDRESS",
        "btcsig": "/Retardio Solo/",
        "blockpoll": 100,
        "nonce1length": 4,
        "nonce2length": 8,
        "update_interval": 30,
        "version_mask": "1fffe000",
        "serverurl": [
            "0.0.0.0:3032"
        ],
        "mindiff": 1,
        "startdiff": 8,
        "logdir": "logs",
        "maxclients": 65536,
        "gratuitous": false
    }
}
```

### Configuration Breakdown

**btcd section:**
- `url` - Retardio RPC endpoint (IP:PORT)
- `auth` - RPC username
- `pass` - RPC password
- `notify` - Enable block template notifications
- `timeout` - RPC timeout in seconds

**Pool settings:**
- `btcaddress` - Fallback address if miner doesn't provide one
- `btcsig` - Pool signature in coinbase (shows in blocks)
- `blockpoll` - Poll for new blocks every 100ms
- `update_interval` - Push new work every 30 seconds

**Stratum settings:**
- `serverurl` - IP:PORT to listen on (0.0.0.0 = all interfaces)
- `mindiff` - Minimum difficulty (1 for ESP32s)
- `startdiff` - Starting difficulty for all miners
- `nonce1length` - Extranonce1 size (4 bytes)
- `nonce2length` - Extranonce2 size (8 bytes)

**Advanced:**
- `logdir` - Where to store logs
- `maxclients` - Maximum concurrent miners
- `gratuitous` - Send share accepted messages (false = less bandwidth)

---

## ESP32-Friendly Configuration

For ESP32 miners and small hashrates:

```json
{
    "ckpool": {
        "btcd": [
            {
                "url": "127.0.0.1:18332",
                "auth": "retardiouser",
                "pass": "YOUR_RPC_PASSWORD",
                "notify": true
            }
        ],
        "btcaddress": "FaDf8jKmN3pQrS9tV2wX4yZ5bC6dE7fG8h",
        "btcsig": "/Retardio Solo - ESP32 Friendly/",
        "blockpoll": 100,
        "update_interval": 30,
        "serverurl": [
            "0.0.0.0:3032"
        ],
        "mindiff": 0.5,
        "startdiff": 1,
        "logdir": "logs",
        "maxclients": 10000
    }
}
```

**Key differences:**
- `mindiff`: 0.5 (super low for ESP32s)
- `startdiff`: 1 (everyone starts at diff 1)
- No maxdiff limit (ckpool handles this automatically)

---

## Start ckpool

### Foreground (Testing)

```bash
./ckpool -c ckpool.conf
```

Output:
```
[2024-12-18 12:00:00] ckpool generator ready
[2024-12-18 12:00:00] ckpool stratifier ready
[2024-12-18 12:00:00] ckpool connector ready
[2024-12-18 12:00:00] ckpool listener ready on socket 0.0.0.0:3032
```

### Daemon Mode (Production)

```bash
./ckpool -c ckpool.conf -d
```

### Systemd Service (Auto-start)

Create `/etc/systemd/system/ckpool.service`:

```ini
[Unit]
Description=ckpool Retardio Solo Mining Pool
After=network.target

[Service]
Type=forking
User=retardio
WorkingDirectory=/home/retardio/ckpool
ExecStart=/home/retardio/ckpool/ckpool -c /home/retardio/ckpool/ckpool.conf -d
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

Enable and start:
```bash
sudo systemctl daemon-reload
sudo systemctl enable ckpool
sudo systemctl start ckpool
sudo systemctl status ckpool
```

---

## How Miners Connect

### Connection String

```bash
# Miner's address goes in username field
cpuminer -a sha256d \
    -o stratum+tcp://YOUR_POOL_IP:3032 \
    -u YOUR_RETARDIO_ADDRESS \
    -p x
```

**CRITICAL:** The `-u` (username) is the miner's payout address!

### How ckpool Handles Rewards

```
Miner connects → Username = FaDf8jKmN3pQrS9tV2wX4yZ5bC6dE7fG8h
      ↓
Miner finds block
      ↓
ckpool builds coinbase transaction:
  Output: 2397.26 RET → FaDf8jKmN3pQrS9tV2wX4yZ5bC6dE7fG8h
      ↓
ckpool submits block to Retardio node
      ↓
Block accepted → Miner gets 100% reward!
```

### If Miner Doesn't Provide Address

Uses `btcaddress` from config as fallback (pool operator's address).

---

## Monitoring

### View Logs

```bash
tail -f logs/ckpool.log
```

### Check Connected Miners

```bash
# Use ckpmsg to query pool stats
./ckpmsg stats | jq
```

Example output:
```json
{
  "runtime": 3600,
  "workers": 5,
  "users": 3,
  "hashrate1m": "150000000",
  "hashrate5m": "145000000",
  "hashrate15m": "148000000",
  "diff": 8,
  "accepted": 1500,
  "rejected": 5,
  "lns": 1200000000
}
```

### Real-time Monitoring

```bash
watch -n 1 './ckpmsg stats | jq ".workers, .hashrate1m"'
```

---

## Advanced Features

### Multiple Ports (Optional)

ckpool can run multiple ports with different starting difficulties:

**Not needed** - ckpool's VarDiff is excellent. But if you want:

Start multiple instances:
```bash
# Port 3032 - Low diff
./ckpool -c ckpool-low.conf -d -n ckpool-low

# Port 3256 - High diff
./ckpool -c ckpool-high.conf -d -n ckpool-high
```

### Proxy Mode

ckpool can proxy to another pool (for load balancing):

```json
"proxy": "stratum+tcp://backup.pool.com:3333"
```

### Custom Difficulty Per Worker

Miners can request difficulty:

```bash
cpuminer -a sha256d \
    -o stratum+tcp://pool:3032 \
    -u YOUR_ADDRESS+d=16 \
    -p x
```

`+d=16` requests difficulty 16.

---

## Security

### Firewall Rules

```bash
# Allow stratum port
sudo ufw allow 3032/tcp

# Block RPC port from internet
sudo ufw deny 18332/tcp

# Allow RPC only from localhost (already default in retardio.conf)
```

### DDoS Protection

ckpool has built-in protection:
- Connection rate limiting
- Invalid share banning
- Flood detection

### SSL/TLS (Optional)

For encrypted connections:

```json
"serverurl": [
    "0.0.0.0:3032",
    "0.0.0.0:3333:cert=/path/to/cert.pem:key=/path/to/key.pem"
]
```

Miners connect:
```bash
cpuminer -a sha256d \
    -o stratum+ssl://pool:3333 \
    -u YOUR_ADDRESS \
    -p x
```

---

## Troubleshooting

### ckpool Won't Start

**Check config syntax:**
```bash
./ckpool -c ckpool.conf -t
```

**Check RPC connection:**
```bash
curl --user retardiouser:password \
  --data-binary '{"method":"getblocktemplate","params":[{"rules":["segwit"]}]}' \
  http://127.0.0.1:18332/
```

### Miners Can't Connect

**Check ckpool is listening:**
```bash
netstat -tuln | grep 3032
```

**Check firewall:**
```bash
sudo ufw status
```

**Check logs:**
```bash
tail -50 logs/ckpool.log
```

### Shares Not Accepted

**Common causes:**
- Incorrect algorithm (`-a sha256d` required)
- Wrong difficulty (too high for miner)
- Stale work (network issues)

**Check ckpool logs** for rejected share reasons.

### Block Found But Not Rewarded

**Verify:**
1. Miner used correct address as username
2. Block was accepted by network
3. Check block explorer (or `retardio-cli getblock`)
4. Rewards require 100 confirmations

---

## Comparison: ckpool vs NOMP

| Feature | ckpool | NOMP |
|---------|--------|------|
| **Solo mining** | ✅ Native | ⚠️ Requires hacks |
| **Pool mining** | ❌ Not designed for it | ✅ Native |
| **Language** | C | Node.js |
| **Database** | None | Redis required |
| **Performance** | Excellent | Good |
| **Resource usage** | Minimal | Moderate |
| **Setup** | Simple | Complex |
| **Web UI** | None | Available |
| **Best for** | Solo pools | Team pools |

---

## Integration with DigiShield

With our new DigiShield per-block difficulty:

### Benefits for ckpool:

✅ **Rapid difficulty adjustment** - Pool always has optimal difficulty
✅ **Anti-ASIC jumping** - Large miners can't game the system
✅ **ESP32 friendly** - Difficulty drops quickly when big miners leave
✅ **Fair competition** - Everyone has a chance to find blocks

### Effect on Pool:

```
ASIC connects → Mines at low diff for 2 blocks
   ↓
DigiShield detects fast blocks
   ↓
Difficulty increases after block 3
   ↓
ASIC sees difficulty is rising quickly
   ↓
ASIC leaves (not worth it)
   ↓
Difficulty drops again after 15 blocks
   ↓
ESP32s can mine comfortably again
```

---

## Quick Start Script

Save as `start_retardio_solo_pool.sh`:

```bash
#!/bin/bash

# 1. Make sure Retardio node is running
if ! pgrep -x "retardiod" > /dev/null; then
    echo "Starting Retardio node..."
    cd /path/to/retardio-coin
    ./src/retardiod -datadir=~/.retardio -daemon
    sleep 5
fi

# 2. Start ckpool
echo "Starting ckpool solo mining pool..."
cd /path/to/ckpool
./ckpool -c ckpool.conf -d

echo "Pool started on port 3032"
echo ""
echo "Miners can connect:"
echo "  cpuminer -a sha256d -o stratum+tcp://$(hostname -I | awk '{print $1}'):3032 -u YOUR_ADDRESS -p x"
```

Make executable:
```bash
chmod +x start_retardio_solo_pool.sh
./start_retardio_solo_pool.sh
```

---

## Summary

### ckpool for Retardio Solo Mining:

✅ **True solo** - Block finder gets 2397.26 RET (100%)
✅ **ESP32 friendly** - Supports diff as low as 0.5
✅ **No pool fees** - Optional, configurable
✅ **Lightning fast** - C implementation
✅ **Easy setup** - Single config file
✅ **Perfect partner for DigiShield** - Handles rapid difficulty changes

### Setup Time:

- **Install:** 5 minutes
- **Configure:** 2 minutes
- **Total:** 7 minutes to live solo pool!

---

**Ready to mine? Fire up ckpool and let those ESP32s compete fairly!** 🚀
