# Retardio Stratum Mining Pool - Detailed Explanation

## Yes, It's a Stratum Pool!

The pool setup we created uses the **Stratum mining protocol**, which is the industry-standard protocol for cryptocurrency mining pools. Stratum is vastly superior to older protocols like getwork.

---

## Table of Contents

1. [What is Stratum?](#what-is-stratum)
2. [Pool Architecture](#pool-architecture)
3. [How the Pool Works](#how-the-pool-works)
4. [NOMP - The Pool Software](#nomp---the-pool-software)
5. [Share Validation & Difficulty](#share-validation--difficulty)
6. [Payment System](#payment-system)
7. [Miner Connection Flow](#miner-connection-flow)
8. [Technical Deep Dive](#technical-deep-dive)
9. [Pool vs Solo Mining](#pool-vs-solo-mining)
10. [Advanced Configuration](#advanced-configuration)

---

## What is Stratum?

### Stratum Protocol Overview

**Stratum** is a line-based JSON-RPC protocol used for communication between mining pools and miners. It was designed to replace the older getwork protocol.

### Why Stratum is Better:

**1. Reduced Bandwidth**
- Getwork: Miner requests new work every few seconds (~50 KB/s per miner)
- Stratum: Server pushes new work only when needed (~1 KB/s per miner)
- **Result:** Pool can handle 1000s of miners with minimal bandwidth

**2. Extranonce Support**
- Miners can generate their own unique work by modifying the extranonce
- No need to request new work constantly
- Miners can iterate through billions of hashes without contacting server

**3. Difficulty Adjustment**
- Pool can adjust difficulty per-miner in real-time
- Fast miners get harder work, slow miners get easier work
- Optimizes share submission rate for all miner types (CPU, GPU, ASIC)

**4. Long Polling Built-In**
- Pool pushes new work to miners instantly when blocks change
- No polling overhead
- Miners always work on latest block

**5. Worker Authentication**
- Miners authenticate with username/password
- Pool tracks shares per worker
- Better statistics and monitoring

---

## Pool Architecture

Here's the complete architecture of your Retardio stratum pool:

```
┌─────────────────────────────────────────────────────────────┐
│                    MINING POOL STACK                         │
└─────────────────────────────────────────────────────────────┘

┌──────────────┐      ┌──────────────┐      ┌──────────────┐
│  Miner #1    │      │  Miner #2    │      │  Miner #N    │
│  (cpuminer)  │      │  (cgminer)   │      │   (ASIC)     │
└──────┬───────┘      └──────┬───────┘      └──────┬───────┘
       │                     │                     │
       │  Stratum Protocol (TCP Socket)           │
       │  Port 3032 (auto-adjusts difficulty)     │
       └─────────────────────┬─────────────────────┘
                             │
                    ┌────────▼─────────┐
                    │  STRATUM SERVER  │
                    │  (NOMP/Node.js)  │
                    │                  │
                    │  - Accepts conn  │
                    │  - Sends work    │
                    │  - Validates     │
                    │  - Tracks shares │
                    └────────┬─────────┘
                             │
              ┌──────────────┼──────────────┐
              │              │              │
      ┌───────▼──────┐  ┌────▼─────┐  ┌────▼──────┐
      │   REDIS DB   │  │ RETARDIO │  │  PAYMENT  │
      │              │  │   NODE   │  │ PROCESSOR │
      │ - Shares     │  │          │  │           │
      │ - Stats      │  │ - RPC    │  │ - Calc    │
      │ - Balances   │  │ - Blocks │  │ - Payouts │
      └──────────────┘  └────┬─────┘  └───────────┘
                             │
                      ┌──────▼──────┐
                      │ BLOCKCHAIN  │
                      │   (Blocks)  │
                      └─────────────┘
```

### Component Breakdown

#### 1. **Stratum Server (NOMP)**
- **Language:** Node.js
- **Function:** Core pool server that handles miner connections
- **Port:**
  - 3032 (universal port - auto-adjusts difficulty for all miners)
- **Responsibilities:**
  - Accept TCP connections from miners
  - Authenticate workers
  - Send mining jobs (block templates)
  - Receive and validate shares
  - Adjust difficulty per miner
  - Detect new blocks
  - Update miners when new blocks arrive

#### 2. **Redis Database**
- **Function:** In-memory database for fast share tracking
- **Stores:**
  - Valid shares submitted by each miner
  - Invalid/rejected shares
  - Miner hashrate statistics
  - Block discovery data
  - Pending balances
  - Payment history
- **Why Redis:**
  - Extremely fast (100k+ ops/second)
  - Persistence options available
  - Simple key-value storage perfect for shares

#### 3. **Retardio Node**
- **Function:** Full blockchain node with RPC enabled
- **Pool Uses RPC For:**
  - `getblocktemplate` - Get new block template to mine
  - `submitblock` - Submit solved blocks to network
  - `getinfo` / `getblockchaininfo` - Network status
  - `sendmany` - Process payouts to miners
  - `validateaddress` - Validate miner addresses
- **Requirements:**
  - Must have `server=1` in retardio.conf
  - Must have `txindex=1` for tracking
  - RPC credentials must match pool config

#### 4. **Payment Processor**
- **Function:** Calculates and sends payouts
- **Process:**
  1. Runs every X seconds (configurable, default 120s)
  2. Calculates each miner's share percentage
  3. Determines payout amounts
  4. Sends payments via `sendmany` RPC call
  5. Updates Redis with payment records
- **Payment Methods:**
  - **PROP (Proportional):** Shares divided by total shares in round
  - **PPLNS (Pay Per Last N Shares):** More fair, reduces pool hopping
  - **PPS (Pay Per Share):** Guaranteed payment (pool takes risk)

---

## How the Pool Works

### Step-by-Step Mining Process

#### Phase 1: Miner Connects

```
Miner                         Pool
  │                            │
  ├──── TCP Connect ──────────>│
  │     (to port 3032)         │
  │                            │
  │<──── Connection OK ────────┤
  │                            │
  ├──── mining.subscribe ─────>│
  │                            │
  │<──── extranonce1 ──────────┤
  │      extranonce2_size      │
  │                            │
  ├──── mining.authorize ─────>│
  │   ("Faddress", "x")        │
  │                            │
  │<──── Authorized ───────────┤
```

**What Happens:**
1. Miner opens TCP connection to pool
2. Pool accepts connection
3. Miner subscribes to mining notifications
4. Pool assigns unique **extranonce1** (ensures unique work)
5. Miner authenticates with Retardio address
6. Pool validates address format (starts with F)

#### Phase 2: Pool Sends Mining Job

```
Pool                          Miner
  │                            │
  ├──── mining.notify ────────>│
  │                            │
  │  Job Parameters:           │
  │  - job_id: "5001"          │
  │  - prevhash: "abc123..."   │
  │  - coinb1: "010000..."     │
  │  - coinb2: "...ffffff"     │
  │  - merkle_branch: [...]    │
  │  - version: "20000000"     │
  │  - nbits: "1e0fffff"       │
  │  - ntime: "675a8c40"       │
  │  - clean_jobs: true        │
  │                            │
```

**What Happens:**
1. Pool gets block template from Retardio node via `getblocktemplate`
2. Pool constructs coinbase transaction:
   - Output 1: Block reward (2397.26 RET) to pool address
   - Output 2: Pool fee (1% default) to fee address
   - **extranonce space** left for miners to modify
3. Pool calculates merkle branch
4. Pool sends job to miner via `mining.notify`

**Miner's Work:**
- Constructs full block header from job parameters
- Inserts own **extranonce2** (makes work unique)
- Iterates **nonce** from 0 to 4.2 billion
- Hashes with SHA-256d
- If hash < difficulty target, submits share

#### Phase 3: Miner Submits Share

```
Miner                         Pool
  │                            │
  ├──── mining.submit ────────>│
  │                            │
  │  Share Data:               │
  │  - worker: "Faddress"      │
  │  - job_id: "5001"          │
  │  - extranonce2: "0000"     │
  │  - ntime: "675a8c40"       │
  │  - nonce: "f3a41c5b"       │
  │                            │
  │<──── Result: true ─────────┤
  │      (Share accepted!)     │
```

**Pool Validation Process:**
1. Reconstruct block header using share data
2. Insert miner's extranonce2
3. Hash with SHA-256d
4. Check if hash meets **share difficulty** (NOT block difficulty!)
5. If valid:
   - Record share in Redis
   - Respond with `true`
   - Check if hash also meets **block difficulty**
   - If block: Submit to network!
6. If invalid:
   - Reject share
   - Respond with error
   - Possibly ban miner if too many invalids

#### Phase 4: Block Found!

```
Pool discovers share meets block difficulty:

Pool                    Retardio Node           Network
  │                           │                    │
  ├─── submitblock ──────────>│                    │
  │    (full block data)      │                    │
  │                           │                    │
  │                           ├─── Broadcast ─────>│
  │                           │   (to peers)       │
  │                           │                    │
  │<─── Block accepted ───────┤                    │
  │                           │                    │
  ├─── Notify all miners ─────────────────────────>│
  │    (new block, start fresh work)               │
```

**What Happens:**
1. Pool detects winning share
2. Constructs full block with transactions
3. Submits via `submitblock` RPC
4. Node validates and broadcasts
5. Pool records block in Redis
6. Pool pushes new job to all miners (clean_jobs=true)
7. Block reward goes to pool address
8. After 100 confirmations, pool processes payouts

#### Phase 5: Payment Processing

```
Every 120 seconds (configurable):

Payment Processor:
  1. Query Redis for all shares since last round
  2. Calculate each miner's percentage:
     miner_shares / total_shares = percentage
  3. Calculate payout:
     block_reward * percentage = miner_payout
  4. Build payment transaction:
     sendmany {
       "Fminer1": 245.50,
       "Fminer2": 1250.75,
       "Fminer3": 901.01
     }
  5. Subtract pool fee (1%)
  6. Send via RPC to Retardio node
  7. Update Redis with payment records
  8. Clear shares for next round
```

---

## NOMP - The Pool Software

### What is NOMP?

**NOMP** = **Node Open Mining Portal**

- **Repository:** https://github.com/zone117x/node-open-mining-portal
- **Language:** Node.js / JavaScript
- **License:** GPL-2.0
- **Status:** Mature, battle-tested on many coins
- **Features:**
  - Full stratum implementation
  - Multi-coin support
  - Web interface for stats
  - MPOS database integration (optional)
  - Variable difficulty (VarDiff)
  - Share validation
  - Payment processing
  - Ban system for bad miners

### NOMP Architecture

```
node-open-mining-portal/
├── init.js                 # Main entry point
├── libs/
│   ├── pool.js             # Pool management
│   ├── stratum.js          # Stratum protocol
│   ├── jobManager.js       # Mining job creation
│   ├── daemon.js           # RPC communication
│   ├── varDiff.js          # Variable difficulty
│   └── paymentProcessor.js # Payout handling
├── coins/
│   └── retardio.json       # Coin config (algorithm, prefixes)
├── pool_configs/
│   └── retardio.json       # Pool config (ports, RPC, etc.)
└── website/                # Optional web frontend
```

### How NOMP Handles Shares

**Share Types:**

1. **Valid Share** - Meets miner's difficulty, credited
2. **Invalid Share** - Failed validation (wrong nonce, etc.)
3. **Stale Share** - Based on old work (block changed)
4. **Block Share** - Valid share that solves block!
5. **Duplicate Share** - Same nonce submitted twice

**Share Difficulty vs Block Difficulty:**

```
Block Difficulty:  0x1e0fffff (initial)
   = 1,048,576 hashes expected

Miner Difficulty:  Varies per miner
   CPU miner:      8 (8 hashes expected)
   GPU miner:      256 (256 hashes expected)
   ASIC miner:     4096 (4096 hashes expected)

Example:
- Miner finds hash: 0x0000000abcdef...
- Pool checks:
  1. Is hash < miner difficulty (8)? YES → Valid share
  2. Is hash < block difficulty (1048576)? NO → Just a share

- If both YES → BLOCK FOUND!
```

This means:
- CPU miner submits ~1 share every 2 seconds (at ~4 H/s)
- Each share has a 1 in 131,072 chance of being a block (at diff 8)
- Pool combines all miners' shares to find blocks faster

### Variable Difficulty (VarDiff)

NOMP automatically adjusts each miner's difficulty to target ~1 share every 15 seconds.

**Configuration (from retardio-pool.json):**
```json
"varDiff": {
    "minDiff": 1,           // Lowest difficulty
    "maxDiff": 512,         // Highest difficulty
    "targetTime": 15,       // Target 1 share per 15 seconds
    "retargetTime": 90,     // Readjust every 90 seconds
    "variancePercent": 30   // Allow 30% variance
}
```

**How It Works:**
```
1. Miner starts at diff=8
2. After 90 seconds, pool measures share rate
3. If miner submits shares too fast (< 15s average):
   → Increase difficulty (e.g., 8 → 16)
4. If miner submits shares too slow (> 15s average):
   → Decrease difficulty (e.g., 8 → 4)
5. Repeat every 90 seconds
```

**Benefits:**
- Optimizes network traffic (not too many shares)
- Fair for all hashrates (CPU to ASIC)
- Reduces pool server load
- Miners always productive

---

## Payment System

### Payment Models Supported

#### 1. **PROP (Proportional)** - Default
```
When block is found:
  1. Count all shares submitted since last block
  2. Calculate: payout = (your_shares / total_shares) * block_reward
  3. Pay out immediately or accumulate

Example:
  Block reward: 2397.26 RET
  Pool fee: 1% = 23.97 RET
  Distributable: 2373.29 RET

  Miner A: 1000 shares (10%) → 237.33 RET
  Miner B: 5000 shares (50%) → 1186.65 RET
  Miner C: 4000 shares (40%) → 949.31 RET
```

**Pros:**
- Simple and easy to understand
- Fair if miners stay consistently

**Cons:**
- Vulnerable to "pool hopping" (miners switch pools based on round length)
- Variance (long rounds = lower payout per share)

#### 2. **PPLNS (Pay Per Last N Shares)** - More Fair
```
When block is found:
  1. Look back at last N shares (e.g., last 1000 shares)
  2. Only count those shares for payment
  3. Shares older than N are ignored

Example with N=1000:
  Block found at share #5000
  Payment calculated from shares #4000-5000

  Miners who left after share #3500: Get nothing
  Miners who joined at share #4500: Get paid!
```

**Pros:**
- Reduces pool hopping (hoppers don't benefit from switching)
- More fair for consistent miners
- Pool operator takes less variance risk

**Cons:**
- More complex
- Can confuse new miners
- Miners might not get paid if they mine briefly

#### 3. **PPS (Pay Per Share)** - Not Recommended for Small Pools
```
Each share paid immediately at fixed rate:
  Payment per share = block_reward / block_difficulty

Example:
  Block reward: 2397.26 RET
  Block difficulty: 1,048,576 (at diff 0x1e0fffff)
  Payment per diff-1 share: 2397.26 / 1,048,576 = 0.002287 RET

  Miner submits diff-8 share → 8 * 0.002287 = 0.01829 RET
```

**Pros:**
- Zero variance for miners (guaranteed payment)
- Miners love it (predictable income)

**Cons:**
- Pool takes ALL variance risk
- If unlucky, pool loses money
- Requires large reserves
- Not recommended for new pools

### Payment Configuration

From `retardio-pool.json`:
```json
"paymentProcessing": {
    "enabled": true,
    "paymentInterval": 120,        // Run every 2 minutes
    "minimumPayment": 10.0,        // Min 10 RET to payout
    "maxBlocksPerPayment": 10,     // Process max 10 blocks per run
    "daemon": {
        "host": "127.0.0.1",
        "port": 18332,
        "user": "retardiouser",
        "password": "your_rpc_password"
    }
}
```

**How It Works:**

```javascript
Every 120 seconds:
  1. Check Redis for unpaid blocks (mature, 100+ confirmations)
  2. For each block:
     a. Get all shares for that round
     b. Calculate payouts
     c. Build sendmany transaction
     d. Submit to Retardio node
  3. Mark block as paid
  4. Update miner balances
  5. If balance > minimumPayment:
     - Include in next payout
  6. If balance < minimumPayment:
     - Accumulate for next time
```

**Transaction Fees:**
- Pool pays transaction fees
- Deducted from pool fee portion
- Configurable in code

---

## Miner Connection Flow

### Complete Connection Example

Here's what happens when a miner connects (with actual stratum messages):

```json
[1] Miner → Pool: TCP connect to 127.0.0.1:3032
[2] Pool → Miner: Connection accepted

[3] Miner → Pool:
{
  "id": 1,
  "method": "mining.subscribe",
  "params": ["cpuminer/2.5.0"]
}

[4] Pool → Miner:
{
  "id": 1,
  "result": [
    [
      ["mining.set_difficulty", "b4b6693b72a50c7116db18d6497cac52"],
      ["mining.notify", "ae6812eb4cd7735a302a8a9dd95c6fde"]
    ],
    "08000002",  // extranonce1
    4            // extranonce2_size
  ],
  "error": null
}

[5] Miner → Pool:
{
  "id": 2,
  "method": "mining.authorize",
  "params": ["FaDf8jKmN3pQrS9tV2wX4yZ5bC6dE7fG8h", "x"]
}

[6] Pool → Miner:
{
  "id": 2,
  "result": true,
  "error": null
}

[7] Pool → Miner:
{
  "id": null,
  "method": "mining.set_difficulty",
  "params": [8]  // Starting difficulty
}

[8] Pool → Miner:
{
  "id": null,
  "method": "mining.notify",
  "params": [
    "5001",                                          // job_id
    "4a5e1e4baab89f3a32518a88c31bc87f618f76673e",   // prevhash (reversed)
    "01000000010000000000000000000000000000000000", // coinb1
    "ffffffff00000000",                             // coinb2
    [],                                              // merkle_branch
    "20000000",                                      // version
    "1e0fffff",                                      // nbits
    "675a8c40",                                      // ntime
    true                                             // clean_jobs
  ]
}

[9] Miner computes locally (no network traffic)
    - Tries billions of nonces
    - Takes 1-30 seconds

[10] Miner → Pool (found valid share!):
{
  "id": 4,
  "method": "mining.submit",
  "params": [
    "FaDf8jKmN3pQrS9tV2wX4yZ5bC6dE7fG8h",  // worker
    "5001",                                 // job_id
    "00000000",                             // extranonce2
    "675a8c45",                             // ntime
    "a3f0125c"                              // nonce
  ]
}

[11] Pool validates share:
     - Reconstructs block header
     - Hashes with SHA256d
     - Checks if hash meets difficulty 8
     - Records in Redis

[12] Pool → Miner:
{
  "id": 4,
  "result": true,  // Share accepted!
  "error": null
}

[13] Repeat steps 9-12 until new block...

[14] Pool detects new block (via Retardio node):

[15] Pool → Miner:
{
  "id": null,
  "method": "mining.notify",
  "params": [
    "5002",      // NEW job_id
    "00000a1b2c3d4e5f...",  // NEW prevhash
    // ... new coinbase, new ntime, etc.
    true         // clean_jobs=true (discard old work!)
  ]
}

[16] Miner immediately switches to new work
     (old shares now invalid/stale)
```

---

## Technical Deep Dive

### Share Validation Algorithm

Here's exactly how the pool validates a share:

```python
def validate_share(job, extranonce2, ntime, nonce):
    # 1. Reconstruct coinbase transaction
    coinbase = job.coinb1 + extranonce1 + extranonce2 + job.coinb2
    coinbase_hash = sha256d(coinbase)

    # 2. Calculate merkle root
    merkle_root = coinbase_hash
    for branch in job.merkle_branch:
        merkle_root = sha256d(merkle_root + branch)

    # 3. Build block header (80 bytes)
    header = (
        job.version +           # 4 bytes
        job.prevhash +          # 32 bytes (reversed)
        merkle_root +           # 32 bytes (reversed)
        ntime +                 # 4 bytes
        job.nbits +             # 4 bytes
        nonce                   # 4 bytes
    )

    # 4. Hash the header
    hash_result = sha256d(header)
    hash_int = int.from_bytes(hash_result[::-1], 'big')

    # 5. Calculate difficulty target
    miner_difficulty = get_miner_difficulty(worker_address)
    target = calculate_target(miner_difficulty)

    # 6. Validate
    if hash_int > target:
        return "invalid"  # Hash doesn't meet difficulty

    # 7. Check if it's also a block
    block_target = calculate_target(network_difficulty)
    if hash_int <= block_target:
        submit_block_to_network(header, coinbase, transactions)
        return "block"  # IT'S A BLOCK!

    return "valid"  # Valid share, not a block
```

### Difficulty Calculation

```python
def calculate_target(difficulty):
    """
    Converts difficulty number to target hash value
    Bitcoin uses: 0x00000000FFFF0000000000000000000000000000000000000000000000000000
    as diff 1 target
    """
    diff1_target = 0x00000000FFFF0000000000000000000000000000000000000000000000000000
    target = diff1_target // difficulty
    return target

# Examples:
# Difficulty 1:  target = 0x00000000FFFF0000...
#                (hash must start with 8 zeros)
# Difficulty 8:  target = 0x00000000001FFFC0...
#                (hash must start with 11 zeros)
# Difficulty 256: target = 0x0000000000003FFF...
#                 (hash must start with 15 zeros)
```

### Extranonce Space

The extranonce allows miners to iterate through a massive search space without asking for new work:

```
Extranonce1: 4 bytes (assigned by pool, unique per miner)
Extranonce2: 4 bytes (miner can change freely)
Nonce:       4 bytes (miner iterates)

Total search space per job:
  extranonce2: 2^32 = 4.2 billion values
  nonce:       2^32 = 4.2 billion values
  Total:       2^64 = 18.4 quintillion hashes!

Example:
  Job ID: 5001
  Extranonce1: 0x08000002 (pool assigns)

  Miner tries:
    extranonce2=0x00000000, nonce=0x00000000
    extranonce2=0x00000000, nonce=0x00000001
    extranonce2=0x00000000, nonce=0x00000002
    ...
    extranonce2=0x00000000, nonce=0xFFFFFFFF (4 billion)
    extranonce2=0x00000001, nonce=0x00000000 (start over with new coinbase)
    ...

  This allows miner to work for hours without contacting pool!
```

---

## Pool vs Solo Mining

### Solo Mining

```
Pro:
  ✓ Keep 100% of block rewards
  ✓ No pool fees
  ✓ No pool downtime risk
  ✓ Complete control

Con:
  ✗ High variance (might not find blocks for days/weeks)
  ✗ All-or-nothing (either 2397 RET or 0 RET)
  ✗ Small miners rarely find blocks

Best for:
  - Large miners (high hashrate)
  - Testing
  - Low-difficulty networks
```

### Pool Mining

```
Pro:
  ✓ Consistent payouts
  ✓ Low variance
  ✓ Good for small miners
  ✓ Predictable income

Con:
  ✗ Pool fees (1-3% typical)
  ✗ Trust pool operator
  ✗ Pool downtime affects earnings
  ✗ Pool might get hacked

Best for:
  - Small/medium miners
  - Miners who want steady income
  - Production mining
```

### Comparison Example

```
Scenario: Network hashrate = 1000 MH/s, block time = 30s

Solo Mining (10 MH/s - 1% of network):
  Expected blocks per day: 2,880 * 0.01 = 28.8 blocks
  Expected income: 28.8 * 2397.26 = 69,041 RET/day
  Reality: Might find 0 blocks one day, 50 blocks another day
  Variance: VERY HIGH

Pool Mining (10 MH/s - 1% of pool):
  Pool finds: ~288 blocks/day (10% of network)
  Your share: 1% of pool = 2.88 blocks worth
  Expected income: 2.88 * 2397.26 * 0.99 (1% fee) = 6,834 RET/day
  Reality: Consistent ~6,834 RET every day
  Variance: LOW

Conclusion: Pool is better for most miners
```

---

## Advanced Configuration

### Stratum Port Configuration

Your pool has a single port configured for all miner types:

```json
"ports": {
    "3032": {  // UNIVERSAL PORT - All miners
        "diff": 8,
        "varDiff": {
            "minDiff": 1,
            "maxDiff": 16384,
            "targetTime": 15,
            "retargetTime": 90,
            "variancePercent": 30
        }
    }
}
```

**Single Universal Port:**

- **Port 3032:** All miners (CPU/GPU/ASIC) start at diff 8
  - VarDiff automatically adjusts between 1-16384 based on hashrate
  - CPU miners might adjust down to diff 1-4
  - GPU miners might adjust to diff 16-256
  - ASIC miners might adjust up to diff 512-16384
  - Simplifies setup - miners just connect to one port

### Banning System

Pool automatically bans malicious miners:

```json
"banning": {
    "enabled": true,
    "time": 600,           // Ban for 10 minutes
    "invalidPercent": 50,  // If 50% of shares invalid
    "checkThreshold": 500, // After 500 shares
    "purgeInterval": 300   // Clean ban list every 5 min
}
```

**When Miners Get Banned:**
1. Submit too many invalid shares (wrong nonce, bad format)
2. Submit duplicate shares (same nonce twice)
3. Submit stale shares repeatedly (old work)
4. Flood attack (too many connections)

### Pool Fees

```json
"rewardRecipients": {
    "FpoolFeeAddress123...": 1.0  // 1% to this address
}
```

**How Fees Work:**
```
Block found: 2397.26 RET
Pool fee (1%): 23.97 RET → FpoolFeeAddress123...
Distribute: 2373.29 RET → Miners

This is built into the coinbase transaction,
so fees are automatic and can't be cheated.
```

### Payment Thresholds

```json
"minimumPayment": 10.0  // Only pay if balance >= 10 RET
```

**Why Thresholds?**
- Each payout costs transaction fees
- Small payouts waste fees
- Miners accumulate until threshold
- Configurable per pool

**Example:**
```
Miner earns 3 RET/day
Day 1: 3 RET (no payout, < 10 minimum)
Day 2: 6 RET (no payout)
Day 3: 9 RET (no payout)
Day 4: 12 RET (payout 12 RET, reset balance)
```

---

## Security Considerations

### 1. **RPC Security**
```
DANGER: Never expose RPC port (18332) to internet!

Bad:
  rpcbind=0.0.0.0
  rpcallowip=0.0.0.0/0

Good:
  rpcbind=127.0.0.1
  rpcallowip=127.0.0.1
```

### 2. **Pool Wallet Security**
```
- Keep minimal funds in pool hot wallet
- Use cold storage for reserves
- Regular backups of wallet.dat
- Encrypt wallet: retardio-cli encryptwallet "passphrase"
```

### 3. **DDoS Protection**
```
- Use firewall to rate-limit connections
- CloudFlare for web frontend
- Fail2ban for repeated failed auth
- Connection limits in pool config
```

### 4. **Share Validation**
```
- Always validate ALL shares
- Never trust miner data
- Ban miners with high invalid rate
- Log suspicious activity
```

---

## Summary

### Your Retardio Stratum Pool:

✅ **Full stratum protocol implementation**
✅ **Variable difficulty for all miner types**
✅ **Single universal port with auto-adjusting difficulty (1-16384)**
✅ **Automated payment processing (PROP)**
✅ **Share tracking with Redis**
✅ **Ban system for bad miners**
✅ **Configurable fees and thresholds**
✅ **Production-ready with NOMP**

### Key Features:

- **Protocol:** Stratum (industry standard)
- **Software:** NOMP (Node.js)
- **Database:** Redis (fast share tracking)
- **Port:** 3032 (universal, auto-adjusts diff 1-16384 for all miners)
- **Payment:** Proportional (PROP), configurable to PPLNS
- **Difficulty:** Variable per-miner (VarDiff)
- **Bandwidth:** ~1 KB/s per miner (very efficient)

### Setup Time:

- **Automated:** 5-10 minutes with `./setup_pool.sh`
- **Manual:** 20-30 minutes following MINING_SETUP.md

### Perfect For:

- Small to medium mining operations
- Community pools
- Private pools for friends/team
- Learning how mining pools work

---

**Ready to set up your pool? Run `./setup_pool.sh` when you're ready!**
