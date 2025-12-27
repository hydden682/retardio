#!/usr/bin/env python3
"""
Retardio Pool - DEBUG VERSION
Logs ALL raw messages between pool and miners
"""

import asyncio
import json
import hashlib
import struct
import time
import subprocess

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
    return bytes.fromhex(hex_word)[::-1]

def swap_endian_words(hex_words):
    data = bytes.fromhex(hex_words)
    result = b''
    for i in range(0, len(data), 4):
        result += data[i:i+4][::-1]
    return result

def merkle_root(coinbase_hash, branches):
    current = coinbase_hash
    for branch in branches:
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
        self.difficulty = 0.001  # Very low difficulty
        self.jobs = {}
        self.id = extranonce_counter

    async def send(self, data):
        msg = json.dumps(data) + "\n"
        print(f"    [SEND -> miner{self.id}] {msg.strip()}")
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

        # Try LITTLE-ENDIAN version (what we had before that worked for getting shares)
        version_le_hex = struct.pack("<I", template["version"]).hex()

        nbits = template["bits"]
        ntime = f"{template['curtime']:08x}"
        merkle_branches = [tx["txid"] for tx in template.get("transactions", [])]

        self.jobs[job_id] = {
            "template": template,
            "prevhash_stratum": prevhash_stratum,
            "prevhash_rpc": prevhash_rpc,
            "cb1": cb1,
            "cb2": cb2,
            "merkle_branches": merkle_branches,
            "version": template["version"],
            "version_hex": version_le_hex,
            "nbits": nbits,
            "ntime": ntime,
            "target": template["target"]
        }

        print(f"\n[JOB {job_id}] height={height}")
        print(f"    version_hex: {version_le_hex}")
        print(f"    prevhash:    {prevhash_stratum[:32]}...")
        print(f"    nbits:       {nbits}")
        print(f"    ntime:       {ntime}")

        await self.send({
            "id": None,
            "method": "mining.notify",
            "params": [job_id, prevhash_stratum, cb1, cb2, merkle_branches, version_le_hex, nbits, ntime, clean]
        })

    async def handle_submit(self, msg_id, params):
        print(f"\n{'='*60}")
        print(f"[SHARE RECEIVED] params: {params}")

        if len(params) < 5:
            await self.send({"id": msg_id, "result": False, "error": [20, "Invalid params", None]})
            return

        worker, job_id, extranonce2, ntime_hex, nonce_hex = params[:5]

        print(f"    worker:      {worker}")
        print(f"    job_id:      {job_id}")
        print(f"    extranonce2: {extranonce2}")
        print(f"    ntime:       {ntime_hex}")
        print(f"    nonce:       {nonce_hex}")

        if job_id not in self.jobs:
            print(f"[-] Job {job_id} not found!")
            print(f"    Available jobs: {list(self.jobs.keys())}")
            await self.send({"id": msg_id, "result": False, "error": [21, "Job not found", None]})
            return

        job = self.jobs[job_id]
        template = job["template"]

        # Build coinbase
        coinbase_hex = job["cb1"] + self.extranonce1 + extranonce2 + job["cb2"]
        coinbase_hash = sha256d(bytes.fromhex(coinbase_hex))

        # Merkle root
        mr = merkle_root(coinbase_hash, job["merkle_branches"])

        # Try multiple header constructions and show results
        print(f"\n    [Testing byte orderings...]")

        target_int = int(job["target"], 16)

        # Method 1: Original (v4 style) - int conversion
        version_b = struct.pack("<I", job["version"])
        prevhash_b = bytes.fromhex(job["prevhash_rpc"])[::-1]
        ntime_b1 = struct.pack("<I", int(ntime_hex, 16))
        nbits_b1 = bytes.fromhex(job["nbits"])[::-1]
        nonce_b1 = struct.pack("<I", int(nonce_hex, 16))

        header1 = version_b + prevhash_b + mr + ntime_b1 + nbits_b1 + nonce_b1
        hash1 = sha256d(header1)[::-1].hex()
        zeros1 = len(hash1) - len(hash1.lstrip('0'))

        # Method 2: swap_endian style
        prevhash_b2 = swap_endian_words(job["prevhash_stratum"])
        ntime_b2 = swap_endian_word(ntime_hex)
        nbits_b2 = swap_endian_word(job["nbits"])
        nonce_b2 = swap_endian_word(nonce_hex)

        header2 = version_b + prevhash_b2 + mr + ntime_b2 + nbits_b2 + nonce_b2
        hash2 = sha256d(header2)[::-1].hex()
        zeros2 = len(hash2) - len(hash2.lstrip('0'))

        # Method 3: Direct bytes (no conversion)
        ntime_b3 = bytes.fromhex(ntime_hex)
        nbits_b3 = bytes.fromhex(job["nbits"])
        nonce_b3 = bytes.fromhex(nonce_hex)

        header3 = version_b + prevhash_b + mr + ntime_b3 + nbits_b3 + nonce_b3
        hash3 = sha256d(header3)[::-1].hex()
        zeros3 = len(hash3) - len(hash3.lstrip('0'))

        print(f"    Method1 (int+LE):    zeros={zeros1} hash={hash1[:16]}...")
        print(f"    Method2 (swap):      zeros={zeros2} hash={hash2[:16]}...")
        print(f"    Method3 (direct):    zeros={zeros3} hash={hash3[:16]}...")
        print(f"    Target:              {job['target'][:16]}...")

        best_zeros = max(zeros1, zeros2, zeros3)
        print(f"    BEST: {best_zeros} leading zeros")

        # Check if any method found a block
        for name, h, header in [("Method1", hash1, header1), ("Method2", hash2, header2), ("Method3", hash3, header3)]:
            if int(h, 16) < target_int:
                print(f"\n[!!!] BLOCK FOUND with {name}!")
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

        print(f"{'='*60}\n")
        await self.send({"id": msg_id, "result": True, "error": None})

    async def handle(self):
        print(f"\n[+] Connection from {self.address} (miner{self.id})")
        try:
            while True:
                line = await self.reader.readline()
                if not line:
                    break

                raw = line.decode().strip()
                print(f"    [RECV <- miner{self.id}] {raw}")

                try:
                    msg = json.loads(raw)
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
                    else:
                        print(f"    [?] Unknown method: {method}")
                except Exception as e:
                    print(f"[-] Error: {e}")
                    import traceback
                    traceback.print_exc()
        except Exception as e:
            print(f"[-] Connection error: {e}")
        finally:
            if self.worker_name and self.worker_name in miners:
                del miners[self.worker_name]
            print(f"[-] Disconnected: miner{self.id}")

async def main():
    print("=" * 60)
    print("  RETARDIO POOL - DEBUG MODE")
    print("  All messages logged")
    print("=" * 60)

    info = rpc("getblockchaininfo")
    if not info:
        print("ERROR: Cannot connect to node!")
        return

    print(f"Node: Block {info['blocks']}, Diff {info['difficulty']:.6f}")
    print(f"Port: {POOL_PORT}")
    print("=" * 60)

    server = await asyncio.start_server(lambda r, w: StratumMiner(r, w).handle(), '0.0.0.0', POOL_PORT)

    async with server:
        await server.serve_forever()

if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        print("\nPool stopped.")
