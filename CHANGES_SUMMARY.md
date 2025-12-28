# Retardio Fork - Changes Summary

## Quick Reference: What Was Changed

### File: src/kernel/chainparams.cpp

| Line | Original Value | New Value | Purpose |
|------|----------------|-----------|---------|
| 75 | `"The Times 03/Jan/2009..."` | `"Retardio 18/Dec/2024..."` | Genesis timestamp message |
| 89 | `210000` | `87600` | Reduction interval (12/year, EXACT DGB) |
| 91 | `227931` | `0` | BIP34 active from genesis |
| 93 | `388381` | `0` | BIP65 active from genesis |
| 94 | `363725` | `0` | BIP66 active from genesis |
| 95 | `419328` | `0` | CSV active from genesis |
| 96 | `481824` | `0` | Segwit active from genesis |
| 97 | `483840` | `0` | BIP9 warning height |
| 99 | `14 * 24 * 60 * 60` | `120 * 30` | Difficulty adjustment period (1 hour) |
| 100 | `10 * 60` | `30` | Block time (30 seconds) |
| 104 | `1815` | `108` | Activation threshold (90% of 120) |
| 105 | `2016` | `120` | Difficulty adjustment window |
| 109-112 | Taproot dates | `ALWAYS_ACTIVE` | Taproot active from genesis |
| 115 | Bitcoin magic | `0xfe, 0xca, 0xbe, 0xef` | Network magic bytes |
| 116 | `8333` | `18333` | Network port |
| 136 | `50 * COIN` | `239726 * COIN / 100` | Genesis block reward (2397.26 RET, EXACT DGB) |
| 125-127 | Bitcoin hashes | Commented out | Will be set after genesis mining |
| 129 | Bitcoin DNS seeds | `vSeeds.clear()` | No DNS seeds yet |
| 131 | `std::vector<unsigned char>(1,0)` | `std::vector<unsigned char>(1,35)` | Address prefix (F) |
| 132 | `std::vector<unsigned char>(1,5)` | `std::vector<unsigned char>(1,85)` | Script address prefix |
| 133 | `std::vector<unsigned char>(1,128)` | `std::vector<unsigned char>(1,163)` | Private key prefix |
| 135 | `"bc"` | `"ret"` | Bech32 prefix |
| 143-178 | Bitcoin checkpoints | Empty | Cleared for new chain |
| 180-194 | Bitcoin assumeutxo | Empty | Cleared for new chain |
| 196-201 | Bitcoin chain data | New data (0 txs) | Reset for new chain |

### File: src/consensus/params.h

**No changes required** - This file defines the parameter structures used by chainparams.cpp.

### File: src/validation.cpp

**Modified**: GetBlockSubsidy() function at line 2212

**Original code** (Bitcoin halving):
```cpp
CAmount GetBlockSubsidy(int nHeight, const Consensus::Params& consensusParams)
{
    int halvings = nHeight / consensusParams.nSubsidyHalvingInterval;
    if (halvings >= 64)
        return 0;
    CAmount nSubsidy = 50 * COIN;
    nSubsidy >>= halvings;  // Bit-shift right (divide by 2^halvings)
    return nSubsidy;
}
```

**New code** (EXACT DigiByte emission - 12 reductions/year):
```cpp
CAmount GetBlockSubsidy(int nHeight, const Consensus::Params& consensusParams)
{
    CAmount nSubsidy = 239726 * COIN / 100;  // 2397.26 RET (EXACT DGB for 21B supply)
    int reductions = nHeight / consensusParams.nSubsidyHalvingInterval;

    // Apply 1% reduction for each period (EXACT DGB model)
    for (int i = 0; i < reductions; i++) {
        nSubsidy = nSubsidy * 99 / 100;
        if (nSubsidy == 0) break;
    }
    return nSubsidy;
}
```

## Critical Parameters Explained

### Block Time: 30 seconds
```cpp
consensus.nPowTargetSpacing = 30;
```
- Bitcoin: 600 seconds (10 minutes)
- Retardio: 30 seconds
- **20x faster than Bitcoin**

### Difficulty Adjustment: 120 blocks
```cpp
consensus.nPowTargetTimespan = 120 * 30;  // 3600 seconds
consensus.nMinerConfirmationWindow = 120;
```
- Bitcoin adjusts every 2016 blocks (~2 weeks)
- Retardio adjusts every 120 blocks (~1 hour)
- Adjustment interval calculation: `nPowTargetTimespan / nPowTargetSpacing = 3600 / 30 = 120 blocks`

### Emission Model: EXACT DigiByte (12 Reductions/Year)
```cpp
consensus.nSubsidyHalvingInterval = 87600;  // 12 reductions/year at 30s blocks
```
- Bitcoin halves every 210,000 blocks (~4 years): 50→25→12.5→6.25... (21M max)
- DigiByte reduces 1% every 175,200 blocks (12/year at 15s) (21B max)
- Retardio reduces 1% every 87,600 blocks (12/year at 30s) (21B max, EXACT DGB)
- Starting reward: 2,397.26 RET (calculated for exact 21B supply)
- After 1 reduction: 2,373 RET (99% of previous)
- After 12 reductions (1 year): 2,149 RET (90% of starting)
- Smooth exponential decay curve instead of abrupt halvings (same as DGB)
- **Configurable**: Can change to 15s blocks (change nSubsidyHalvingInterval to 175,200 for EXACT DGB)

