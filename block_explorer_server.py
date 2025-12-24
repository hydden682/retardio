#!/usr/bin/env python3
"""
Retardio Block Explorer Server
Runs on http://localhost:3002/
"""

from http.server import HTTPServer, BaseHTTPRequestHandler
import json
import subprocess
import os

PORT = 3002
RETARDIO_CLI = os.path.expanduser("~/.retardio/retardio-cli")
DATA_DIR = os.path.expanduser("~/.retardio/data")

def rpc_call(method, params=[]):
    """Call Retardio RPC"""
    try:
        cmd = [RETARDIO_CLI, f"-datadir={DATA_DIR}", method] + [str(p) for p in params]
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=10)
        if result.returncode == 0:
            try:
                return json.loads(result.stdout)
            except:
                return result.stdout.strip()
        else:
            return {"error": result.stderr}
    except Exception as e:
        return {"error": str(e)}

class BlockExplorerHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/":
            self.serve_html()
        elif self.path == "/api/stats":
            self.serve_stats()
        elif self.path.startswith("/api/blocks"):
            self.serve_blocks()
        elif self.path.startswith("/api/block/"):
            block_id = self.path.split("/")[-1]
            self.serve_block(block_id)
        else:
            self.send_error(404)

    def serve_html(self):
        """Serve the main HTML page"""
        html = """<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Retardio Block Explorer</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            padding: 20px;
        }
        .container { max-width: 1200px; margin: 0 auto; }
        .header {
            background: white;
            padding: 30px;
            border-radius: 15px;
            box-shadow: 0 10px 40px rgba(0,0,0,0.1);
            margin-bottom: 30px;
            text-align: center;
        }
        .header h1 { color: #667eea; font-size: 2.5em; margin-bottom: 10px; }
        .header p { color: #666; font-size: 1.1em; }
        .stats {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 20px;
            margin-bottom: 30px;
        }
        .stat-card {
            background: white;
            padding: 25px;
            border-radius: 15px;
            box-shadow: 0 10px 40px rgba(0,0,0,0.1);
        }
        .stat-card h3 {
            color: #667eea;
            font-size: 0.9em;
            text-transform: uppercase;
            margin-bottom: 10px;
        }
        .stat-card .value { color: #333; font-size: 2em; font-weight: bold; }
        .search-box {
            background: white;
            padding: 30px;
            border-radius: 15px;
            box-shadow: 0 10px 40px rgba(0,0,0,0.1);
            margin-bottom: 30px;
        }
        .search-box h2 { color: #667eea; margin-bottom: 20px; }
        .search-input { display: flex; gap: 10px; }
        .search-input input {
            flex: 1;
            padding: 15px;
            border: 2px solid #e0e0e0;
            border-radius: 10px;
            font-size: 1em;
        }
        .search-input button {
            padding: 15px 30px;
            background: #667eea;
            color: white;
            border: none;
            border-radius: 10px;
            cursor: pointer;
            font-size: 1em;
            font-weight: bold;
        }
        .search-input button:hover { background: #764ba2; }
        .block-list {
            background: white;
            padding: 30px;
            border-radius: 15px;
            box-shadow: 0 10px 40px rgba(0,0,0,0.1);
        }
        .block-list h2 { color: #667eea; margin-bottom: 20px; }
        .block-item {
            padding: 20px;
            border-bottom: 1px solid #e0e0e0;
            cursor: pointer;
            transition: background 0.3s;
        }
        .block-item:hover { background: #f5f5f5; }
        .block-item:last-child { border-bottom: none; }
        .block-height {
            font-size: 1.2em;
            font-weight: bold;
            color: #667eea;
            margin-bottom: 5px;
        }
        .block-hash {
            color: #666;
            font-family: monospace;
            font-size: 0.9em;
            word-break: break-all;
        }
        .block-time { color: #999; font-size: 0.9em; margin-top: 5px; }
        .block-detail {
            background: #f9f9f9;
            padding: 20px;
            margin-top: 15px;
            border-radius: 10px;
            display: none;
        }
        .block-detail.active { display: block; }
        .detail-row { display: flex; padding: 10px 0; border-bottom: 1px solid #e0e0e0; }
        .detail-row:last-child { border-bottom: none; }
        .detail-label { font-weight: bold; color: #667eea; min-width: 150px; }
        .detail-value { color: #333; font-family: monospace; word-break: break-all; }
        .error { background: #ff4444; color: white; padding: 15px; border-radius: 10px; margin-top: 10px; }
        .loading { text-align: center; padding: 20px; color: #667eea; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🔍 Retardio Block Explorer</h1>
            <p>Explore the Retardio blockchain - Running on localhost:3002</p>
        </div>

        <div class="stats">
            <div class="stat-card">
                <h3>Current Height</h3>
                <div class="value" id="blockHeight">Loading...</div>
            </div>
            <div class="stat-card">
                <h3>Difficulty</h3>
                <div class="value" id="difficulty">Loading...</div>
            </div>
            <div class="stat-card">
                <h3>Connections</h3>
                <div class="value" id="connections">Loading...</div>
            </div>
            <div class="stat-card">
                <h3>Chain Work</h3>
                <div class="value" id="chainwork">Loading...</div>
            </div>
        </div>

        <div class="search-box">
            <h2>Search</h2>
            <div class="search-input">
                <input type="text" id="searchInput" placeholder="Enter block height or hash...">
                <button onclick="searchBlock()">Search</button>
            </div>
            <div id="searchError"></div>
        </div>

        <div class="block-list">
            <h2>Recent Blocks</h2>
            <div id="blockList">
                <div class="loading">Loading blocks...</div>
            </div>
        </div>
    </div>

    <script>
        async function loadStats() {
            try {
                const stats = await fetch('/api/stats').then(r => r.json());
                document.getElementById('blockHeight').textContent = stats.blocks.toLocaleString();
                document.getElementById('difficulty').textContent = stats.difficulty.toFixed(8);
                document.getElementById('connections').textContent = stats.connections || '0';
                document.getElementById('chainwork').textContent = stats.chainwork.substring(0, 16) + '...';
            } catch (error) {
                console.error('Error loading stats:', error);
            }
        }

        async function loadRecentBlocks() {
            try {
                const blocks = await fetch('/api/blocks').then(r => r.json());
                const blockList = document.getElementById('blockList');
                blockList.innerHTML = '';

                blocks.forEach(block => {
                    const blockItem = document.createElement('div');
                    blockItem.className = 'block-item';
                    blockItem.innerHTML = `
                        <div class="block-height">Block #${block.height}</div>
                        <div class="block-hash">Hash: ${block.hash}</div>
                        <div class="block-time">Time: ${new Date(block.time * 1000).toLocaleString()} | ${block.tx} transactions</div>
                        <div class="block-detail" id="detail-${block.height}">
                            <div class="detail-row">
                                <div class="detail-label">Height:</div>
                                <div class="detail-value">${block.height}</div>
                            </div>
                            <div class="detail-row">
                                <div class="detail-label">Hash:</div>
                                <div class="detail-value">${block.hash}</div>
                            </div>
                            <div class="detail-row">
                                <div class="detail-label">Difficulty:</div>
                                <div class="detail-value">${block.difficulty}</div>
                            </div>
                            <div class="detail-row">
                                <div class="detail-label">Size:</div>
                                <div class="detail-value">${block.size} bytes</div>
                            </div>
                        </div>
                    `;
                    blockItem.onclick = () => toggleBlockDetail(block.height);
                    blockList.appendChild(blockItem);
                });
            } catch (error) {
                document.getElementById('blockList').innerHTML = `
                    <div class="error">Error loading blocks: ${error.message}<br><br>
                    Make sure your Retardio node is running.</div>
                `;
            }
        }

        function toggleBlockDetail(height) {
            const detail = document.getElementById(`detail-${height}`);
            detail.classList.toggle('active');
        }

        async function searchBlock() {
            const input = document.getElementById('searchInput').value.trim();
            const errorDiv = document.getElementById('searchError');
            errorDiv.innerHTML = '';

            if (!input) {
                errorDiv.innerHTML = '<div class="error">Please enter a block height or hash</div>';
                return;
            }

            try {
                const block = await fetch(`/api/block/${input}`).then(r => r.json());
                if (block.error) {
                    errorDiv.innerHTML = `<div class="error">Block not found: ${block.error}</div>`;
                    return;
                }

                const blockList = document.getElementById('blockList');
                blockList.innerHTML = `
                    <div class="block-item">
                        <div class="block-height">Block #${block.height}</div>
                        <div class="block-hash">Hash: ${block.hash}</div>
                        <div class="block-detail active">
                            <div class="detail-row">
                                <div class="detail-label">Height:</div>
                                <div class="detail-value">${block.height}</div>
                            </div>
                            <div class="detail-row">
                                <div class="detail-label">Hash:</div>
                                <div class="detail-value">${block.hash}</div>
                            </div>
                            <div class="detail-row">
                                <div class="detail-label">Previous Hash:</div>
                                <div class="detail-value">${block.previousblockhash || 'Genesis Block'}</div>
                            </div>
                            <div class="detail-row">
                                <div class="detail-label">Merkle Root:</div>
                                <div class="detail-value">${block.merkleroot}</div>
                            </div>
                            <div class="detail-row">
                                <div class="detail-label">Timestamp:</div>
                                <div class="detail-value">${new Date(block.time * 1000).toLocaleString()}</div>
                            </div>
                            <div class="detail-row">
                                <div class="detail-label">Difficulty:</div>
                                <div class="detail-value">${block.difficulty}</div>
                            </div>
                        </div>
                    </div>
                `;
            } catch (error) {
                errorDiv.innerHTML = `<div class="error">Error: ${error.message}</div>`;
            }
        }

        loadStats();
        loadRecentBlocks();
        setInterval(() => { loadStats(); loadRecentBlocks(); }, 10000);

        document.getElementById('searchInput').addEventListener('keypress', (e) => {
            if (e.key === 'Enter') searchBlock();
        });
    </script>
</body>
</html>"""

        self.send_response(200)
        self.send_header('Content-type', 'text/html')
        self.end_headers()
        self.wfile.write(html.encode())

    def serve_stats(self):
        """Serve blockchain stats"""
        info = rpc_call("getblockchaininfo")
        connections = rpc_call("getconnectioncount")

        stats = {
            "blocks": info.get("blocks", 0),
            "difficulty": info.get("difficulty", 0),
            "chainwork": info.get("chainwork", ""),
            "connections": connections if isinstance(connections, int) else 0
        }

        self.send_response(200)
        self.send_header('Content-type', 'application/json')
        self.send_header('Access-Control-Allow-Origin', '*')
        self.end_headers()
        self.wfile.write(json.dumps(stats).encode())

    def serve_blocks(self):
        """Serve recent blocks"""
        try:
            height = rpc_call("getblockcount")
            if isinstance(height, dict) and "error" in height:
                self.send_error(500)
                return

            blocks = []
            for i in range(min(10, height + 1)):
                block_height = height - i
                if block_height < 0:
                    break

                block_hash = rpc_call("getblockhash", [block_height])
                block = rpc_call("getblock", [block_hash, 1])

                if isinstance(block, dict) and "error" not in block:
                    blocks.append({
                        "height": block.get("height", block_height),
                        "hash": block.get("hash", block_hash),
                        "time": block.get("time", 0),
                        "tx": block.get("nTx", 0),
                        "difficulty": block.get("difficulty", 0),
                        "size": block.get("size", 0)
                    })

            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.send_header('Access-Control-Allow-Origin', '*')
            self.end_headers()
            self.wfile.write(json.dumps(blocks).encode())
        except Exception as e:
            self.send_error(500, str(e))

    def serve_block(self, block_id):
        """Serve specific block"""
        try:
            # Try as height first
            if block_id.isdigit():
                block_hash = rpc_call("getblockhash", [int(block_id)])
            else:
                block_hash = block_id

            block = rpc_call("getblock", [block_hash, 2])

            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.send_header('Access-Control-Allow-Origin', '*')
            self.end_headers()
            self.wfile.write(json.dumps(block).encode())
        except Exception as e:
            self.send_error(404, str(e))

    def log_message(self, format, *args):
        """Custom log format"""
        print(f"[{self.log_date_time_string()}] {format % args}")

if __name__ == "__main__":
    server = HTTPServer(("localhost", PORT), BlockExplorerHandler)
    print(f"╔══════════════════════════════════════════════════════╗")
    print(f"║   Retardio Block Explorer Server                    ║")
    print(f"╚══════════════════════════════════════════════════════╝")
    print(f"")
    print(f"Server running on: http://localhost:{PORT}/")
    print(f"Press Ctrl+C to stop")
    print(f"")

    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nServer stopped.")
