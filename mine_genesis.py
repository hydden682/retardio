#!/usr/bin/env python3
"""
Genesis block miner for Retardio altcoin
This script will find the correct nonce for your genesis block

EXACT DigiByte emission: 2,397.26 RET starting reward, 1% reduction (12/year)
21 billion max supply (same as DigiByte)
"""

import hashlib
import struct
import time

def hash256(data):
    """Double SHA256 hash"""
    return hashlib.sha256(hashlib.sha256(data).digest()).digest()

def mine_genesis_block():
    """
    Mine the genesis block by finding a valid nonce
    """
    # Genesis block parameters
    version = 1
    prev_block = "00" * 32
    # Merkle root from the actual Retardio genesis transaction
    # This was calculated by the node's CreateGenesisBlock function
    merkle_root = "c7e816ed84ae0af8e2d447786bbd936ed7bb3e77294b05c9b6962d7a203282bc"
    timestamp = 1734566400  # December 18, 2024
    bits = 0x1e7fffff

    print("Mining genesis block for Retardio...")
    print("Emission: 2,397.26 RET starting, 12 reductions/year (EXACT DigiByte)")
    print("Max supply: 21 billion RET (same as DGB)")
    print(f"Target bits: 0x{bits:08x}")
    print(f"Timestamp: {timestamp}")
    print("")

    # Calculate target from bits
    # bits format: 0x1e0fffff means 0x0fffff * 2^(8*(0x1e-3))
    exponent = bits >> 24
    mantissa = bits & 0xffffff
    target = mantissa * (1 << (8 * (exponent - 3)))

    print(f"Target: {target:064x}")
    print("")

    nonce = 0
    start_time = time.time()

    while True:
        # Build block header
        header = struct.pack("<I", version)
        header += bytes.fromhex(prev_block)
        header += bytes.fromhex(merkle_root)[::-1]  # Reverse for little endian
        header += struct.pack("<I", timestamp)
        header += struct.pack("<I", bits)
        header += struct.pack("<I", nonce)

        # Hash the header
        hash_result = hash256(header)
        hash_int = int.from_bytes(hash_result[::-1], 'big')

        if hash_int <= target:
            print(f"\n>>> Found valid genesis block!")
            print(f"Nonce: {nonce}")
            print(f"Hash: {hash_result[::-1].hex()}")
            print(f"Time taken: {time.time() - start_time:.2f} seconds")
            print(f"\nUpdate chainparams.cpp genesis line to:")
            print(f"genesis = CreateGenesisBlock({timestamp}, {nonce}, 0x{bits:08x}, 1, 239726 * COIN / 100);")
            print(f"\nGenesis hash: {hash_result[::-1].hex()}")
            break

        nonce += 1

        if nonce % 100000 == 0:
            elapsed = time.time() - start_time
            hashrate = nonce / elapsed if elapsed > 0 else 0
            print(f"Nonce: {nonce:12d} | Hashrate: {hashrate:10.2f} H/s", end='\r')

if __name__ == "__main__":
    mine_genesis_block()
