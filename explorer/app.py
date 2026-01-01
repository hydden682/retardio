#!/usr/bin/env python3
"""
Retardio Block Explorer - Public Server
A production-ready block explorer that connects to multiple nodes
"""

import os
import json
import time
import threading
import sqlite3
from datetime import datetime
from flask import Flask, jsonify, request, render_template, g
from flask_cors import CORS
import requests
from requests.auth import HTTPBasicAuth
import logging

app = Flask(__name__, template_folder='templates', static_folder='static')
CORS(app)

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

DATABASE = os.environ.get('DATABASE_PATH', 'explorer.db')
registered_nodes = {}
primary_node = None
node_lock = threading.Lock()

def get_db():
    db = getattr(g, '_database', None)
    if db is None:
        db = g._database = sqlite3.connect(DATABASE)
        db.row_factory = sqlite3.Row
    return db

@app.teardown_appcontext
def close_connection(exception):
    db = getattr(g, '_database', None)
    if db is not None:
        db.close()

def init_db():
    with app.app_context():
        db = get_db()
        db.executescript('''
            CREATE TABLE IF NOT EXISTS nodes (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                host TEXT NOT NULL, port INTEGER NOT NULL,
                rpc_user TEXT, rpc_pass TEXT,
                last_seen TIMESTAMP, block_height INTEGER DEFAULT 0,
                is_active INTEGER DEFAULT 1, version TEXT,
                UNIQUE(host, port)
            );
            CREATE TABLE IF NOT EXISTS blocks (
                height INTEGER PRIMARY KEY, hash TEXT UNIQUE NOT NULL,
                prev_hash TEXT, timestamp INTEGER, difficulty REAL,
                nonce INTEGER, size INTEGER, tx_count INTEGER,
                reward REAL, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            );
            CREATE TABLE IF NOT EXISTS transactions (
                txid TEXT PRIMARY KEY, block_height INTEGER,
                block_hash TEXT, timestamp INTEGER, size INTEGER,
                fee REAL, is_coinbase INTEGER DEFAULT 0,
                total_output REAL, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            );
            CREATE TABLE IF NOT EXISTS tx_outputs (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                txid TEXT NOT NULL,
                vout_index INTEGER NOT NULL,
                address TEXT,
                value REAL,
                block_height INTEGER,
                timestamp INTEGER,
                UNIQUE(txid, vout_index)
            );
            CREATE TABLE IF NOT EXISTS tx_inputs (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                txid TEXT NOT NULL,
                vin_index INTEGER NOT NULL,
                prev_txid TEXT,
                prev_vout INTEGER,
                address TEXT,
                value REAL,
                block_height INTEGER,
                UNIQUE(txid, vin_index)
            );
            CREATE INDEX IF NOT EXISTS idx_blocks_hash ON blocks(hash);
            CREATE INDEX IF NOT EXISTS idx_tx_block ON transactions(block_height);
            CREATE INDEX IF NOT EXISTS idx_outputs_address ON tx_outputs(address);
            CREATE INDEX IF NOT EXISTS idx_inputs_address ON tx_inputs(address);
            CREATE INDEX IF NOT EXISTS idx_outputs_txid ON tx_outputs(txid);
        ''')
        db.commit()

def rpc_call(node, method, params=[]):
    try:
        url = f"http://{node['host']}:{node['port']}"
        payload = {'jsonrpc': '1.0', 'id': 'explorer', 'method': method, 'params': params}
        auth = HTTPBasicAuth(node['rpc_user'], node['rpc_pass']) if node.get('rpc_user') else None
        response = requests.post(url, json=payload, auth=auth, timeout=10)
        result = response.json()
        return result.get('result') if not result.get('error') else None
    except Exception as e:
        logger.error(f"RPC error: {e}")
        return None

def get_active_node():
    global primary_node
    with node_lock:
        if primary_node and registered_nodes.get(primary_node, {}).get('is_active'):
            return registered_nodes[primary_node]
        for node_id, node in registered_nodes.items():
            if node.get('is_active'):
                primary_node = node_id
                return node
    return None

