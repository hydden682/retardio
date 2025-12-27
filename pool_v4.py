#!/usr/bin/env python3
"""
Retardio Stratum Pool v4 - Corrected Byte Ordering
"""

import asyncio
import json
import hashlib
import struct
import time
import subprocess
import binascii

# Configuration - UPDATE THESE FOR YOUR SETUP
RPC_CLI = "/home/hydden682/retardio-coin/build/bin/retardio-cli"
DATA_DIR = "/home/hydden682/.retardio/data"
POOL_PORT = 3333
POOL_ADDRESS = "FMm2c4tBkbGphXx9JtndkbcnKSr1BSfnzu"

miners = {}
extranonce_counter = 0

def rpc(method, *args):
    """Call retardio-cli"""
    try:
        cmd = [RPC_CLI, f"-datadir={DATA_DIR}", method] + [str(a) for a in args]
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=30)
        if result.returncode == 0 and result.stdout.strip():
            try:
                return json.loads(result.stdout)
            except:
                return result.stdout.strip()
        return None
    except Exception as e:
        print(f"RPC Error: {e}")
        return None

def sha256d(data):
    """Double SHA256"""
    return hashlib.sha256(hashlib.sha256(data).digest()).digest()

def merkle_root(coinbase_hash, tx_hashes):
    """Calculate merkle root from coinbase and transaction hashes"""
    current = coinbase_hash
    for tx_hash in tx_hashes:
        # tx_hash from getblocktemplate is in RPC byte order, reverse it
        tx_bytes = bytes.fromhex(tx_hash)[::-1]
        current = sha256d(current + tx_bytes)
    return current

def serialize_height(height):
    """Serialize block height for coinbase scriptsig (BIP34)"""
    if height == 0:
        return "00"  # OP_0
    elif height >= 1 and height <= 16:
        return f"{0x50 + height:02x}"  # OP_1 through OP_16
    elif height < 128:
        return f"01{height:02x}"  # push 1 byte
    elif height < 32768:
        # Need 2 bytes, little-endian
        return f"02{height & 0xff:02x}{(height >> 8) & 0xff:02x}"
    elif height < 8388608:
        # Need 3 bytes
        return f"03{height & 0xff:02x}{(height >> 8) & 0xff:02x}{(height >> 16) & 0xff:02x}"
    else:
        # Need 4 bytes
        return f"04{height & 0xff:02x}{(height >> 8) & 0xff:02x}{(height >> 16) & 0xff:02x}{(height >> 24) & 0xff:02x}"

