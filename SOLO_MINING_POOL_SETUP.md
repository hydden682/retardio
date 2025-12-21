# Solo Mining Pool Setup for Retardio

## What is Solo Mining Pool?

A solo mining pool is a stratum proxy that:
- ✅ Allows miners to connect via stratum protocol
- ✅ Block finder gets **100% of the reward** (2397.26 RET)
- ✅ No proportional payouts
- ✅ No share tracking/accounting
- ✅ Pool just validates shares and submits winning blocks

**Perfect for:** Private pools, testing, or when you want "lottery style" mining

---

## Option 1: ckpool (Recommended for Solo)

**ckpool** is the gold standard for solo mining pools.

### Features:
- ✅ True solo mining (block finder gets all)
- ✅ Extremely efficient (handles massive hashrate)
- ✅ Battle-tested (used by major solo pools)
- ✅ Simple configuration
- ✅ No database required

### Installation

```bash
# Install dependencies
sudo apt-get install build-essential libssl-dev

# Clone ckpool
git clone https://bitbucket.org/ckolivas/ckpool.git
cd ckpool

# Build
./configure
make

# Install
sudo make install
```

### Configuration

Create `ckpool.conf`:

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
        "btcaddress": "YOUR_RETARDIO_ADDRESS_HERE",
        "btcsig": "/Retardio Solo/",
        "blockpoll": 100,
        "update_interval": 30,
        "serverurl": [
            "0.0.0.0:3032"
        ],
        "mindiff": 1,
        "startdiff": 8,
        "logdir": "logs"
    }
}
```

**Key settings:**
- `btcaddress`: Your address - block rewards go HERE
- `btcsig`: Pool signature in blocks
- `serverurl`: Stratum port (3032)
- `mindiff`: Minimum difficulty (1)
- `startdiff`: Starting difficulty (8)

### Start ckpool

```bash
# Start in foreground (testing)
ckpool -c ckpool.conf

# Start as daemon (production)
ckpool -c ckpool.conf -d
```

### Miners Connect

```bash
cpuminer -a sha256d \
    -o stratum+tcp://YOUR_POOL_IP:3032 \
    -u YOUR_RETARDIO_ADDRESS \
    -p x
```

**Important:** Use YOUR address as the username. When you find a block, the reward goes to that address!

---

## Option 2: solo-stratum (Simple Node.js)

A lightweight solo mining proxy built on node-stratum-pool.

### Installation

```bash
# Clone (we'll use a generic stratum pool and configure for solo)
git clone https://github.com/zone117x/node-stratum-pool.git
cd node-stratum-pool
npm install
```

### Configuration

Create `config.json`:

```json
{
    "enabled": true,
    "coin": {
        "name": "Retardio",
        "symbol": "RET",
        "algorithm": "sha256"
    },
    "address": "FALLBACK_ADDRESS_IF_MINER_DOESNT_PROVIDE",
    "rewardRecipients": {},
    "paymentProcessing": {
        "enabled": false
    },
    "ports": {
        "3032": {
            "diff": 8,
            "varDiff": {
                "minDiff": 1,
                "maxDiff": 16384,
                "targetTime": 15,
                "retargetTime": 90,
                "variancePercent": 30
            }
        }
    },
    "daemons": [
        {
            "host": "127.0.0.1",
            "port": 18332,
            "user": "retardiouser",
            "password": "YOUR_RPC_PASSWORD"
        }
    ],
    "p2p": {
        "enabled": false
    },
    "connectionTimeout": 600
}
```

---

## Option 3: Public-Pool (Full-Featured Solo)

**public-pool** is a modern solo mining pool with web interface.

### Installation

```bash
git clone https://github.com/benjamincburns/node-open-mining-portal.git public-pool
cd public-pool
npm install
```

### Configure for Solo

Similar to NOMP but with solo-specific settings. Configuration would be more involved.

---

## Option 4: Direct Node Mining (Simplest)

If you just want solo mining without stratum, use the built-in miner:

```bash
# Start node
./src/retardiod -datadir=~/.retardio

