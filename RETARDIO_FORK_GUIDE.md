# Retardio Altcoin Fork Guide

This document outlines all the changes made to fork Retardio into the Retardio altcoin.

## Key Parameters

- **Name**: Retardio
- **PoW Algorithm**: SHA-256 (unchanged from Bitcoin)
- **Block Time**: 30 seconds (configurable down to 15 seconds like DGB)
- **Difficulty Adjustment**: Every 120 blocks (vs Bitcoin's 2016 blocks)
- **Block Reward**: 2,397.26 RET starting, reduces 1% (EXACT DigiByte emission)
- **Reduction Interval**: Every 87,600 blocks (12 reductions/year, same as DGB)
- **Max Supply**: ~21,000,000,000 coins (21 billion, same as DigiByte)
- **Network Port**: 18333
- **Address Prefix**: 'F' (base58 prefix: 35)
- **Bech32 HRP**: "ret"

## Files Modified

### 1. src/kernel/chainparams.cpp

This is the primary file containing all network parameters.

#### Key Changes Made:

**Line 75** - Genesis timestamp message:
```cpp
const char* pszTimestamp = "Retardio 18/Dec/2024 A new altcoin is born";
```

**Lines 90-97** - BIP activation heights (all enabled from genesis):
```cpp
consensus.BIP34Height = 0;
consensus.BIP65Height = 0;
consensus.BIP66Height = 0;
consensus.CSVHeight = 0;
consensus.SegwitHeight = 0;
consensus.MinBIP9WarningHeight = 0;
```

**Lines 99-108** - Consensus parameters for 30-second blocks:
```cpp
consensus.nPowTargetTimespan = 120 * 30;  // 3600 seconds = 1 hour
consensus.nPowTargetSpacing = 30;          // 30 seconds per block
consensus.nRuleChangeActivationThreshold = 108;  // 90% of 120
consensus.nMinerConfirmationWindow = 120;        // Difficulty adjustment window
```

**Lines 128-132** - Network magic bytes and port:
```cpp
pchMessageStart[0] = 0xfe;
pchMessageStart[1] = 0xca;
pchMessageStart[2] = 0xbe;
pchMessageStart[3] = 0xef;
nDefaultPort = 18333;
```

**Line 137** - Genesis block (nonce needs to be mined):
```cpp
genesis = CreateGenesisBlock(1734566400, 0, 0x1e0fffff, 1, 50 * COIN);
```

**Lines 146-152** - Address prefixes:
```cpp
base58Prefixes[PUBKEY_ADDRESS] = std::vector<unsigned char>(1,35);  // 'F' prefix
base58Prefixes[SCRIPT_ADDRESS] = std::vector<unsigned char>(1,85);
base58Prefixes[SECRET_KEY] = std::vector<unsigned char>(1,163);
bech32_hrp = "ret";
```

## Block Time Economics

With 30-second blocks:
- **Blocks per hour**: 120 blocks
- **Blocks per day**: 2,880 blocks
- **Blocks per month**: 86,400 blocks
- **Blocks per year**: ~1,051,200 blocks

### Emission Schedule (EXACT DigiByte Model)
- **Starting reward**: 2,397.26 RET per block
- **Reduction**: 1% every 87,600 blocks (12 reductions/year, same as DGB)
- **Daily emission**: ~6,905,000 RET initially (959x Bitcoin's rate)
- **Model**: Smooth exponential decay instead of abrupt halvings (same as DGB)
- **Full emission**: Approaches 21 billion asymptotically over many years
- **Note**: If block time changes to 15s, reduction interval becomes 175,200 blocks (exact DGB)

## Starting Difficulty

The genesis block uses `nBits = 0x1e0fffff`, which is relatively easy and suitable for:
- CPU mining during initial testing
- Target hashrate of ~1-10 MH/s for 30-second blocks
- Difficulty will adjust every 120 blocks (~1 hour)

## Next Steps

### 1. Mine the Genesis Block

You need to find a valid nonce for the genesis block. Use the provided Python script:

```bash
cd retardio-coin
python mine_genesis.py
```

This will output:
- The correct nonce value
- The genesis block hash
- The merkle root hash

### 2. Update chainparams.cpp with Genesis Results

After mining, update line 137 with the correct nonce:
```cpp
genesis = CreateGenesisBlock(1734566400, FOUND_NONCE, 0x1e0fffff, 1, 50 * COIN);
```

Uncomment and update lines 139-141 with the correct hashes:
```cpp
assert(consensus.hashGenesisBlock == uint256{"YOUR_GENESIS_HASH"});
assert(genesis.hashMerkleRoot == uint256{"YOUR_MERKLE_ROOT"});
```

### 3. Additional Files to Consider Modifying

While chainparams.cpp contains the core parameters, you may also want to update:

#### **src/clientversion.h**
- Change version strings and client name

#### **src/qt/res/retardio-qt-res.rc** (Windows)
- Update application name and descriptions

#### **src/qt/bitcoingui.cpp**
- Update GUI text and window titles

#### **README.md**
- Update project description

#### **configure.ac** and **Makefile.am**
- Update project name references

### 4. Build the Client

```bash
cd retardio-coin
./autogen.sh
./configure
make -j$(nproc)
```

### 5. Test the Chain

```bash
# Create data directory
mkdir -p ~/.retardio

# Start the daemon
./src/retardiod -datadir=~/.retardio -daemon

# Generate initial blocks (mining)
./src/retardio-cli -datadir=~/.retardio generatetoaddress 100 YOUR_ADDRESS

# Check blockchain info
./src/retardio-cli -datadir=~/.retardio getblockchaininfo
```

## Address Format Examples

With the 'F' prefix (base58 35):
- **Mainnet P2PKH**: Starts with 'F' (e.g., FxxxxxxxxxxxxxxxxxxxxxxxxxxxxXXXXXX)
- **Mainnet Bech32**: Starts with 'ret1' (e.g., ret1qxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx)

## Network Protocol

- **Magic Bytes**: 0xfecabeef (unique identifier for Retardio network packets)
- **Default Port**: 18333 (both P2P and RPC will use this by default)
- **DNS Seeds**: Cleared - add your own seed nodes as network grows

## Important Notes

1. **No Peer Network**: This is a brand new chain with no existing peers. You'll need to:
   - Mine your own blocks initially
   - Set up seed nodes
   - Manually add peer nodes using `-addnode`

2. **Testnet/Regtest**: The testnet and regtest parameters in chainparams.cpp should also be updated if you plan to use those networks.

3. **Checkpoint Data**: Currently cleared. Add checkpoints as the chain matures for faster sync.

4. **Security**: This is a fork for testing/learning. For production use:
   - Conduct thorough security audits
   - Set up proper DNS seeds
   - Consider additional anti-51% attack measures given the low initial hashrate

5. **Branding**: Search and replace "Bitcoin" with "Retardio" throughout the codebase for complete rebranding.

## Difficulty Adjustment Formula

The difficulty adjusts every 120 blocks to maintain 30-second block times:
```
Target Time = 120 blocks × 30 seconds = 3,600 seconds (1 hour)
Actual Time = Time for last 120 blocks
New Difficulty = Old Difficulty × (Target Time / Actual Time)
```

## Supply Schedule (EXACT DGB: 12 Reductions/Year)

| Time | Block | Reward | % of Starting | Cumulative Supply |
|------|-------|--------|---------------|-------------------|
| Genesis | 0 | 2,397.26 RET | 100% | 0 |
| 1 reduction | 87,600 | 2,373 RET | 99% | ~210 million |
| 12 reductions (1 yr) | 1,051,200 | 2,149 RET | 90% | ~2.4 billion |
| 2 years | 2,102,400 | 1,931 RET | 81% | ~4.6 billion |
| 5 years | 5,256,000 | 1,485 RET | 62% | ~10.5 billion |
| 10 years | 10,512,000 | 893 RET | 37% | ~17 billion |
| 20 years | 21,024,000 | 323 RET | 13% | ~20 billion |
| Infinite | ∞ | 0 RET | 0% | ~21 billion |

## Changing Block Time to 15 Seconds

If you want to match DigiByte's 15-second blocks, update these values in [chainparams.cpp](retardio-coin/src/kernel/chainparams.cpp):

```cpp
consensus.nPowTargetSpacing = 15; // Change from 30 to 15
consensus.nSubsidyHalvingInterval = 175200; // Change from 87,600 to 175,200 (EXACT DGB interval)
```

This will give you:
- **Blocks per hour**: 240 blocks (vs 120 at 30s)
- **Blocks per day**: 5,760 blocks (vs 2,880 at 30s)
- **12 reductions per year**: 175,200 blocks per reduction (EXACT DGB)
- **Same as DigiByte**: 1% every 175,200 blocks

## Mining

Initial mining can be done with:
- **CPU**: Using the built-in miner for testing
- **GPU**: Any SHA-256 capable miner (cgminer, bfgminer, etc.)
- **ASIC**: Compatible with Bitcoin SHA-256 ASICs (though massively overpowered for this network)

For initial testnet, recommend CPU mining with:
```bash
./src/retardio-cli -datadir=~/.retardio generatetoaddress 1 YOUR_ADDRESS
```

## Questions?

The main consensus parameters are now configured in:
- **src/kernel/chainparams.cpp** - Network and consensus rules
- **src/consensus/params.h** - Consensus parameter definitions (no changes needed)

Happy forking! 🚀
