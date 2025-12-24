#!/bin/bash
cd /mnt/c/Users/15187/retardio-coin/build/bin

# Create wallet if needed
./retardio-cli -datadir=/mnt/c/Users/15187/.retardio createwallet miner 2>/dev/null || true

# Get address
ADDRESS=$(./retardio-cli -datadir=/mnt/c/Users/15187/.retardio getnewaddress)
echo "Mining to address: $ADDRESS"
echo ""
echo "Mining 20 blocks to test DigiShield difficulty adjustment..."
echo "Expected: Blocks 1-15 should have stable difficulty, block 16+ should adjust per-block"
echo ""

for i in {1..20}; do
    echo -n "Block $i: "
    ./retardio-cli -datadir=/mnt/c/Users/15187/.retardio generatetoaddress 1 $ADDRESS > /dev/null 2>&1
    DIFF=$(./retardio-cli -datadir=/mnt/c/Users/15187/.retardio getdifficulty 2>/dev/null)
    BITS=$(./retardio-cli -datadir=/mnt/c/Users/15187/.retardio getblockheader $(./retardio-cli -datadir=/mnt/c/Users/15187/.retardio getbestblockhash) | grep '"bits"' | cut -d'"' -f4)
    echo "Difficulty=$DIFF, Bits=$BITS"
done

echo ""
echo "DigiShield test complete! Check if difficulty changed after block 15."
