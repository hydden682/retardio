#!/usr/bin/env python3
"""
Retardio Mining Pool - Stratum Server
Official pool for Retardio cryptocurrency
"""

import asyncio
import json
import hashlib
import struct
import time
from collections import defaultdict
import subprocess
import os

# Pool configuration
POOL_ADDRESS = "YOUR_POOL_ADDRESS_HERE"  # Will be set during setup
POOL_FEE = 1.0  # 1% pool fee
DIFFICULTY = 0.0001  # Initial share difficulty
STRATUM_PORT = 3333
RPC_USER = "retardio"
RPC_PASS = "retardio"
RPC_HOST = "127.0.0.1"
RPC_PORT = 18332

# Paths
RETARDIO_CLI = os.path.expanduser("~/.retardio/retardio-cli")
DATA_DIR = os.path.expanduser("~/.retardio/data")

# Miner tracking
miners = {}
shares = defaultdict(int)
hashrates = defaultdict(float)

def rpc_call(method, params=[]):
    """Call Retardio RPC"""
    try:
        cmd = [RETARDIO_CLI, f"-datadir={DATA_DIR}", method] + [str(p) for p in params]
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=30)
        if result.returncode == 0:
            try:
                return json.loads(result.stdout)
            except:
                return result.stdout.strip()
        else:
            return {"error": result.stderr}
    except Exception as e:
        return {"error": str(e)}

async def get_block_template():
    """Get block template from node"""
    return rpc_call("getblocktemplate", [{"rules": ["segwit"]}])

async def submit_block(block_hex):
    """Submit found block to node"""
    return rpc_call("submitblock", [block_hex])

class StratumClient:
    def __init__(self, reader, writer):
        self.reader = reader
        self.writer = writer
        self.address = writer.get_extra_info('peername')
        self.worker_name = None
        self.difficulty = DIFFICULTY
        self.last_share = time.time()
        self.shares = 0

    async def send_response(self, msg_id, result, error=None):
        """Send JSON-RPC response"""
        response = {
            "id": msg_id,
            "result": result,
            "error": error
        }
        data = json.dumps(response) + "\n"
        self.writer.write(data.encode())
        await self.writer.drain()

    async def send_notification(self, method, params):
        """Send stratum notification"""
        notification = {
            "id": None,
            "method": method,
            "params": params
        }
        data = json.dumps(notification) + "\n"
        self.writer.write(data.encode())
        await self.writer.drain()

    async def handle_subscribe(self, msg_id, params):
        """Handle mining.subscribe"""
        session_id = hashlib.sha256(f"{self.address}{time.time()}".encode()).hexdigest()[:16]
        await self.send_response(msg_id, [
            [["mining.notify", session_id]],
            session_id,
            4  # extranonce2 size
        ])

    async def handle_authorize(self, msg_id, params):
        """Handle mining.authorize"""
        if len(params) >= 1:
            self.worker_name = params[0]
            miners[self.worker_name] = self
            print(f"[+] Miner authorized: {self.worker_name} from {self.address}")
            await self.send_response(msg_id, True)
        else:
            await self.send_response(msg_id, False, "Invalid authorization")

    async def handle_submit(self, msg_id, params):
        """Handle mining.submit (share submission)"""
        if len(params) < 5:
            await self.send_response(msg_id, False, "Invalid share")
            return

        worker_name, job_id, extranonce2, ntime, nonce = params

        # For now, accept all shares (simplified)
        self.shares += 1
        self.last_share = time.time()
        shares[worker_name] += 1

        print(f"[+] Share accepted from {worker_name} (total: {shares[worker_name]})")
        await self.send_response(msg_id, True)

        # TODO: Validate share and check if it's a block

    async def handle_message(self, message):
        """Handle incoming stratum message"""
        try:
            msg = json.loads(message)
            method = msg.get("method")
            msg_id = msg.get("id")
            params = msg.get("params", [])

            if method == "mining.subscribe":
                await self.handle_subscribe(msg_id, params)
            elif method == "mining.authorize":
                await self.handle_authorize(msg_id, params)
            elif method == "mining.submit":
                await self.handle_submit(msg_id, params)
            else:
                await self.send_response(msg_id, None, f"Unknown method: {method}")
        except json.JSONDecodeError:
            print(f"[-] Invalid JSON from {self.address}: {message}")
        except Exception as e:
            print(f"[-] Error handling message: {e}")

    async def handle(self):
        """Main client handler"""
        print(f"[+] New connection from {self.address}")

        try:
            while True:
                data = await self.reader.readline()
                if not data:
                    break

                message = data.decode().strip()
                if message:
                    await self.handle_message(message)
        except asyncio.CancelledError:
            pass
        except Exception as e:
            print(f"[-] Error with {self.address}: {e}")
        finally:
            if self.worker_name:
                print(f"[-] Miner disconnected: {self.worker_name}")
                if self.worker_name in miners:
                    del miners[self.worker_name]
            self.writer.close()
            await self.writer.wait_closed()