### Starting Difficulty: 0x1e0fffff
```cpp
genesis = CreateGenesisBlock(1734566400, 0, 0x1e0fffff, 1, 239726 * COIN / 100);
```
- This is easier than Bitcoin's original 0x1d00ffff
- Suitable for ~1-10 MH/s hashrate
- Will adjust automatically every 120 blocks

### Network Magic: 0xfecabeef
```cpp
pchMessageStart[0] = 0xfe;
pchMessageStart[1] = 0xca;
pchMessageStart[2] = 0xbe;
pchMessageStart[3] = 0xef;
```
- Unique identifier for Retardio network packets
- Prevents accidental connection to Bitcoin network
- Must be different from Bitcoin (0xf9beb4d9)

### Address Prefix: 'F'
```cpp
base58Prefixes[PUBKEY_ADDRESS] = std::vector<unsigned char>(1,35);
```
- Base58 encoding with prefix 35 produces addresses starting with 'F'
- Example: FxxxxxxxxxxxxxxxxxxxxxxxxxxxxXXXXXX
- Easy to distinguish from Bitcoin addresses (which start with '1' or '3')

## Genesis Block Mining

**Current Status**: Genesis block configured but NOT MINED yet

**To mine**:
```bash
python mine_genesis.py
```

**Then update** [chainparams.cpp:136](retardio-coin/src/kernel/chainparams.cpp#L136):
```cpp
genesis = CreateGenesisBlock(1734566400, FOUND_NONCE, 0x1e0fffff, 1, 239726 * COIN / 100);
```

**And uncomment** [chainparams.cpp:139-141](retardio-coin/src/kernel/chainparams.cpp#L139-L141):
```cpp
assert(consensus.hashGenesisBlock == uint256{"YOUR_GENESIS_HASH"});
assert(genesis.hashMerkleRoot == uint256{"YOUR_MERKLE_ROOT"});
```

## Build & Test

1. **Mine genesis block**:
   ```bash
   python mine_genesis.py
   ```

2. **Update genesis parameters** in chainparams.cpp with results

3. **Build**:
   ```bash
   ./autogen.sh
   ./configure
   make -j$(nproc)
   ```

4. **Run**:
   ```bash
   ./src/retardiod -datadir=~/.retardio -daemon
   ```

5. **Mine blocks**:
   ```bash
   ./src/retardio-cli -datadir=~/.retardio generatetoaddress 100 YOUR_ADDRESS
   ```

## Verification Checklist

- [ ] Genesis block mined (valid nonce found)
- [ ] Genesis hash updated in chainparams.cpp
- [ ] Merkle root hash updated in chainparams.cpp
- [ ] Code compiles without errors
- [ ] Can generate blocks with 30-second target
- [ ] Difficulty adjusts after 120 blocks
- [ ] Addresses start with 'F'
- [ ] Network uses port 18333
- [ ] Block reward is 2,397.26 coins initially (EXACT DGB)
- [ ] Reward reduces by 1% every 87,600 blocks (at 30s) or 175,200 blocks (at 15s)
- [ ] Max supply approaches 21 billion (same as DGB)

## Network Economics

| Metric | Bitcoin | DigiByte | Retardio |
|--------|---------|----------|----------|
| Block time | 10 min | 15 sec | 30 sec |
| Blocks/day | 144 | 5,760 | 2,880 |
| Diff adjustment | 2016 blocks (~2 weeks) | Every block | 120 blocks (~1 hour) |
| Emission model | 50% halving every 4 years | 1% reduction monthly | 1% reduction monthly |
| Reduction interval | 210,000 blocks | 175,200 blocks | 87,600 blocks (30s) / 175,200 (15s) |
| Starting reward | 50 BTC | Variable | 2,397.26 RET (EXACT DGB) |
| Daily emission (initial) | 7,200 BTC | ~40M DGB | ~6.9M RET |
| Max supply | 21M BTC | 21B DGB | 21B RET |
| Full emission | ~140 years | 2035 | Asymptotic (~100+ years) |

## What's Next?

1. **Complete branding**: Search/replace "Bitcoin" → "Retardio" in all files
2. **Update GUI**: Modify Qt resources and strings
3. **Set up seeds**: Add DNS seed nodes once you have multiple nodes
4. **Add checkpoints**: Add checkpoints as chain matures
5. **Documentation**: Update README.md and other docs
6. **Testing**: Thoroughly test all consensus rules

For detailed information, see [RETARDIO_FORK_GUIDE.md](RETARDIO_FORK_GUIDE.md)