def sync_blocks():
    while True:
        try:
            node = get_active_node()
            if not node:
                time.sleep(30)
                continue
            info = rpc_call(node, 'getblockchaininfo')
            if not info:
                time.sleep(30)
                continue
            current_height = info.get('blocks', 0)
            with app.app_context():
                db = get_db()
                cursor = db.execute('SELECT MAX(height) FROM blocks')
                our_height = cursor.fetchone()[0] or -1
            for height in range(our_height + 1, min(our_height + 101, current_height + 1)):
                block_hash = rpc_call(node, 'getblockhash', [height])
                if not block_hash:
                    continue
                block = rpc_call(node, 'getblock', [block_hash, 2])
                if not block:
                    continue
                with app.app_context():
                    db = get_db()
                    reward = sum(v.get('value', 0) for v in block['tx'][0].get('vout', [])) if block.get('tx') else 0
                    db.execute('INSERT OR REPLACE INTO blocks VALUES (?,?,?,?,?,?,?,?,?,CURRENT_TIMESTAMP)',
                        (height, block['hash'], block.get('previousblockhash', ''), block.get('time', 0),
                         block.get('difficulty', 0), block.get('nonce', 0), block.get('size', 0),
                         len(block.get('tx', [])), reward))
                    for tx in block.get('tx', []):
                        is_coinbase = 1 if 'coinbase' in tx.get('vin', [{}])[0] else 0
                        total_output = sum(v.get('value', 0) for v in tx.get('vout', []))
                        db.execute('INSERT OR REPLACE INTO transactions VALUES (?,?,?,?,?,?,?,?,CURRENT_TIMESTAMP)',
                            (tx['txid'], height, block['hash'], block.get('time', 0),
                             tx.get('size', 0), 0, is_coinbase, total_output))
                        # Store transaction outputs with addresses
                        for vout in tx.get('vout', []):
                            vout_idx = vout.get('n', 0)
                            value = vout.get('value', 0)
                            addresses = vout.get('scriptPubKey', {}).get('addresses', [])
                            # Also check 'address' field (newer Bitcoin Core versions)
                            if not addresses:
                                addr = vout.get('scriptPubKey', {}).get('address')
                                if addr:
                                    addresses = [addr]
                            for addr in addresses:
                                db.execute('INSERT OR REPLACE INTO tx_outputs (txid, vout_index, address, value, block_height, timestamp) VALUES (?,?,?,?,?,?)',
                                    (tx['txid'], vout_idx, addr, value, height, block.get('time', 0)))
                        # Store transaction inputs (for spending tracking)
                        if not is_coinbase:
                            for vin_idx, vin in enumerate(tx.get('vin', [])):
                                prev_txid = vin.get('txid')
                                prev_vout = vin.get('vout')
                                if prev_txid:
                                    # Try to look up the address from the previous output
                                    prev_cursor = db.execute('SELECT address, value FROM tx_outputs WHERE txid = ? AND vout_index = ?', (prev_txid, prev_vout))
                                    prev_row = prev_cursor.fetchone()
                                    addr = prev_row['address'] if prev_row else None
                                    value = prev_row['value'] if prev_row else 0
                                    db.execute('INSERT OR REPLACE INTO tx_inputs (txid, vin_index, prev_txid, prev_vout, address, value, block_height) VALUES (?,?,?,?,?,?,?)',
                                        (tx['txid'], vin_idx, prev_txid, prev_vout, addr, value, height))
                    db.commit()
                logger.info(f"Synced block {height}")
            time.sleep(10)
        except Exception as e:
            logger.error(f"Sync error: {e}")
            time.sleep(30)

def health_check():
    while True:
        with node_lock:
            for nid, node in registered_nodes.items():
                info = rpc_call(node, 'getblockchaininfo')
                node['is_active'] = bool(info)
                if info:
                    node['block_height'] = info.get('blocks', 0)
                    node['last_seen'] = datetime.now().isoformat()
        time.sleep(60)

@app.route('/')
def index():
    return render_template('index.html')

@app.route('/api/status')
def api_status():
    node = get_active_node()
    if not node:
        return jsonify({'error': 'No active nodes'}), 503
    info = rpc_call(node, 'getblockchaininfo')
    return jsonify({'status': 'online', 'blocks': info.get('blocks', 0) if info else 0,
                    'difficulty': info.get('difficulty', 0) if info else 0,
                    'nodes': len([n for n in registered_nodes.values() if n.get('is_active')])})

@app.route('/api/blocks')
def api_blocks():
    limit = min(int(request.args.get('limit', 20)), 100)
    db = get_db()
    cursor = db.execute('SELECT * FROM blocks ORDER BY height DESC LIMIT ?', (limit,))
    return jsonify({'blocks': [dict(row) for row in cursor.fetchall()]})

@app.route('/api/block/<identifier>')
def api_block(identifier):
    db = get_db()
    if identifier.isdigit():
        cursor = db.execute('SELECT * FROM blocks WHERE height = ?', (int(identifier),))
    else:
        cursor = db.execute('SELECT * FROM blocks WHERE hash = ?', (identifier,))
    row = cursor.fetchone()
    if not row:
        return jsonify({'error': 'Not found'}), 404
    tx_cursor = db.execute('SELECT * FROM transactions WHERE block_height = ?', (row['height'],))
    return jsonify({**dict(row), 'transactions': [dict(tx) for tx in tx_cursor.fetchall()]})

@app.route('/api/tx/<txid>')
def api_tx(txid):
    db = get_db()
    cursor = db.execute('SELECT * FROM transactions WHERE txid = ?', (txid,))
    row = cursor.fetchone()
    if not row:
        node = get_active_node()
        if node:
            tx = rpc_call(node, 'getrawtransaction', [txid, True])
            if tx:
                return jsonify(tx)
        return jsonify({'error': 'Not found'}), 404
    return jsonify(dict(row))

