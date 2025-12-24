# DigiShield Per-Block Difficulty Implementation for Retardio

## What is DigiShield?

**DigiShield** is DigiByte's difficulty adjustment algorithm that:
- ✅ Adjusts difficulty **every single block**
- ✅ Uses moving average of last 15 blocks
- ✅ Prevents difficulty manipulation
- ✅ Protects against hashrate spikes/drops
- ✅ Makes ASIC domination harder

## Implementation Plan

We need to modify `src/pow.cpp` to use DigiShield V3 algorithm.

### Current Bitcoin Behavior

```cpp
// Adjusts every 120 blocks (in our case)
if ((pindexLast->nHeight+1) % params.DifficultyAdjustmentInterval() != 0)
{
    return pindexLast->nBits;  // No change most of the time
}
```

### DigiShield Behavior

```cpp
// Adjusts EVERY block based on last 15 blocks
// Always recalculates difficulty
```

## Modified Code

Here's the complete implementation:

### File: src/pow.cpp

Replace the `GetNextWorkRequired` function:

```cpp
unsigned int GetNextWorkRequired(const CBlockIndex* pindexLast, const CBlockHeader *pblock, const Consensus::Params& params)
{
    assert(pindexLast != nullptr);
    unsigned int nProofOfWorkLimit = UintToArith256(params.powLimit).GetCompact();

    // Genesis block
    if (pindexLast == nullptr)
        return nProofOfWorkLimit;

    // DigiShield V3 - Per-block difficulty adjustment
    // Uses average of last 15 blocks
    const int nBlocksToAverage = 15;

    // Special case for first 15 blocks - use simple adjustment
    if (pindexLast->nHeight < nBlocksToAverage)
    {
        // For first few blocks, use standard Bitcoin adjustment
        // to establish initial difficulty
        if ((pindexLast->nHeight+1) % params.DifficultyAdjustmentInterval() != 0)
        {
            if (params.fPowAllowMinDifficultyBlocks)
            {
                if (pblock->GetBlockTime() > pindexLast->GetBlockTime() + params.nPowTargetSpacing*2)
                    return nProofOfWorkLimit;
                else
                {
                    const CBlockIndex* pindex = pindexLast;
                    while (pindex->pprev && pindex->nHeight % params.DifficultyAdjustmentInterval() != 0 && pindex->nBits == nProofOfWorkLimit)
                        pindex = pindex->pprev;
                    return pindex->nBits;
                }
            }
            return pindexLast->nBits;
        }

        int nHeightFirst = pindexLast->nHeight - (params.DifficultyAdjustmentInterval()-1);
        assert(nHeightFirst >= 0);
        const CBlockIndex* pindexFirst = pindexLast->GetAncestor(nHeightFirst);
        assert(pindexFirst);

        return CalculateNextWorkRequired(pindexLast, pindexFirst->GetBlockTime(), params);
    }

    // DigiShield V3: Calculate average of last 15 blocks
    int64_t nTotalTime = 0;
    const CBlockIndex* pindex = pindexLast;

    for (int i = 0; i < nBlocksToAverage && pindex && pindex->pprev; i++)
    {
        nTotalTime += pindex->GetBlockTime() - pindex->pprev->GetBlockTime();
        pindex = pindex->pprev;
    }

    // Get average time per block
    int64_t nAverageTime = nTotalTime / nBlocksToAverage;

    // Use the average to calculate new difficulty
    return CalculateNextWorkRequired_DigiShield(pindexLast, nAverageTime, params);
}
```

Add new function for DigiShield calculation:

