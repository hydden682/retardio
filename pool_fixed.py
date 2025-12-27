#!/usr/bin/env python3
"""
Retardio Stratum Pool - Fixed Block Submission
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

def hex_reverse(h):
    """Reverse byte order of hex string"""
    return bytes.fromhex(h)[::-1].hex()

def merkle_root(coinbase_hash, tx_hashes):
    """Calculate merkle root from coinbase and transaction hashes"""
    # Start with coinbase hash (already in internal byte order)
    current = coinbase_hash

    for tx_hash in tx_hashes:
        # tx_hash from getblocktemplate is in RPC byte order, reverse it
        tx_bytes = bytes.fromhex(tx_hash)[::-1]
        # Concatenate and hash
        current = sha256d(current + tx_bytes)

    return current

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

        # Previous block hash - for stratum, reverse each 4-byte word
        prevhash = template["previousblockhash"]
        prevhash_words = [prevhash[i:i+8] for i in range(0, 64, 8)]
        prevhash_stratum = "".join(prevhash_words[::-1])

        # Build coinbase transaction
        height = template["height"]
        reward = template["coinbasevalue"]

        # Coinbase scriptSig: height in script number format
        if height < 17:
            height_script = f"{0x50 + height:02x}"
        elif height < 128:
            height_script = f"01{height:02x}"
        elif height < 32768:
            height_script = f"02{height & 0xFF:02x}{(height >> 8) & 0xFF:02x}"
        else:
            height_bytes = height.to_bytes((height.bit_length() + 7) // 8, 'little')
            height_script = f"{len(height_bytes):02x}{height_bytes.hex()}"

        # Coinbase part 1: version + inputs + scriptsig prefix
        cb1 = "02000000"  # version 2
        cb1 += "01"  # 1 input
        cb1 += "00" * 32  # null txid
        cb1 += "ffffffff"  # vout
        # scriptsig length placeholder - will include height + extranonce1 + extranonce2
        scriptsig_len = len(height_script)//2 + 4 + self.extranonce2_size
        cb1 += f"{scriptsig_len:02x}"
        cb1 += height_script

        # Coinbase part 2: sequence + outputs + locktime
        cb2 = "ffffffff"  # sequence
        cb2 += "01"  # 1 output
        cb2 += struct.pack("<Q", reward).hex()  # value
        # P2PKH output to pool address (simplified - just use OP_TRUE for testing)
        cb2 += "0151"  # OP_TRUE (anyone can spend - for testing)
        cb2 += "00000000"  # locktime

        # Version in little-endian hex
        version_hex = struct.pack("<I", template["version"]).hex()

        # Bits and time
        nbits = template["bits"]
        ntime = f"{template['curtime']:08x}"

        # Merkle branches (transaction txids)
        merkle_branches = [tx["txid"] for tx in template.get("transactions", [])]

        # Store job info
        self.jobs[job_id] = {
            "template": template,
            "prevhash": prevhash,
            "cb1": cb1,
            "cb2": cb2,
            "merkle_branches": merkle_branches,
            "version": template["version"],
            "nbits": nbits,
            "ntime": template["curtime"],
            "target": template["target"]
        }
        self.current_job = job_id

        # Send job to miner
        await self.send({
            "id": None,
            "method": "mining.notify",
            "params": [
                job_id,           # job_id
                prevhash_stratum, # prevhash (word-reversed)
                cb1,              # coinbase1
                cb2,              # coinbase2
                merkle_branches,  # merkle branches
                version_hex,      # version (little-endian hex)
                nbits,            # nbits
                ntime,            # ntime
                clean             # clean_jobs
            ]
        })

        print(f"[>] Job {job_id} to {self.worker_name} (height={height}, diff={template['difficulty']:.6f})")

    async def handle_submit(self, msg_id, params):
        """Handle share submission from miner"""
        if len(params) < 5:
            await self.send({"id": msg_id, "result": False, "error": [20, "Invalid params", None]})
            return

        worker, job_id, extranonce2, ntime_hex, nonce_hex = params[:5]

        print(f"\n[*] SHARE from {worker}")
        print(f"    job_id: {job_id}")
        print(f"    extranonce2: {extranonce2}")
        print(f"    ntime: {ntime_hex}")
        print(f"    nonce: {nonce_hex}")

        if job_id not in self.jobs:
            print(f"[-] Job {job_id} not found")
            await self.send({"id": msg_id, "result": False, "error": [21, "Job not found", None]})
            return

        job = self.jobs[job_id]
        template = job["template"]

        # Reconstruct coinbase transaction
        coinbase_hex = job["cb1"] + self.extranonce1 + extranonce2 + job["cb2"]
        coinbase_bin = bytes.fromhex(coinbase_hex)
        coinbase_hash = sha256d(coinbase_bin)

        print(f"    coinbase_hash: {coinbase_hash[::-1].hex()}")

        # Calculate merkle root
        mr = merkle_root(coinbase_hash, job["merkle_branches"])

        print(f"    merkle_root: {mr[::-1].hex()}")

        # Build block header (80 bytes)
        # All fields in little-endian as they appear in the actual block
        header = b""
        header += struct.pack("<I", job["version"])  # version (4 bytes LE)
        header += bytes.fromhex(job["prevhash"])[::-1]  # prevhash (32 bytes, reversed)
        header += mr  # merkle root (32 bytes, as computed)
        header += struct.pack("<I", int(ntime_hex, 16))  # ntime (4 bytes LE)
        header += bytes.fromhex(job["nbits"])[::-1]  # nbits (4 bytes, reversed)
        header += struct.pack("<I", int(nonce_hex, 16))  # nonce (4 bytes LE)

        print(f"    header_hex: {header.hex()}")

        # Hash the header
        block_hash = sha256d(header)
        block_hash_hex = block_hash[::-1].hex()  # Display format (big-endian)

        print(f"    block_hash: {block_hash_hex}")
        print(f"    target:     {job['target']}")

        # Check if hash meets target
        hash_int = int(block_hash_hex, 16)
        target_int = int(job["target"], 16)

        if hash_int < target_int:
            print(f"\n[!!!] BLOCK FOUND!")
            print(f"      Hash:   {block_hash_hex}")
            print(f"      Height: {template['height']}")

            # Build full block for submission
            block_hex = header.hex()

            # Add transaction count
            tx_count = 1 + len(template.get("transactions", []))
            if tx_count < 0xFD:
                block_hex += f"{tx_count:02x}"
            elif tx_count <= 0xFFFF:
                block_hex += f"fd{tx_count:04x}"
            else:
                block_hex += f"fe{tx_count:08x}"

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
                # Send new job immediately
                await self.send_job(clean=True)
            else:
                print(f"[!!!] Block rejected: {result}")
        else:
            # Share doesn't meet block target, but accept it anyway
            diff_ratio = target_int / max(hash_int, 1)
            print(f"    share_diff: {diff_ratio:.6f} (need: 1.0)")

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
    print("  RETARDIO STRATUM POOL - Block Submission Fixed")
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
    print(f"Connect miners to: stratum+tcp://192.168.1.200:{POOL_PORT}")
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
