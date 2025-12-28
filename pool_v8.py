#!/usr/bin/env python3
"""
Retardio Stratum Pool v8.2 - TRUE SOLO POOL
- Each miner receives 100% of their block rewards directly
- Miner's address extracted from stratum worker name
- Configurable via environment variables
- Fixed BIP34 height encoding
"""

import asyncio
import json
import hashlib
import struct
import time
import subprocess
import urllib.request
import os
from datetime import datetime
from http.server import HTTPServer, BaseHTTPRequestHandler
import threading

# Configuration via environment variables with defaults
RPC_CLI = os.environ.get("RETARDIO_CLI", "/usr/local/bin/retardio-cli")
DATA_DIR = os.environ.get("RETARDIO_DATADIR", os.path.expanduser("~/.retardio/data"))
POOL_PORT = int(os.environ.get("POOL_PORT", "3333"))
POOL_UI_URL = os.environ.get("POOL_UI_URL", "http://127.0.0.1:5555")
POOL_UI_API_KEY = os.environ.get("POOL_UI_API_KEY", "")  # API key for pool UI authentication
POOL_STATS_PORT = int(os.environ.get("POOL_STATS_PORT", "3334"))

# Pool share difficulty - LOW for hobby miners to submit shares frequently
# This allows miners to see progress even if they never find a block
# Shares that meet network difficulty will be submitted as blocks
POOL_SHARE_DIFF = float(os.environ.get("POOL_SHARE_DIFF", "0.001"))

# Pool wallet address - OPTIONAL for solo pool
# In solo mode, miner's address is extracted from their worker name
# POOL_ADDRESS is only used as fallback if miner address is invalid
POOL_ADDRESS = os.environ.get("POOL_ADDRESS", "")

miners = {}
extranonce_counter = 0

# Session ID - unique per pool restart, used to identify stale jobs
SESSION_ID = f"{int(time.time()) & 0xFFFF:04x}"

# Worker statistics tracking
worker_stats = {}  # {worker_name: {best_diff, shares, connect_time, last_seen, hashrate}}

def extract_miner_address(worker_name):
    """
    Extract wallet address from miner's stratum worker name.
    Common formats:
      - FAddress (just the address)
      - FAddress.rig1 (address.worker_id)
      - FAddress/rig1 (address/worker_id)
    Returns the address if valid, None otherwise.
    """
    if not worker_name:
        return None

    # Extract address part (before . or /)
    address = worker_name.split('.')[0].split('/')[0].strip()

    # Validate it looks like a Retardio address
    # Must start with 'F' and be proper base58 length (26-35 chars typically)
    if not address.startswith('F') or len(address) < 25 or len(address) > 36:
        return None

    # Validate base58 characters
    ALPHABET = '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz'
    for char in address:
        if char not in ALPHABET:
            return None

    # Try to decode the address to verify checksum
    try:
        version, pubkey_hash = decode_address(address)
        # Check version byte (should be 0x23 = 35 for Retardio 'F' addresses)
        if version != 0x23:
            print(f"    [!] Warning: Address version {version} != expected 0x23")
        return address
    except (ValueError, Exception) as e:
        print(f"    [!] Invalid address in worker name: {e}")
        return None

