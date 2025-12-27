#!/usr/bin/env python3
"""
Retardio Stratum Pool v5 - Alternative Byte Ordering
Trying: ntime/nonce as literal hex bytes (not integer conversion)
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

def merkle_root(coinbase_hash, tx_hashes):
    current = coinbase_hash
    for tx_hash in tx_hashes:
        tx_bytes = bytes.fromhex(tx_hash)[::-1]
        current = sha256d(current + tx_bytes)
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

        prevhash_rpc = template["previousblockhash"]
        prevhash_words = [prevhash_rpc[i:i+8] for i in range(0, 64, 8)]
        prevhash_stratum = "".join(prevhash_words[::-1])

        height = template["height"]
        reward = template["coinbasevalue"]
        height_script = serialize_height(height)
        scriptsig_len = len(height_script)//2 + 4 + self.extranonce2_size

        cb1 = "02000000" + "01" + "00"*32 + "ffffffff" + f"{scriptsig_len:02x}" + height_script
        cb2 = "ffffffff" + "01" + struct.pack("<Q", reward).hex() + "0151" + "00000000"

        version_le_hex = struct.pack("<I", template["version"]).hex()
        nbits = template["bits"]
        ntime = f"{template['curtime']:08x}"
        merkle_branches = [tx["txid"] for tx in template.get("transactions", [])]

        self.jobs[job_id] = {
            "template": template,
            "prevhash_rpc": prevhash_rpc,
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
            "params": [job_id, prevhash_stratum, cb1, cb2, merkle_branches, version_le_hex, nbits, ntime, clean]
        })
        print(f"[>] Job {job_id} sent (height={height})")

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

        # Build coinbase
        coinbase_hex = job["cb1"] + self.extranonce1 + extranonce2 + job["cb2"]
        coinbase_hash = sha256d(bytes.fromhex(coinbase_hex))

        # Merkle root
        mr = merkle_root(coinbase_hash, job["merkle_branches"])

        # Try MULTIPLE byte orderings for header fields
        print(f"\n    Testing different byte orderings...")

        # Fields that don't change
        version_bytes = struct.pack("<I", job["version"])
        prevhash_bytes = bytes.fromhex(job["prevhash_rpc"])[::-1]

        # Different interpretations of ntime
        ntime_as_int_le = struct.pack("<I", int(ntime_hex, 16))  # Original approach
        ntime_as_bytes = bytes.fromhex(ntime_hex)  # Direct hex bytes
        ntime_as_bytes_rev = bytes.fromhex(ntime_hex)[::-1]  # Reversed hex bytes

        # Different interpretations of nbits
        nbits_reversed = bytes.fromhex(job["nbits"])[::-1]  # Original approach
        nbits_direct = bytes.fromhex(job["nbits"])  # Direct

        # Different interpretations of nonce
        nonce_as_int_le = struct.pack("<I", int(nonce_hex, 16))  # Original approach
        nonce_as_bytes = bytes.fromhex(nonce_hex)  # Direct hex bytes
        nonce_as_bytes_rev = bytes.fromhex(nonce_hex)[::-1]  # Reversed hex bytes

        target_int = int(job["target"], 16)
        best_hash = None
        best_leading_zeros = 0
        best_config = None

        # Try all combinations
        configs = [
            ("int_le/rev/int_le", ntime_as_int_le, nbits_reversed, nonce_as_int_le),
            ("int_le/rev/direct", ntime_as_int_le, nbits_reversed, nonce_as_bytes),
            ("int_le/rev/rev", ntime_as_int_le, nbits_reversed, nonce_as_bytes_rev),
            ("int_le/direct/int_le", ntime_as_int_le, nbits_direct, nonce_as_int_le),
            ("int_le/direct/direct", ntime_as_int_le, nbits_direct, nonce_as_bytes),
            ("int_le/direct/rev", ntime_as_int_le, nbits_direct, nonce_as_bytes_rev),
            ("direct/rev/int_le", ntime_as_bytes, nbits_reversed, nonce_as_int_le),
            ("direct/rev/direct", ntime_as_bytes, nbits_reversed, nonce_as_bytes),
            ("direct/rev/rev", ntime_as_bytes, nbits_reversed, nonce_as_bytes_rev),
            ("direct/direct/int_le", ntime_as_bytes, nbits_direct, nonce_as_int_le),
            ("direct/direct/direct", ntime_as_bytes, nbits_direct, nonce_as_bytes),
            ("direct/direct/rev", ntime_as_bytes, nbits_direct, nonce_as_bytes_rev),
            ("rev/rev/int_le", ntime_as_bytes_rev, nbits_reversed, nonce_as_int_le),
            ("rev/rev/direct", ntime_as_bytes_rev, nbits_reversed, nonce_as_bytes),
            ("rev/rev/rev", ntime_as_bytes_rev, nbits_reversed, nonce_as_bytes_rev),
            ("rev/direct/int_le", ntime_as_bytes_rev, nbits_direct, nonce_as_int_le),
            ("rev/direct/direct", ntime_as_bytes_rev, nbits_direct, nonce_as_bytes),
            ("rev/direct/rev", ntime_as_bytes_rev, nbits_direct, nonce_as_bytes_rev),
        ]

        for config_name, ntime_b, nbits_b, nonce_b in configs:
            header = version_bytes + prevhash_bytes + mr + ntime_b + nbits_b + nonce_b
            block_hash = sha256d(header)
            hash_display = block_hash[::-1].hex()

            # Count leading zeros
            leading_zeros = len(hash_display) - len(hash_display.lstrip('0'))

            if leading_zeros > best_leading_zeros:
                best_leading_zeros = leading_zeros
                best_hash = hash_display
                best_config = config_name

            hash_int = int(hash_display, 16)
            if hash_int < target_int:
                print(f"\n[!!!] BLOCK FOUND with config: {config_name}")
                print(f"      Hash: {hash_display}")

                # Build and submit block
                block_hex = header.hex()
                tx_count = 1 + len(template.get("transactions", []))
                block_hex += f"{tx_count:02x}" if tx_count < 0xFD else f"fd{tx_count:04x}"
                block_hex += coinbase_hex
                for tx in template.get("transactions", []):
                    block_hex += tx["data"]

                result = rpc("submitblock", block_hex)
                if result is None or result == "":
                    print(f"[***] BLOCK ACCEPTED!")
                else:
                    print(f"[!!!] Rejected: {result}")

        print(f"\n    Best config: {best_config}")
        print(f"    Best hash:   {best_hash}")
        print(f"    Leading 0s:  {best_leading_zeros}")
        print(f"    Target:      {job['target'][:20]}...")
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
    print("  RETARDIO POOL v5 - Testing All Byte Orderings")
    print("=" * 60)

    info = rpc("getblockchaininfo")
    if not info:
        print("ERROR: Cannot connect to node!")
        return

    print(f"Node: Block {info['blocks']}, Diff {info['difficulty']:.6f}")
    print(f"Port: 3333")
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