```cpp
unsigned int CalculateNextWorkRequired_DigiShield(const CBlockIndex* pindexLast, int64_t nAverageTime, const Consensus::Params& params)
{
    if (params.fPowNoRetargeting)
        return pindexLast->nBits;

    const arith_uint256 bnPowLimit = UintToArith256(params.powLimit);
    arith_uint256 bnNew;
    bnNew.SetCompact(pindexLast->nBits);

    // DigiShield: Limit adjustment to prevent wild swings
    // Allow max 2x increase or 0.5x decrease per block
    int64_t nActualTime = nAverageTime;
    int64_t nTargetTime = params.nPowTargetSpacing;

    // Limit to 2x or 0.5x (less aggressive than Bitcoin's 4x)
    if (nActualTime < nTargetTime / 2)
        nActualTime = nTargetTime / 2;
    if (nActualTime > nTargetTime * 2)
        nActualTime = nTargetTime * 2;

    // Adjust difficulty
    bnNew *= nActualTime;
    bnNew /= nTargetTime;

    if (bnNew > bnPowLimit)
        bnNew = bnPowLimit;

    return bnNew.GetCompact();
}
```

Also need to add the function declaration to `src/pow.h`:

```cpp
/** DigiShield V3 difficulty adjustment */
unsigned int CalculateNextWorkRequired_DigiShield(const CBlockIndex* pindexLast, int64_t nAverageTime, const Consensus::Params& params);
```

## How It Works

### Every Block:

```
Block N arrives
   ↓
Look at last 15 blocks (N-1 to N-15)
   ↓
Calculate average time between blocks
   ↓
If average < 30s → Increase difficulty
If average > 30s → Decrease difficulty
   ↓
Limit adjustment to 2x max change
   ↓
Apply new difficulty to block N+1
```

### Example:

```
Last 15 blocks took:
  25s, 28s, 32s, 30s, 29s, 31s, 27s, 33s, 30s, 28s, 31s, 29s, 30s, 32s, 28s

Average: 30.2 seconds

Target: 30 seconds

Adjustment: Difficulty increases slightly (30.2/30 = 1.0067x)
```

## Effect on Different Miners

### ESP32 (5 KH/s):
- ✅ Benefits from quick difficulty drops when big miners leave
- ✅ Has chance to mine during low-diff windows
- ✅ Not overwhelmed by difficulty spikes

### Small GPU (10 MH/s):
- ✅ Stable mining experience
- ✅ Quick adaptation to hashrate changes
- ✅ Fair competition

### Large ASIC (1 TH/s):
- ❌ Can't manipulate difficulty by jumping on/off
- ❌ Difficulty adjusts before they can gain advantage
- ❌ Wasted hashpower on frequent difficulty changes
- ❌ Not profitable vs easier coins

## Additional Protection: Update chainparams.cpp

While we're implementing per-block difficulty, we should also update the confirmation window:

```cpp
// In chainparams.cpp around line 107
consensus.nMinerConfirmationWindow = 15;  // Match DigiShield averaging window
consensus.nRuleChangeActivationThreshold = 14; // 93% of 15
```

This doesn't affect difficulty but keeps BIP9 activation aligned with our new adjustment period.

## Testing Checklist

After implementing:

- [ ] Code compiles without errors
- [ ] Genesis block still validates
- [ ] Difficulty adjusts every block
- [ ] Difficulty doesn't swing wildly (max 2x per block)
- [ ] Average block time stabilizes around 30 seconds
- [ ] Small miners can find blocks
- [ ] ASIC jumping doesn't manipulate difficulty

## Comparison: Before vs After

### Before (Bitcoin-style):
```
Adjustment: Every 120 blocks (~1 hour)
ASIC attack: Join network → Mine 120 blocks at low diff → Leave
Result: ASIC gets unfair advantage
```

### After (DigiShield):
```
Adjustment: Every single block
ASIC attack: Join network → Difficulty rises immediately → Can't gain advantage
Result: Fair for all miners
```

## Files to Modify

1. **src/pow.cpp** - Main implementation
2. **src/pow.h** - Add function declaration
3. **src/kernel/chainparams.cpp** (optional) - Update confirmation window

## Build Commands

After making changes:

```bash
cd retardio-coin
make clean
make -j$(nproc)
```

## Want Me to Implement This Now?

I can:
1. ✅ Modify src/pow.cpp with DigiShield code
2. ✅ Update src/pow.h with declarations
3. ✅ Optionally update chainparams.cpp
4. ✅ Create test plan

Ready to proceed?