class StratumMiner:
    def __init__(self, reader, writer):
        global extranonce_counter
        self.reader = reader
        self.writer = writer
        self.address = writer.get_extra_info('peername')
        extranonce_counter += 1
        self.extranonce1 = f"{extranonce_counter:08x}"
        self.extranonce2_size = 4
        self.worker_name = None
        self.difficulty = 1
        self.jobs = {}
        self.current_job = None

    async def send(self, data):
        """Send JSON message to miner"""
        msg = json.dumps(data) + "\n"
        self.writer.write(msg.encode())
        await self.writer.drain()

    async def send_difficulty(self):
        """Send mining.set_difficulty"""
        await self.send({
            "id": None,
            "method": "mining.set_difficulty",
            "params": [self.difficulty]
        })

    async def send_job(self, clean=True):
        """Send mining.notify with new job"""
        template = rpc("getblocktemplate", '{"rules":["segwit"]}')
        if not template:
            print("[-] Failed to get block template")
            return

        job_id = f"{int(time.time()) & 0xFFFFFFFF:08x}"

        # Previous block hash handling for stratum
        # RPC gives hash in "display" order (big-endian)
        # Stratum expects it with 4-byte words reversed
        prevhash_rpc = template["previousblockhash"]
        prevhash_words = [prevhash_rpc[i:i+8] for i in range(0, 64, 8)]
        prevhash_stratum = "".join(prevhash_words[::-1])

        height = template["height"]
        reward = template["coinbasevalue"]

        # Build coinbase scriptsig content
        height_script = serialize_height(height)

        # extranonce1 is 4 bytes, extranonce2 is 4 bytes = 8 bytes total
        scriptsig_len = len(height_script)//2 + 4 + self.extranonce2_size

        # Coinbase part 1: version through scriptsig (before extranonce)
        cb1 = "02000000"  # version 2, LE
        cb1 += "01"  # 1 input
        cb1 += "00" * 32  # null txid
        cb1 += "ffffffff"  # vout index (0xffffffff for coinbase)
        cb1 += f"{scriptsig_len:02x}"  # scriptsig length
        cb1 += height_script  # height (BIP34)

        # Coinbase part 2: sequence through locktime (after extranonce)
        cb2 = "ffffffff"  # sequence
        cb2 += "01"  # 1 output
        cb2 += struct.pack("<Q", reward).hex()  # value in satoshis, LE
        cb2 += "0151"  # scriptpubkey: [len=1][OP_TRUE=0x51]
        cb2 += "00000000"  # locktime

        # Version for stratum: little-endian hex representation
        version_le_hex = struct.pack("<I", template["version"]).hex()

        # nBits stays as-is (it's already the hex representation)
        nbits = template["bits"]

        # nTime as hex (big-endian representation of the integer)
        ntime = f"{template['curtime']:08x}"

        # Merkle branches (transaction txids from template)
        merkle_branches = [tx["txid"] for tx in template.get("transactions", [])]

        # Store job info for later verification
        self.jobs[job_id] = {
            "template": template,
            "prevhash_rpc": prevhash_rpc,  # Original RPC format
            "cb1": cb1,
            "cb2": cb2,
            "merkle_branches": merkle_branches,
            "version": template["version"],
            "nbits": nbits,
            "ntime_int": template["curtime"],
            "target": template["target"]
        }
        self.current_job = job_id

        # Send job to miner
        await self.send({
            "id": None,
            "method": "mining.notify",
            "params": [
                job_id,
                prevhash_stratum,
                cb1,
                cb2,
                merkle_branches,
                version_le_hex,
                nbits,
                ntime,
                clean
            ]
        })

        print(f"[>] Job {job_id} to {self.worker_name} (height={height}, diff={template['difficulty']:.6f})")

    async def handle_submit(self, msg_id, params):
        """Handle share submission from miner"""
        if len(params) < 5:
            await self.send({"id": msg_id, "result": False, "error": [20, "Invalid params", None]})
            return

        worker, job_id, extranonce2, ntime_hex, nonce_hex = params[:5]

        print(f"\n{'='*60}")
        print(f"[*] SHARE RECEIVED from {worker}")
        print(f"    job_id:      {job_id}")
        print(f"    extranonce2: {extranonce2}")
        print(f"    ntime:       {ntime_hex}")
        print(f"    nonce:       {nonce_hex}")

        if job_id not in self.jobs:
            print(f"[-] Job {job_id} not found")
            await self.send({"id": msg_id, "result": False, "error": [21, "Job not found", None]})
            return

        job = self.jobs[job_id]
        template = job["template"]

        # === STEP 1: Reconstruct coinbase transaction ===
        coinbase_hex = job["cb1"] + self.extranonce1 + extranonce2 + job["cb2"]
        coinbase_bin = bytes.fromhex(coinbase_hex)
        coinbase_hash = sha256d(coinbase_bin)

        print(f"\n    [Coinbase]")
        print(f"    cb1:            {job['cb1']}")
        print(f"    extranonce1:    {self.extranonce1}")
        print(f"    extranonce2:    {extranonce2}")
        print(f"    cb2:            {job['cb2']}")
        print(f"    coinbase_hex:   {coinbase_hex[:60]}...")
        print(f"    coinbase_txid:  {coinbase_hash[::-1].hex()}")

        # === STEP 2: Calculate merkle root ===
        mr = merkle_root(coinbase_hash, job["merkle_branches"])
        print(f"\n    [Merkle Root]")
        print(f"    branches:       {len(job['merkle_branches'])} transactions")
        print(f"    merkle_root:    {mr[::-1].hex()} (display)")
        print(f"    merkle_root:    {mr.hex()} (internal)")

        # === STEP 3: Build block header (80 bytes) ===
        # The key insight: all fields in the header are in INTERNAL byte order
        # which means they need proper conversion from their stratum/RPC formats

        header = b""

        # Version: 4 bytes, little-endian
        version_bytes = struct.pack("<I", job["version"])
        header += version_bytes
        print(f"\n    [Header Fields]")
        print(f"    version:        {job['version']} -> {version_bytes.hex()}")

        # Previous block hash: 32 bytes, internal order (reverse of RPC display)
        prevhash_bytes = bytes.fromhex(job["prevhash_rpc"])[::-1]
        header += prevhash_bytes
        print(f"    prevhash_rpc:   {job['prevhash_rpc']}")
        print(f"    prevhash_int:   {prevhash_bytes.hex()}")

        # Merkle root: 32 bytes, internal order (as computed)
        header += mr
        print(f"    merkle_root:    {mr.hex()}")

        # nTime: 4 bytes, little-endian
        # The miner sends ntime as big-endian hex string representing the timestamp
        # We need to convert it to an integer and pack as little-endian
        ntime_int = int(ntime_hex, 16)
        ntime_bytes = struct.pack("<I", ntime_int)
        header += ntime_bytes
        print(f"    ntime_hex:      {ntime_hex} -> int {ntime_int} -> {ntime_bytes.hex()}")

        # nBits: 4 bytes, stored as-is in compact form (it's already LE in the template)
        # The template gives "bits" as a hex string like "1e0ffff0"
        # This IS the compact target in big-endian hex, needs to be reversed for header
        nbits_bytes = bytes.fromhex(job["nbits"])[::-1]
        header += nbits_bytes
        print(f"    nbits_hex:      {job['nbits']} -> {nbits_bytes.hex()}")

        # Nonce: 4 bytes, little-endian
        # The miner sends nonce as big-endian hex string
        nonce_int = int(nonce_hex, 16)
        nonce_bytes = struct.pack("<I", nonce_int)
        header += nonce_bytes
        print(f"    nonce_hex:      {nonce_hex} -> int {nonce_int} -> {nonce_bytes.hex()}")

        print(f"\n    [Complete Header]")
        print(f"    header ({len(header)} bytes): {header.hex()}")

        # === STEP 4: Hash the header ===
        block_hash = sha256d(header)
        block_hash_display = block_hash[::-1].hex()  # Reverse for display (RPC order)

        print(f"\n    [Block Hash]")
        print(f"    hash_internal:  {block_hash.hex()}")
        print(f"    hash_display:   {block_hash_display}")
        print(f"    target:         {job['target']}")

        # === STEP 5: Check if hash meets target ===
        hash_int = int(block_hash_display, 16)
        target_int = int(job["target"], 16)

        if hash_int < target_int:
            print(f"\n[!!!] BLOCK FOUND!")
            print(f"      Hash:   {block_hash_display}")
            print(f"      Height: {template['height']}")

            # Build full block for submission
            block_hex = header.hex()

            # Add transaction count (varint)
            tx_count = 1 + len(template.get("transactions", []))
            if tx_count < 0xFD:
                block_hex += f"{tx_count:02x}"
            elif tx_count <= 0xFFFF:
                block_hex += f"fd{tx_count & 0xff:02x}{(tx_count >> 8) & 0xff:02x}"
            else:
                block_hex += f"fe{tx_count & 0xff:02x}{(tx_count >> 8) & 0xff:02x}{(tx_count >> 16) & 0xff:02x}{(tx_count >> 24) & 0xff:02x}"

            # Add coinbase transaction
            block_hex += coinbase_hex

            # Add other transactions
            for tx in template.get("transactions", []):
                block_hex += tx["data"]

            print(f"      Submitting block ({len(block_hex)//2} bytes)...")

            # Submit to node
            result = rpc("submitblock", block_hex)

            if result is None or result == "":
                print(f"[***] BLOCK ACCEPTED! Height {template['height']}")
                await self.send_job(clean=True)
            else:
                print(f"[!!!] Block rejected: {result}")
        else:
            # Share doesn't meet block target
            diff_ratio = target_int / max(hash_int, 1)
            print(f"\n    [Share Result]")
            print(f"    share_diff:     {diff_ratio:.6f}")
            print(f"    need_diff:      1.0 (to find block)")

            # Check if hash starts with zeros (sanity check)
            leading_zeros = len(block_hash_display) - len(block_hash_display.lstrip('0'))
            print(f"    leading_zeros:  {leading_zeros}")

        print(f"{'='*60}\n")

        # Accept the share
        await self.send({"id": msg_id, "result": True, "error": None})

    async def handle(self):
        """Main connection handler"""
        print(f"[+] Connection from {self.address}")

        try:
            while True:
                line = await self.reader.readline()
                if not line:
                    break

                try:
                    msg = json.loads(line.decode().strip())
                    method = msg.get("method", "")
                    msg_id = msg.get("id")
                    params = msg.get("params", [])

                    if method == "mining.subscribe":
                        await self.send({
                            "id": msg_id,
                            "result": [
                                [["mining.set_difficulty", "1"], ["mining.notify", "1"]],
                                self.extranonce1,
                                self.extranonce2_size
                            ],
                            "error": None
                        })
                        await self.send_difficulty()

                    elif method == "mining.authorize":
                        self.worker_name = params[0] if params else "unknown"
                        miners[self.worker_name] = self
                        print(f"[+] Authorized: {self.worker_name}")
                        await self.send({"id": msg_id, "result": True, "error": None})
                        await self.send_job(clean=True)

                    elif method == "mining.submit":
                        await self.handle_submit(msg_id, params)

                    elif method == "mining.suggest_difficulty":
                        if params and params[0]:
                            self.difficulty = max(0.001, float(params[0]))
                        await self.send_difficulty()

                    elif method == "mining.extranonce.subscribe":
                        await self.send({"id": msg_id, "result": True, "error": None})

                    else:
                        print(f"[?] Unknown method: {method}")

                except json.JSONDecodeError as e:
                    print(f"[-] JSON error: {e}")
                except Exception as e:
                    print(f"[-] Handler error: {e}")
                    import traceback
                    traceback.print_exc()

        except Exception as e:
            print(f"[-] Connection error: {e}")
        finally:
            if self.worker_name and self.worker_name in miners:
                del miners[self.worker_name]
            print(f"[-] Disconnected: {self.worker_name or self.address}")

async def job_broadcaster():
    """Periodically send new jobs"""
    while True:
        await asyncio.sleep(30)
        for miner in list(miners.values()):
            try:
                await miner.send_job(clean=False)
            except:
                pass

async def main():
    print("=" * 60)
    print("  RETARDIO STRATUM POOL v4 - Corrected Byte Ordering")
    print("=" * 60)

    # Check node connection
    info = rpc("getblockchaininfo")
    if not info:
        print("ERROR: Cannot connect to node!")
        print(f"Check: {RPC_CLI} -datadir={DATA_DIR}")
        return

    print(f"Node connected - Block {info['blocks']}, Difficulty {info['difficulty']:.6f}")
    print(f"Pool Address: {POOL_ADDRESS}")
    print(f"Stratum Port: {POOL_PORT}")
    print("")
    print(f"Connect miners to: stratum+tcp://YOUR_IP:{POOL_PORT}")
    print("=" * 60)
    print("")

    # Start server
    server = await asyncio.start_server(
        lambda r, w: StratumMiner(r, w).handle(),
        '0.0.0.0', POOL_PORT
    )

    # Start job broadcaster
    asyncio.create_task(job_broadcaster())

    async with server:
        await server.serve_forever()

if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        print("\nPool stopped.")