class StatsHandler(BaseHTTPRequestHandler):
    """Simple HTTP handler for pool stats API"""
    def log_message(self, format, *args):
        pass  # Suppress logging

    def do_GET(self):
        if self.path == '/miners' or self.path == '/api/miners':
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.send_header('Access-Control-Allow-Origin', '*')
            self.end_headers()

            # Build detailed worker info
            workers_detail = []
            current_time = time.time()
            for name in miners.keys():
                stats = worker_stats.get(name, {})
                connect_time = stats.get('connect_time', current_time)
                uptime_secs = current_time - connect_time
                workers_detail.append({
                    'name': name,
                    'address': stats.get('address', ''),
                    'best_diff': stats.get('best_diff', 0),
                    'shares': stats.get('shares', 0),
                    'hashrate': stats.get('hashrate', 0),
                    'uptime': uptime_secs,
                    'last_seen': stats.get('last_seen', current_time)
                })

            data = {
                'count': len(miners),
                'workers': list(miners.keys()),
                'workers_detail': workers_detail
            }
            self.wfile.write(json.dumps(data).encode())

        elif self.path == '/stats' or self.path == '/api/stats':
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.send_header('Access-Control-Allow-Origin', '*')
            self.end_headers()

            # Get network info from node
            info = rpc("getblockchaininfo")
            mining_info = rpc("getmininginfo")

            # Calculate total pool hashrate and best difficulty
            total_hashrate = sum(s.get('hashrate', 0) for s in worker_stats.values())
            pool_best_diff = max((s.get('best_diff', 0) for s in worker_stats.values()), default=0)

            data = {
                'block_height': info.get('blocks', 0) if info else 0,
                'network_diff': info.get('difficulty', 0) if info else 0,
                'network_hashrate': mining_info.get('networkhashps', 0) if mining_info else 0,
                'pool_hashrate': total_hashrate,
                'pool_best_diff': pool_best_diff,
                'active_workers': len(miners)
            }
            self.wfile.write(json.dumps(data).encode())
        else:
            self.send_response(404)
            self.send_header('Access-Control-Allow-Origin', '*')
            self.end_headers()

def start_stats_server():
    """Start HTTP server for live stats in a background thread"""
    try:
        server = HTTPServer(('0.0.0.0', POOL_STATS_PORT), StatsHandler)
        print(f"Stats API listening on port {POOL_STATS_PORT}...")
        server.serve_forever()
    except Exception as e:
        print(f"Stats server error: {e}")

def report_block_to_ui(height, block_hash, worker, reward, miner_address=None):
    """Report found block to the pool dashboard"""
    try:
        data = json.dumps({
            "height": height,
            "hash": block_hash,
            "worker": worker,
            "address": miner_address or "",
            "reward": reward / 100000000,
            "timestamp": datetime.now().isoformat()
        }).encode()
        headers = {"Content-Type": "application/json"}
        if POOL_UI_API_KEY:
            headers["X-API-Key"] = POOL_UI_API_KEY
        req = urllib.request.Request(
            f"{POOL_UI_URL}/api/blocks/add",
            data=data,
            headers=headers
        )
        urllib.request.urlopen(req, timeout=5)
        print(f"    [Block reported to UI]")
    except Exception as e:
        print(f"    [UI report failed: {e}]")

def rpc(method, *args):
    """Execute RPC command to node"""
    try:
        cmd = [RPC_CLI, f"-datadir={DATA_DIR}", method] + [str(a) for a in args]
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=30)
        if result.returncode == 0 and result.stdout.strip():
            try:
                return json.loads(result.stdout)
            except json.JSONDecodeError:
                return result.stdout.strip()
        if result.stderr:
            print(f"RPC stderr: {result.stderr}")
        return None
    except subprocess.TimeoutExpired:
        print(f"RPC Timeout: {method}")
        return None
    except Exception as e:
        print(f"RPC Error: {e}")
        return None

def sha256d(data):
    """Double SHA-256 hash"""
    return hashlib.sha256(hashlib.sha256(data).digest()).digest()

def reverse_bytes(data):
    """Reverse byte order"""
    return data[::-1]

def swap_endian_words(hex_str):
    """Swap endianness of each 4-byte word"""
    data = bytes.fromhex(hex_str)
    result = b''
    for i in range(0, len(data), 4):
        result += data[i:i+4][::-1]
    return result

def merkle_root(coinbase_hash, branches):
    """Calculate merkle root from coinbase and branches"""
    current = coinbase_hash
    for branch in branches:
        current = sha256d(current + bytes.fromhex(branch))
    return current