@app.route('/api/address/<address>')
def api_address(address):
    db = get_db()
    # Get all outputs (received) for this address
    received_cursor = db.execute('''
        SELECT txid, vout_index, value, block_height, timestamp
        FROM tx_outputs WHERE address = ? ORDER BY block_height DESC
    ''', (address,))
    received = [dict(row) for row in received_cursor.fetchall()]

    # Get all inputs (spent) from this address
    spent_cursor = db.execute('''
        SELECT txid, vin_index, prev_txid, prev_vout, value, block_height
        FROM tx_inputs WHERE address = ? ORDER BY block_height DESC
    ''', (address,))
    spent = [dict(row) for row in spent_cursor.fetchall()]

    # Calculate balance
    total_received = sum(r['value'] or 0 for r in received)
    total_spent = sum(s['value'] or 0 for s in spent)
    balance = total_received - total_spent

    # Get unique transactions involving this address
    tx_set = set()
    for r in received:
        tx_set.add(r['txid'])
    for s in spent:
        tx_set.add(s['txid'])

    # Get transaction details
    transactions = []
    for txid in tx_set:
        tx_cursor = db.execute('SELECT * FROM transactions WHERE txid = ?', (txid,))
        tx_row = tx_cursor.fetchone()
        if tx_row:
            tx_dict = dict(tx_row)
            # Calculate net amount for this address in this tx
            tx_received = sum(r['value'] or 0 for r in received if r['txid'] == txid)
            tx_spent = sum(s['value'] or 0 for s in spent if s['txid'] == txid)
            tx_dict['net_amount'] = tx_received - tx_spent
            tx_dict['tx_type'] = 'received' if tx_dict['net_amount'] > 0 else 'sent'
            transactions.append(tx_dict)

    # Sort by block height descending
    transactions.sort(key=lambda x: x.get('block_height', 0), reverse=True)

    return jsonify({
        'address': address,
        'balance': balance,
        'total_received': total_received,
        'total_spent': total_spent,
        'tx_count': len(transactions),
        'transactions': transactions[:50]  # Limit to 50 most recent
    })

@app.route('/api/search')
def api_search():
    q = request.args.get('q', '').strip()
    if not q:
        return jsonify({'error': 'Empty query'}), 400
    db = get_db()
    if q.isdigit():
        c = db.execute('SELECT hash FROM blocks WHERE height = ?', (int(q),))
        r = c.fetchone()
        if r:
            return jsonify({'type': 'block', 'height': int(q), 'hash': r['hash']})
    if len(q) == 64:
        c = db.execute('SELECT height FROM blocks WHERE hash = ?', (q,))
        r = c.fetchone()
        if r:
            return jsonify({'type': 'block', 'height': r['height'], 'hash': q})
        c = db.execute('SELECT block_height FROM transactions WHERE txid = ?', (q,))
        r = c.fetchone()
        if r:
            return jsonify({'type': 'tx', 'txid': q})
    if q.startswith('F') or q.startswith('R'):
        # Check if we have any data for this address
        c = db.execute('SELECT COUNT(*) as cnt FROM tx_outputs WHERE address = ?', (q,))
        r = c.fetchone()
        return jsonify({'type': 'address', 'address': q, 'has_data': r['cnt'] > 0 if r else False})
    return jsonify({'error': 'Not found'}), 404

@app.route('/api/nodes')
def api_nodes():
    return jsonify({'nodes': [{'host': n['host'], 'port': n['port'], 'active': n.get('is_active', False),
                               'height': n.get('block_height', 0)} for n in registered_nodes.values()]})

@app.route('/api/nodes/register', methods=['POST'])
def register_node():
    data = request.get_json()
    if not data or not data.get('host') or not data.get('port'):
        return jsonify({'error': 'Missing host/port'}), 400
    node = {'host': data['host'], 'port': int(data['port']),
            'rpc_user': data.get('rpc_user', ''), 'rpc_pass': data.get('rpc_pass', ''),
            'is_active': False, 'block_height': 0}
    info = rpc_call(node, 'getblockchaininfo')
    if info:
        node['is_active'] = True
        node['block_height'] = info.get('blocks', 0)
    node_id = f"{node['host']}:{node['port']}"
    with node_lock:
        registered_nodes[node_id] = node
    db = get_db()
    db.execute('INSERT OR REPLACE INTO nodes (host,port,rpc_user,rpc_pass,is_active,block_height) VALUES (?,?,?,?,?,?)',
               (node['host'], node['port'], node['rpc_user'], node['rpc_pass'], 1 if node['is_active'] else 0, node['block_height']))
    db.commit()
    return jsonify({'success': True, 'active': node['is_active'], 'height': node['block_height']})

def load_nodes():
    with app.app_context():
        db = get_db()
        for row in db.execute('SELECT * FROM nodes').fetchall():
            registered_nodes[f"{row['host']}:{row['port']}"] = dict(row)

# Initialize on import (for gunicorn)
init_db()
load_nodes()
threading.Thread(target=sync_blocks, daemon=True).start()
threading.Thread(target=health_check, daemon=True).start()

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=int(os.environ.get('PORT', 5000)))
