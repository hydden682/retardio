# goslimstratum - Lightweight Solo Mining Pool for Retardio

## What is goslimstratum?

**goslimstratum** is a minimalist stratum mining proxy written in Go:

- ✅ **True solo mining** - Block finder gets 100% of reward
- ✅ **Extremely lightweight** - Uses minimal resources
- ✅ **No database** - No Redis/MySQL required
- ✅ **Simple configuration** - Single config file
- ✅ **Fast** - Written in Go, compiled binary
- ✅ **Small footprint** - Perfect for ESP32-friendly pools

**Repository:** https://github.com/sammy007/open-ethereum-pool

**Note:** Originally for Ethereum, but the core stratum server works with any coin.

---

## Better Alternative: go-pool

Actually, for Bitcoin-based coins (like Retardio), use:

**go-pool** or **gostratum**

Let me provide a better option specifically for SHA-256 coins:

---

## Recommended: Build Custom Go Stratum Proxy

Since goslimstratum is Ethereum-focused, here's a better approach for Retardio:

### Option A: Use `node-stratum-pool` (Lightweight)

This is the base library NOMP uses, but can run standalone for solo mining:

```bash
git clone https://github.com/zone117x/node-stratum-pool.git
cd node-stratum-pool
npm install
```

**Create solo config** (`pool.json`):
```json
{
    "enabled": true,
    "coin": "retardio",
    "address": "MINER_SETS_THIS",
    "rewardRecipients": {},
    "paymentProcessing": {
        "enabled": false
    },
    "ports": {
        "3032": {
            "diff": 8,
            "varDiff": {
                "minDiff": 1,
                "maxDiff": 64,
                "targetTime": 15,
                "retargetTime": 15,
                "variancePercent": 30
            }
        }
    },
    "daemons": [
        {
            "host": "127.0.0.1",
            "port": 18332,
            "user": "retardiouser",
            "password": "YOUR_PASSWORD"
        }
    ],
    "p2p": {
        "enabled": false
    }
}
```

**Start:**
```bash
node init.js
```

---

## Anti-ASIC Pool Configuration

### Strategy 1: Low Max Difficulty + Fast Retarget

**pool.json:**
```json
"ports": {
    "3032": {
        "diff": 4,           // Start very low
        "varDiff": {
            "minDiff": 1,
            "maxDiff": 64,   // Cap at 64 (anti-ASIC)
            "targetTime": 10,   // Target 1 share per 10 seconds
            "retargetTime": 15, // Retarget every 15 seconds
            "variancePercent": 20
        }
    }
}
```

**Effect:**
- ESP32 (1-10 KH/s): Comfy at diff 1-8
- Small GPU (1-10 MH/s): Comfortable at diff 8-64
- Large ASIC (1+ GH/s): **Floods pool with shares, gets rate limited/banned**

### Strategy 2: Single Port, Aggressive Limits

```json
"ports": {
    "3032": {
        "diff": 1,
        "varDiff": {
            "minDiff": 1,
            "maxDiff": 32,      // Very low cap
            "targetTime": 5,    // Very frequent shares
            "retargetTime": 10, // Very frequent retarget
            "variancePercent": 10
        }
    }
},
"banning": {
    "enabled": true,
    "time": 3600,              // Ban for 1 hour
    "invalidPercent": 30,      // Strict
    "checkThreshold": 100,     // Ban after 100 shares
    "purgeInterval": 300
}
```

**Effect:**
- ASICs submit 10,000+ shares/second at diff 32
- Pool connection overload
- Auto-banned for "flooding"
- ESP32s submit 1 share per 5-10 seconds (perfect)

---

## Blockchain-Level Anti-ASIC

### Current Difficulty Adjustment

```cpp
// chainparams.cpp line 101
consensus.nPowTargetTimespan = 120 * 30;  // 3600 seconds (1 hour)
consensus.nPowTargetSpacing = 30;         // 30 seconds
// Adjusts every 120 blocks
```

### Option 1: Frequent Retargeting (Every 10 Blocks)

```cpp
consensus.nPowTargetTimespan = 10 * 30;  // 300 seconds (5 minutes)
consensus.nPowTargetSpacing = 30;        // 30 seconds
consensus.nMinerConfirmationWindow = 10; // 10 blocks
consensus.nRuleChangeActivationThreshold = 9; // 90% of 10
```

**Effect:**
- Difficulty changes every ~5 minutes
- Large miners waste hashpower on outdated work
- Small miners benefit from quick adjustments

### Option 2: Per-Block Difficulty (Like Digibyte MultiShield)

