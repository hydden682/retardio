#!/usr/bin/env python3
"""
Retardio Stratum Pool v6 - FIXED byte ordering based on NightMiner research
Key fix: version sent as big-endian hex (stratum standard)
"""

import asyncio
import json
import hashlib
import struct
import time
import subprocess

# Configuration
RPC_CLI = "/home/hydden682/retardio-coin/build/bin/retardio-cli"
DATA_DIR = "/home/hydden682/.retardio/data"
POOL_PORT = 3333

miners = {}
extranonce_counter = 0

def rpc(method, *args):
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
    return hashlib.sha256(hashlib.sha256(data).digest()).digest()

def swap_endian_word(hex_word):
    """Swap endianness of a 4-byte hex word (like NightMiner does)"""
    return bytes.fromhex(hex_word)[::-1]

def swap_endian_words(hex_words):
    """Swap endianness of each 4-byte chunk in a hex string"""
    data = bytes.fromhex(hex_words)
    result = b''
    for i in range(0, len(data), 4):
        result += data[i:i+4][::-1]
    return result

def merkle_root(coinbase_hash, branches):
    """Calculate merkle root - branches used directly (no reversal)"""
    current = coinbase_hash
    for branch in branches:
        # Branches are used directly as NightMiner does (no byte reversal)
        current = sha256d(current + bytes.fromhex(branch))
    return current