def serialize_height(height):
    """
    Serialize block height for coinbase (BIP34 compliant)
    Uses minimal push encoding as required by consensus rules
    """
    if height == 0:
        return "0100"  # Push 1 byte: 0x00
    elif height <= 0x7f:
        # Heights 1-127: push 1 byte
        return f"01{height:02x}"
    elif height <= 0x7fff:
        # Heights 128-32767: push 2 bytes (little-endian)
        return f"02{height & 0xff:02x}{(height >> 8) & 0xff:02x}"
    elif height <= 0x7fffff:
        # Heights 32768-8388607: push 3 bytes
        return f"03{height & 0xff:02x}{(height >> 8) & 0xff:02x}{(height >> 16) & 0xff:02x}"
    else:
        # Heights 8388608+: push 4 bytes
        return f"04{height & 0xff:02x}{(height >> 8) & 0xff:02x}{(height >> 16) & 0xff:02x}{(height >> 24) & 0xff:02x}"

def decode_address(address):
    """
    Decode a base58check address to get the pubkey hash
    Returns (version_byte, pubkey_hash) or raises ValueError
    """
    ALPHABET = '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz'

    # Base58 decode
    n = 0
    for char in address:
        n = n * 58 + ALPHABET.index(char)

    # Convert to bytes (25 bytes for P2PKH)
    data = n.to_bytes(25, 'big')

    # Verify checksum
    payload = data[:-4]
    checksum = data[-4:]
    expected_checksum = sha256d(payload)[:4]

    if checksum != expected_checksum:
        raise ValueError("Invalid address checksum")

    version = payload[0]
    pubkey_hash = payload[1:]

    return version, pubkey_hash