# Mine to your address
./src/retardio-cli -datadir=~/.retardio generatetoaddress 1 YOUR_ADDRESS
```

**Pros:**
- ✅ No pool software needed
- ✅ 100% of rewards
- ✅ Zero complexity

**Cons:**
- ✗ No stratum (can't use external miners like cgminer)
- ✗ No VarDiff
- ✗ CPU only (no GPU/ASIC support)

---

## Comparison

| Solution | Difficulty | Stratum | Web UI | Best For |
|----------|-----------|---------|---------|----------|
| **ckpool** | Medium | ✅ | ✗ | Production solo pool |
| **node-stratum-pool** | Medium | ✅ | ✗ | Lightweight solo |
| **Public-pool** | Hard | ✅ | ✅ | Feature-rich solo |
| **Direct node mining** | Easy | ✗ | ✗ | Quick testing |

---

## Recommended Setup: ckpool

For a production solo mining pool, I recommend **ckpool**:

### Quick Start

```bash
# 1. Install ckpool
git clone https://bitbucket.org/ckolivas/ckpool.git
cd ckpool
./configure && make && sudo make install

# 2. Create config
cat > ckpool.conf << 'EOF'
{
    "ckpool": {
        "btcd": [
            {
                "url": "127.0.0.1:18332",
                "auth": "retardiouser",
                "pass": "your_rpc_password",
                "notify": true
            }
        ],
        "btcaddress": "YOUR_F_ADDRESS_HERE",
        "btcsig": "/Retardio Solo/",
        "blockpoll": 100,
        "update_interval": 30,
        "serverurl": ["0.0.0.0:3032"],
        "mindiff": 1,
        "startdiff": 8,
        "logdir": "logs"
    }
}
EOF

# 3. Start pool
ckpool -c ckpool.conf

# 4. Miners connect
# cpuminer -a sha256d -o stratum+tcp://YOUR_IP:3032 -u YOUR_ADDRESS -p x
```

### How It Works

```
┌─────────────┐
│   Miner     │ Connects via stratum
│  (cgminer)  │ Username = their Retardio address
└──────┬──────┘
       │ stratum+tcp://pool:3032
       ▼
┌─────────────────────────┐
│   ckpool (Solo Pool)    │
│                         │
│ 1. Receives shares      │
│ 2. Validates difficulty │
│ 3. If share is block:   │
│    - Build coinbase TX  │
│      with MINER's addr  │
│    - Submit block       │
│ 4. Miner gets 2397 RET! │
└──────┬──────────────────┘
       │ RPC (getblocktemplate, submitblock)
       ▼
┌─────────────────────────┐
│   Retardio Node         │
│   (retardiod)           │
│                         │
│ Block reward goes to    │
│ miner's address         │
│ (from coinbase TX)      │
└─────────────────────────┘
```

---

## NOMP for Solo? (Not Recommended)

NOMP can theoretically work for solo by:
1. Disabling payment processing
2. Setting miner's address in coinbase
3. Hacking the code to use miner's username as coinbase address

**But it's messy.** Use ckpool instead.

---

## Port Configuration for Solo Pool

### For ckpool:

You can configure multiple ports in `serverurl`:

```json
"serverurl": [
    "0.0.0.0:3032",
    "0.0.0.0:3256",
    "0.0.0.0:3512"
]
```

Then set per-port difficulty in `ckdb` section (advanced).

**Or just use one port (3032)** - ckpool has VarDiff and will auto-adjust for ASICs.

### Answer to Your Original Question:

**Can you remove ports 3256 and 3512?**

**YES!** Port 3032 with VarDiff (mindiff=1, maxdiff=16384) will handle:
- CPUs (adjusts down to diff 1-4)
- GPUs (adjusts to diff 32-512)
- ASICs (adjusts up to diff 4096-16384)

Large ASICs will work fine on port 3032. The pool automatically increases their difficulty.

**Having multiple ports is optional** - it's just for:
- Convenience (ASICs can skip low diff warmup)
- Segmentation (separate stats per port)
- Legacy compatibility (old miners expect diff-specific ports)

**Modern approach:** One port, VarDiff handles everything.

---

## Summary

### For Solo Mining (Block Finder Gets All):

**Use ckpool:**
```bash
git clone https://bitbucket.org/ckolivas/ckpool.git
cd ckpool
./configure && make && sudo make install
# Configure ckpool.conf with YOUR address
ckpool -c ckpool.conf
```

### For Pool Mining (Proportional Payouts):

**Use NOMP** (the configs I created earlier)

### Ports:

- **One port (3032) is fine** - VarDiff handles ASICs automatically
- **Three ports is optional** - slight convenience, not necessary

---

## Need Help Setting Up ckpool?

Let me know and I can:
1. Create complete ckpool config for Retardio
2. Write setup scripts
3. Document the full solo pool workflow

The choice is yours:
- **Solo pool** → ckpool (block finder gets 2397 RET)
- **Team pool** → NOMP (everyone shares rewards proportionally)

Which do you want to set up?