def serialize_height(height):
    if height == 0:
        return "00"
    elif height >= 1 and height <= 16:
        return f"{0x50 + height:02x}"
    elif height < 128:
        return f"01{height:02x}"
    elif height < 32768:
        return f"02{height & 0xff:02x}{(height >> 8) & 0xff:02x}"
    else:
        return f"03{height & 0xff:02x}{(height >> 8) & 0xff:02x}{(height >> 16) & 0xff:02x}"

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

    async def send(self, data):
        msg = json.dumps(data) + "\n"
        self.writer.write(msg.encode())
        await self.writer.drain()

    async def send_difficulty(self):
        await self.send({"id": None, "method": "mining.set_difficulty", "params": [self.difficulty]})

    async def send_job(self, clean=True):
        template = rpc("getblocktemplate", '{"rules":["segwit"]}')
        if not template:
            print("[-] Failed to get block template")
            return

        job_id = f"{int(time.time()) & 0xFFFFFFFF:08x}"

        # Prevhash: stratum format = swap word order of RPC hash
        prevhash_rpc = template["previousblockhash"]
        prevhash_words = [prevhash_rpc[i:i+8] for i in range(0, 64, 8)]
        prevhash_stratum = "".join(prevhash_words[::-1])

        height = template["height"]
        reward = template["coinbasevalue"]
        height_script = serialize_height(height)
        scriptsig_len = len(height_script)//2 + 4 + self.extranonce2_size

        cb1 = "02000000" + "01" + "00"*32 + "ffffffff" + f"{scriptsig_len:02x}" + height_script
        cb2 = "ffffffff" + "01" + struct.pack("<Q", reward).hex() + "0151" + "00000000"

        # VERSION: Send as BIG-ENDIAN hex (stratum standard!)
        # Miner will swap_endian_word() to get correct LE bytes
        version_be_hex = f"{template['version']:08x}"

        # NBITS: Send as-is from template (BE hex string)
        nbits = template["bits"]

        # NTIME: Send as BE hex of timestamp
        ntime = f"{template['curtime']:08x}"

        # Merkle branches: txids from template (will be used directly by miner)
        merkle_branches = [tx["txid"] for tx in template.get("transactions", [])]

        self.jobs[job_id] = {
            "template": template,
            "prevhash_stratum": prevhash_stratum,
            "cb1": cb1,
            "cb2": cb2,
            "merkle_branches": merkle_branches,
            "version": template["version"],
            "nbits": nbits,
            "target": template["target"]
        }

        await self.send({
            "id": None,
            "method": "mining.notify",
            "params": [job_id, prevhash_stratum, cb1, cb2, merkle_branches, version_be_hex, nbits, ntime, clean]
        })
        print(f"[>] Job {job_id} sent (height={height}, ver={version_be_hex})")

    async def handle_submit(self, msg_id, params):
        if len(params) < 5:
            await self.send({"id": msg_id, "result": False, "error": [20, "Invalid params", None]})
            return

        worker, job_id, extranonce2, ntime_hex, nonce_hex = params[:5]

        print(f"\n{'='*60}")
        print(f"[*] SHARE from {worker}")
        print(f"    ntime={ntime_hex} nonce={nonce_hex}")

        if job_id not in self.jobs:
            print(f"[-] Job {job_id} not found")
            await self.send({"id": msg_id, "result": False, "error": [21, "Job not found", None]})
            return

        job = self.jobs[job_id]
        template = job["template"]

        # === BUILD COINBASE ===
        coinbase_hex = job["cb1"] + self.extranonce1 + extranonce2 + job["cb2"]
        coinbase_hash = sha256d(bytes.fromhex(coinbase_hex))
        print(f"    coinbase_txid: {coinbase_hash[::-1].hex()}")

        # === MERKLE ROOT ===
        mr = merkle_root(coinbase_hash, job["merkle_branches"])
        print(f"    merkle_root:   {mr[::-1].hex()}")

        # === BUILD HEADER (80 bytes) ===
        # Each field uses swap_endian_word/swap_endian_words like miners do

        # Version: swap the BE hex we stored (or just pack the int as LE)
        version_bytes = struct.pack("<I", job["version"])

        # Prevhash: swap_endian_words on stratum format
        prevhash_bytes = swap_endian_words(job["prevhash_stratum"])

        # Merkle root: used as-is (internal byte order from sha256d)
        merkle_bytes = mr

        # nTime: swap the BE hex string from miner
        ntime_bytes = swap_endian_word(ntime_hex)

        # nBits: swap the BE hex string
        nbits_bytes = swap_endian_word(job["nbits"])

        # Nonce: miner sends in reversed format, swap it back
        nonce_bytes = swap_endian_word(nonce_hex)

        header = version_bytes + prevhash_bytes + merkle_bytes + ntime_bytes + nbits_bytes + nonce_bytes

        print(f"    header ({len(header)}B): {header[:20].hex()}...{header[-8:].hex()}")

        # === HASH THE HEADER ===
        block_hash = sha256d(header)
        hash_display = block_hash[::-1].hex()

        # Count leading zeros
        leading_zeros = len(hash_display) - len(hash_display.lstrip('0'))
        print(f"    hash:          {hash_display}")
        print(f"    leading_zeros: {leading_zeros}")
        print(f"    target:        {job['target'][:16]}...")

        # === CHECK TARGET ===
        hash_int = int(hash_display, 16)
        target_int = int(job["target"], 16)

        if hash_int < target_int:
            print(f"\n[!!!] BLOCK FOUND!")

            # Build full block
            block_hex = header.hex()
            tx_count = 1 + len(template.get("transactions", []))
            if tx_count < 0xFD:
                block_hex += f"{tx_count:02x}"
            else:
                block_hex += f"fd{tx_count & 0xff:02x}{(tx_count >> 8) & 0xff:02x}"
            block_hex += coinbase_hex
            for tx in template.get("transactions", []):
                block_hex += tx["data"]

            result = rpc("submitblock", block_hex)
            if result is None or result == "":
                print(f"[***] BLOCK ACCEPTED! Height {template['height']}")
                await self.send_job(clean=True)
            else:
                print(f"[!!!] Rejected: {result}")
        else:
            share_diff = target_int / max(hash_int, 1)
            print(f"    share_diff:    {share_diff:.6f}")

        print(f"{'='*60}\n")
        await self.send({"id": msg_id, "result": True, "error": None})

    async def handle(self):
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
                            "result": [[["mining.set_difficulty", "1"], ["mining.notify", "1"]], self.extranonce1, self.extranonce2_size],
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
                        await self.send_difficulty()
                    elif method == "mining.extranonce.subscribe":
                        await self.send({"id": msg_id, "result": True, "error": None})
                except Exception as e:
                    print(f"[-] Error: {e}")
                    import traceback
                    traceback.print_exc()
        except Exception as e:
            print(f"[-] Connection error: {e}")
        finally:
            if self.worker_name and self.worker_name in miners:
                del miners[self.worker_name]
            print(f"[-] Disconnected: {self.worker_name or self.address}")

async def job_broadcaster():
    while True:
        await asyncio.sleep(30)
        for miner in list(miners.values()):
            try:
                await miner.send_job(clean=False)
            except:
                pass

async def main():
    print("=" * 60)
    print("  RETARDIO POOL v6 - Fixed Byte Ordering")
    print("  Based on NightMiner stratum implementation")
    print("=" * 60)

    info = rpc("getblockchaininfo")
    if not info:
        print("ERROR: Cannot connect to node!")
        return

    print(f"Node: Block {info['blocks']}, Diff {info['difficulty']:.6f}")
    print(f"Port: {POOL_PORT}")
    print("=" * 60)

    server = await asyncio.start_server(lambda r, w: StratumMiner(r, w).handle(), '0.0.0.0', POOL_PORT)
    asyncio.create_task(job_broadcaster())

    async with server:
        await server.serve_forever()

if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        print("\nPool stopped.")