def create_p2pkh_output(amount_satoshis, address):
    """
    Create a P2PKH output script for the coinbase
    Returns the serialized output (amount + scriptPubKey)
    """
    version, pubkey_hash = decode_address(address)

    # P2PKH scriptPubKey: OP_DUP OP_HASH160 <20 bytes> OP_EQUALVERIFY OP_CHECKSIG
    # 76 a9 14 <pubkey_hash> 88 ac
    script = bytes([0x76, 0xa9, 0x14]) + pubkey_hash + bytes([0x88, 0xac])

    # Output: 8-byte amount (LE) + varint script length + script
    output = struct.pack("<Q", amount_satoshis)
    output += bytes([len(script)])
    output += script

    return output.hex()

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
        self.miner_wallet = None  # Miner's wallet address for solo mining
        self.difficulty = 1
        self.jobs = {}
        self.job_counter = 0

    async def send(self, data):
        """Send JSON message to miner"""
        try:
            msg = json.dumps(data) + "\n"
            self.writer.write(msg.encode())
            await self.writer.drain()
        except Exception as e:
            print(f"[-] Send error: {e}")

    async def send_difficulty(self, diff):
        """Send difficulty to miner"""
        self.difficulty = diff
        await self.send({"id": None, "method": "mining.set_difficulty", "params": [diff]})
        print(f"    [Difficulty sent: {diff}]")

    async def send_job(self, clean=True):
        """Send mining job to miner"""
        template = rpc("getblocktemplate", '{"rules":["segwit"]}')
        if not template:
            print("[-] Failed to get block template")
            return

        self.job_counter += 1
        job_id = f"{SESSION_ID}{self.job_counter:04x}"

        # Calculate network difficulty (for block submission)
        target_int = int(template["target"], 16)
        diff1_target = 0x00000000FFFF0000000000000000000000000000000000000000000000000000
        network_diff = diff1_target / target_int if target_int > 0 else 1

        # Send LOW pool share difficulty so hobby miners can submit shares
        # They'll see progress even if they never find a block
        if abs(POOL_SHARE_DIFF - self.difficulty) > 0.0001:
            await self.send_difficulty(POOL_SHARE_DIFF)

        prevhash_rpc = template["previousblockhash"]
        prevhash_words = [prevhash_rpc[i:i+8] for i in range(0, 64, 8)]
        prevhash_stratum = "".join(prevhash_words[::-1])

        height = template["height"]
        reward = template["coinbasevalue"]
        height_script = serialize_height(height)

        # Calculate scriptsig length: height_script + extranonce1 (4 bytes) + extranonce2 (4 bytes)
        scriptsig_len = len(height_script)//2 + 4 + self.extranonce2_size

        # Coinbase part 1: version + input count + prevout + scriptsig length + height
        cb1 = "02000000" + "01" + "00"*32 + "ffffffff" + f"{scriptsig_len:02x}" + height_script

        # Coinbase part 2: sequence + output count + outputs + locktime
        # SOLO POOL: Use miner's address first, then POOL_ADDRESS fallback
        coinbase_address = self.miner_wallet or POOL_ADDRESS

        if coinbase_address:
            # Proper P2PKH output to miner's address (SOLO) or pool address (fallback)
            output_script = create_p2pkh_output(reward, coinbase_address)
            cb2 = "ffffffff" + "01" + output_script + "00000000"
        else:
            # FALLBACK: OP_TRUE output (WARNING: anyone can spend!)
            print("[WARNING] No valid address - using OP_TRUE output!")
            cb2 = "ffffffff" + "01" + struct.pack("<Q", reward).hex() + "0151" + "00000000"

        version_hex = struct.pack("<I", template["version"]).hex()
        nbits = template["bits"]
        ntime = f"{template['curtime']:08x}"
        merkle_branches = [tx["txid"] for tx in template.get("transactions", [])]

        # Limit job history to prevent memory leak
        if len(self.jobs) > 10:
            oldest = list(self.jobs.keys())[0]
            del self.jobs[oldest]

        self.jobs[job_id] = {
            "template": template,
            "prevhash_stratum": prevhash_stratum,
            "cb1": cb1,
            "cb2": cb2,
            "merkle_branches": merkle_branches,
            "version_hex": version_hex,
            "version_int": template["version"],
            "nbits": nbits,
            "target": template["target"],
            "network_diff": network_diff  # Store for block validation
        }

        await self.send({
            "id": None,
            "method": "mining.notify",
            "params": [job_id, prevhash_stratum, cb1, cb2, merkle_branches, version_hex, nbits, ntime, clean]
        })
        print(f"[>] Job {job_id} (height={height}, diff={network_diff:.6f})")

    async def handle_submit(self, msg_id, params):
        """Handle share submission from miner"""
        if len(params) < 5:
            await self.send({"id": msg_id, "result": False, "error": [20, "Invalid params", None]})
            return

        worker, job_id, extranonce2, ntime_hex, nonce_hex = params[:5]

        print(f"\n{'='*60}")
        print(f"[*] SHARE from {worker}")

        if job_id not in self.jobs:
            # Check if this is a stale job from before pool restart
            if not job_id.startswith(SESSION_ID):
                print(f"[-] Stale job {job_id} from previous session (current: {SESSION_ID})")
                # Tell miner to reconnect for fresh jobs
                try:
                    await self.send({"id": None, "method": "client.reconnect", "params": []})
                except Exception:
                    pass
            else:
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

        # Build header
        version_bytes = reverse_bytes(bytes.fromhex(job["version_hex"]))
        prevhash_bytes = swap_endian_words(job["prevhash_stratum"])
        merkle_bytes = mr
        ntime_bytes = reverse_bytes(bytes.fromhex(ntime_hex))
        nbits_bytes = reverse_bytes(bytes.fromhex(job["nbits"]))
        nonce_bytes = reverse_bytes(bytes.fromhex(nonce_hex))

        header = version_bytes + prevhash_bytes + merkle_bytes + ntime_bytes + nbits_bytes + nonce_bytes

        # Hash
        block_hash = sha256d(header)
        hash_display = block_hash[::-1].hex()
        leading_zeros = len(hash_display) - len(hash_display.lstrip('0'))

        print(f"    hash:  {hash_display[:24]}...")
        print(f"    zeros: {leading_zeros}")

        # Check target
        hash_int = int(hash_display, 16)
        target_int = int(job["target"], 16)

        # Calculate share difficulty
        diff1_target = 0x00000000FFFF0000000000000000000000000000000000000000000000000000
        share_diff = diff1_target / hash_int if hash_int > 0 else 0

        # Update worker stats
        if self.worker_name in worker_stats:
            stats = worker_stats[self.worker_name]
            stats['shares'] += 1
            stats['last_seen'] = time.time()

            # Track best difficulty
            if share_diff > stats['best_diff']:
                stats['best_diff'] = share_diff
                print(f"    [NEW BEST DIFF: {share_diff:.2f}]")

            # Calculate hashrate from share times (last 10 shares)
            stats['share_times'].append(time.time())
            if len(stats['share_times']) > 10:
                stats['share_times'] = stats['share_times'][-10:]
            if len(stats['share_times']) >= 2:
                time_span = stats['share_times'][-1] - stats['share_times'][0]
                if time_span > 0:
                    # Estimate hashrate: shares * difficulty * 2^32 / time
                    shares_in_span = len(stats['share_times']) - 1
                    stats['hashrate'] = (shares_in_span * self.difficulty * 4294967296) / time_span

        print(f"    share_diff: {share_diff:.6f}")

        # Check if share meets pool difficulty (for counting)
        # Pool difficulty is MUCH lower than network difficulty
        if share_diff < POOL_SHARE_DIFF:
            print(f"[-] Share below pool difficulty ({POOL_SHARE_DIFF})")
            await self.send({"id": msg_id, "result": False, "error": [23, "Low difficulty share", None]})
            print(f"{'='*60}\n")
            return

        # Share is valid for pool stats - accept it
        print(f"[+] Valid share! (pool_diff={POOL_SHARE_DIFF}, share_diff={share_diff:.6f})")

        # Check if share also meets NETWORK difficulty (potential block!)
        if hash_int < target_int:
            print(f"\n[!!!] BLOCK FOUND!")

            # Build full block
            block_hex = header.hex()
            tx_count = 1 + len(template.get("transactions", []))

            # Proper varint encoding for tx count
            if tx_count < 0xFD:
                block_hex += f"{tx_count:02x}"
            elif tx_count <= 0xFFFF:
                block_hex += f"fd{tx_count & 0xff:02x}{(tx_count >> 8) & 0xff:02x}"
            elif tx_count <= 0xFFFFFFFF:
                block_hex += f"fe{tx_count & 0xff:02x}{(tx_count >> 8) & 0xff:02x}{(tx_count >> 16) & 0xff:02x}{(tx_count >> 24) & 0xff:02x}"

            block_hex += coinbase_hex
            for tx in template.get("transactions", []):
                block_hex += tx["data"]

            result = rpc("submitblock", block_hex)
            if result is None or result == "":
                reward_address = self.miner_wallet or POOL_ADDRESS or "OP_TRUE"
                print(f"[***] BLOCK ACCEPTED! Height {template['height']}")
                print(f"[***] Reward -> {reward_address}")
                report_block_to_ui(template['height'], hash_display, self.worker_name, template['coinbasevalue'], self.miner_wallet)
                try:
                    await self.send({"id": None, "method": "client.show_message", "params": [f"BLOCK FOUND! Height {template['height']}"]})
                except Exception:
                    pass
                await self.send_job(clean=True)
            else:
                print(f"[!!!] Block rejected by node: {result}")

        # Accept the share (even if not a block)
        await self.send({"id": msg_id, "result": True, "error": None})

        print(f"{'='*60}\n")

    async def handle(self):
        """Main handler for miner connection"""
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

                    elif method == "mining.authorize":
                        self.worker_name = params[0] if params else "unknown"
                        miners[self.worker_name] = self

                        # Extract miner's wallet address from worker name (SOLO POOL)
                        self.miner_wallet = extract_miner_address(self.worker_name)
                        if self.miner_wallet:
                            print(f"[+] Authorized: {self.worker_name}")
                            print(f"    Mining to: {self.miner_wallet}")
                        else:
                            print(f"[+] Authorized: {self.worker_name}")
                            if POOL_ADDRESS:
                                print(f"    [!] Invalid address in worker name, using POOL_ADDRESS")
                            else:
                                print(f"    [!] WARNING: No valid address! Using OP_TRUE (anyone can spend)")

                        # Initialize worker stats
                        if self.worker_name not in worker_stats:
                            worker_stats[self.worker_name] = {
                                'address': self.miner_wallet or '',
                                'best_diff': 0,
                                'shares': 0,
                                'connect_time': time.time(),
                                'last_seen': time.time(),
                                'hashrate': 0,
                                'share_times': []  # For hashrate calculation
                            }
                        else:
                            # Reconnecting worker - update connect time but keep best_diff
                            worker_stats[self.worker_name]['connect_time'] = time.time()
                            worker_stats[self.worker_name]['last_seen'] = time.time()

                        await self.send({"id": msg_id, "result": True, "error": None})
                        await self.send_job(clean=True)

                    elif method == "mining.submit":
                        await self.handle_submit(msg_id, params)

                    elif method == "mining.suggest_difficulty":
                        pass  # Ignore - we use network difficulty

                    elif method == "mining.extranonce.subscribe":
                        await self.send({"id": msg_id, "result": True, "error": None})

                except json.JSONDecodeError as e:
                    print(f"[-] JSON decode error: {e}")
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
    """Periodically send new jobs to all miners"""
    while True:
        await asyncio.sleep(30)
        for miner in list(miners.values()):
            try:
                await miner.send_job(clean=False)
            except Exception:
                pass