This requires implementing a new difficulty algorithm. More complex but very effective.

**Example implementation:**

```cpp
// In validation.cpp or pow.cpp
unsigned int GetNextWorkRequired_MultiShield(const CBlockIndex* pindexLast, const CBlockHeader *pblock, const Consensus::Params& params)
{
    // Adjust difficulty EVERY block based on last N blocks
    const int64_t nTargetSpacing = params.nPowTargetSpacing;
    const int nBlocksToAverage = 10; // Look at last 10 blocks

    // Calculate average time of last N blocks
    int64_t nActualTimespan = 0;
    const CBlockIndex* pindex = pindexLast;
    for (int i = 0; i < nBlocksToAverage && pindex; i++) {
        nActualTimespan += pindex->GetBlockTime() - pindex->pprev->GetBlockTime();
        pindex = pindex->pprev;
    }
    nActualTimespan /= nBlocksToAverage;

    // Adjust difficulty based on actual vs target
    arith_uint256 bnNew;
    bnNew.SetCompact(pindexLast->nBits);

    // Limit adjustment to prevent wild swings
    if (nActualTimespan < nTargetSpacing / 4)
        nActualTimespan = nTargetSpacing / 4;
    if (nActualTimespan > nTargetSpacing * 4)
        nActualTimespan = nTargetSpacing * 4;

    bnNew *= nActualTimespan;
    bnNew /= nTargetSpacing;

    // Don't exceed bounds
    if (bnNew > params.powLimit)
        bnNew = params.powLimit;

    return bnNew.GetCompact();
}
```

**Effect:**
- Difficulty adjusts EVERY SINGLE BLOCK
- Large ASICs can't stabilize
- Rapid hashrate changes don't dominate
- ESP32s have fair chance during low-diff blocks

---

## Recommended Setup for ESP32-Friendly Network

### Network Level (chainparams.cpp):

```cpp
// Fast difficulty adjustment - every 30 blocks (~15 minutes)
consensus.nPowTargetTimespan = 30 * 30;  // 900 seconds
consensus.nPowTargetSpacing = 30;        // 30 seconds
consensus.nMinerConfirmationWindow = 30;
consensus.nRuleChangeActivationThreshold = 27; // 90% of 30
```

### Pool Level (pool.json):

```json
{
    "ports": {
        "3032": {
            "diff": 1,
            "varDiff": {
                "minDiff": 1,
                "maxDiff": 32,      // Anti-ASIC cap
                "targetTime": 8,     // Fast shares
                "retargetTime": 10,  // Quick adjustment
                "variancePercent": 20
            }
        }
    },
    "banning": {
        "enabled": true,
        "time": 3600,
        "invalidPercent": 25,
        "checkThreshold": 200
    },
    "connectionTimeout": 300
}
```

### Effect on Different Miners:

**ESP32 (5 KH/s):**
- Diff 1-2
- Submits ~1 share per 10 seconds
- Perfect experience ✅

**Small GPU (10 MH/s):**
- Diff 8-32
- Submits ~1 share per 8 seconds
- Comfortable ✅

**Large ASIC (1 TH/s):**
- Capped at diff 32
- Submits 31,250 shares/second
- **Pool rejects: "Rate limit exceeded"** ❌
- Gets banned ❌
- Leaves for easier network ❌

---

## Implementation Plan

Want me to create:

### Option 1: Pool-Only Protection (Quick)
- Update pool configs with low maxDiff (32-64)
- Fast retargeting (10-15 seconds)
- Aggressive banning
- **No code changes needed**

### Option 2: Network + Pool Protection (Better)
- Modify chainparams.cpp for 30-block retargeting
- Update pool configs
- **Requires rebuild**

### Option 3: Full Anti-ASIC (Best)
- Implement per-block difficulty adjustment
- Update pool configs
- **Requires new difficulty algorithm**

### Option 4: Change PoW Algorithm (Nuclear Option)
- Switch from SHA-256 to scrypt/yescrypt/randomx
- ASIC-resistant algorithms
- **Requires significant code changes**

Which approach do you want?

---

## For goslimstratum Specifically

If you really want Go-based stratum:

**Better options for Bitcoin-based coins:**
1. **ckpool** - C, ultra-lightweight, battle-tested
2. **Stratum mining proxy** - Python, simple
3. **Write custom Go proxy** - Can provide example code

goslimstratum is Ethereum-specific and would need heavy modification for SHA-256 coins.

**Recommendation:** Use **ckpool** for solo mining + aggressive pool configs for anti-ASIC.

Let me know which strategy you want and I'll implement it!