async def handle_client(reader, writer):
    """Handle new client connection"""
    client = StratumClient(reader, writer)
    await client.handle()

async def broadcast_jobs():
    """Broadcast new mining jobs to all connected miners"""
    while True:
        try:
            # Get new block template
            template = await get_block_template()

            if isinstance(template, dict) and "error" not in template:
                # Send mining.notify to all connected miners
                job_params = [
                    hashlib.sha256(str(time.time()).encode()).hexdigest()[:8],  # job_id
                    template.get("previousblockhash", "0" * 64),
                    template.get("coinbaseaux", {}).get("flags", ""),
                    [],  # merkle branches
                    "00000002",  # version
                    template.get("bits", ""),
                    hex(int(time.time()))[2:],  # ntime
                    True  # clean_jobs
                ]

                for miner in list(miners.values()):
                    try:
                        await miner.send_notification("mining.notify", job_params)
                    except:
                        pass

            # Update every 30 seconds
            await asyncio.sleep(30)
        except Exception as e:
            print(f"[-] Error broadcasting jobs: {e}")
            await asyncio.sleep(10)

async def stats_display():
    """Display pool statistics"""
    while True:
        await asyncio.sleep(60)

        print("\n" + "="*60)
        print(f"RETARDIO POOL STATS - {time.strftime('%Y-%m-%d %H:%M:%S')}")
        print("="*60)
        print(f"Connected miners: {len(miners)}")

        if shares:
            print(f"\nTop miners:")
            sorted_miners = sorted(shares.items(), key=lambda x: x[1], reverse=True)[:10]
            for i, (worker, share_count) in enumerate(sorted_miners, 1):
                print(f"  {i}. {worker}: {share_count} shares")

        print("="*60 + "\n")

async def main():
    """Main pool server"""
    print("╔══════════════════════════════════════════════════════╗")
    print("║   Retardio Mining Pool - Stratum Server             ║")
    print("╚══════════════════════════════════════════════════════╝")
    print("")

    # Check if node is running
    info = rpc_call("getblockchaininfo")
    if isinstance(info, dict) and "error" in info:
        print("❌ Error: Retardio node is not running!")
        print("")
        print("Please start your node first:")
        print(f"  {RETARDIO_CLI} -datadir={DATA_DIR} -daemon")
        return

    print(f"✓ Connected to Retardio node")
    print(f"✓ Current block height: {info.get('blocks', 0)}")
    print("")
    print(f"Starting stratum server on port {STRATUM_PORT}...")
    print(f"Pool fee: {POOL_FEE}%")
    print(f"Share difficulty: {DIFFICULTY}")
    print("")
    print("Miners can connect using:")
    print(f"  stratum+tcp://YOUR_SERVER_IP:{STRATUM_PORT}")
    print("")

    # Start server
    server = await asyncio.start_server(handle_client, '0.0.0.0', STRATUM_PORT)

    # Start background tasks
    asyncio.create_task(broadcast_jobs())
    asyncio.create_task(stats_display())

    print("Pool is running! Press Ctrl+C to stop")
    print("")

    async with server:
        await server.serve_forever()

if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        print("\n\nPool stopped.")