async def main():
    print("=" * 60)
    print("  RETARDIO POOL v8.2 - TRUE SOLO POOL")
    print("=" * 60)
    print()
    print("SOLO MINING MODE:")
    print("  - Miners use their wallet address as stratum username")
    print("  - Format: FAddress or FAddress.rigname")
    print("  - Block rewards go 100% to the miner who found it")
    print()

    # Optional fallback address
    if POOL_ADDRESS:
        print(f"Fallback Address: {POOL_ADDRESS}")
        print("  (Used if miner's address in worker name is invalid)")
    else:
        print("No fallback POOL_ADDRESS set")
        print("  (Miners MUST use valid address as worker name)")

    print(f"RPC CLI: {RPC_CLI}")
    print(f"Data Dir: {DATA_DIR}")
    print(f"Pool Port: {POOL_PORT}")
    print(f"UI URL: {POOL_UI_URL}")
    print(f"UI API Key: {'configured' if POOL_UI_API_KEY else 'NOT SET - block reports will fail!'}")
    print(f"Session ID: {SESSION_ID}")

    # Start stats server in background thread
    stats_thread = threading.Thread(target=start_stats_server, daemon=True)
    stats_thread.start()

    info = rpc("getblockchaininfo")
    if not info:
        print("\nERROR: Cannot connect to node!")
        print("Make sure retardiod is running and RPC is accessible")
        return

    print(f"\nNode: Block {info['blocks']}, Diff {info['difficulty']:.6f}")
    print("=" * 60)
    print(f"Pool listening on port {POOL_PORT}...")

    server = await asyncio.start_server(
        lambda r, w: StratumMiner(r, w).handle(),
        '0.0.0.0',
        POOL_PORT
    )
    asyncio.create_task(job_broadcaster())

    async with server:
        await server.serve_forever()

if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        print("\nPool stopped.")
