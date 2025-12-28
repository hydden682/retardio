#!/usr/bin/env python3
"""
Retardio Pool Dashboard v1.1
Web UI to display found blocks and pool statistics

Security fixes:
- Debug mode disabled
- API key authentication for block submission
"""

from flask import Flask, render_template, jsonify, request
from flask_cors import CORS
import sqlite3
import os
import secrets
from datetime import datetime
from functools import wraps

app = Flask(__name__)
CORS(app)

# Configuration via environment variables
DB_PATH = os.environ.get('POOL_DB_PATH', os.path.join(os.path.dirname(__file__), 'pool.db'))
API_KEY = os.environ.get('POOL_API_KEY', '')

# Generate API key if not set (for first-run)
if not API_KEY:
    API_KEY = secrets.token_hex(32)
    print(f"[WARNING] No POOL_API_KEY set. Generated temporary key: {API_KEY}")
    print("[WARNING] Set POOL_API_KEY environment variable for production!")

def require_api_key(f):
    """Decorator to require API key for internal endpoints"""
    @wraps(f)
    def decorated(*args, **kwargs):
        provided_key = request.headers.get('X-API-Key') or request.args.get('api_key')
        if not provided_key or provided_key != API_KEY:
            return jsonify({'error': 'Unauthorized'}), 401
        return f(*args, **kwargs)
    return decorated

def get_db():
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    return conn

def init_db():
    with get_db() as conn:
        conn.execute('''
            CREATE TABLE IF NOT EXISTS blocks (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                height INTEGER NOT NULL,
                hash TEXT NOT NULL,
                worker TEXT NOT NULL,
                address TEXT,
                reward REAL,
                timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
            )
        ''')
        conn.execute('''
            CREATE TABLE IF NOT EXISTS shares (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                worker TEXT NOT NULL,
                valid INTEGER DEFAULT 1,
                timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
            )
        ''')
        conn.commit()

@app.route('/')
def index():
    return render_template('index.html')

@app.route('/api/blocks')
def get_blocks():
    """Get all found blocks"""
    start_date = request.args.get('start', '2025-01-01')
    end_date = request.args.get('end', '2030-12-31')
    worker = request.args.get('worker', None)

    conn = get_db()
    if worker:
        rows = conn.execute('''
            SELECT * FROM blocks
            WHERE timestamp BETWEEN ? AND ? AND worker LIKE ?
            ORDER BY timestamp DESC
        ''', (start_date, end_date + ' 23:59:59', f'%{worker}%')).fetchall()
    else:
        rows = conn.execute('''
            SELECT * FROM blocks
            WHERE timestamp BETWEEN ? AND ?
            ORDER BY timestamp DESC
        ''', (start_date, end_date + ' 23:59:59')).fetchall()
    conn.close()

    blocks = []
    for row in rows:
        blocks.append({
            'id': row['id'],
            'height': row['height'],
            'hash': row['hash'],
            'worker': row['worker'],
            'address': row['address'],
            'reward': row['reward'],
            'timestamp': row['timestamp']
        })
    return jsonify(blocks)

@app.route('/api/blocks/add', methods=['POST'])
@require_api_key
def add_block():
    """Add a new found block (called by pool server only)"""
    data = request.json
    if not data:
        return jsonify({'error': 'No data provided'}), 400
    conn = get_db()
    conn.execute('''
        INSERT INTO blocks (height, hash, worker, address, reward, timestamp)
        VALUES (?, ?, ?, ?, ?, ?)
    ''', (
        data.get('height'),
        data.get('hash'),
        data.get('worker'),
        data.get('address', ''),
        data.get('reward', 0),
        data.get('timestamp', datetime.now().isoformat())
    ))
    conn.commit()
    conn.close()
    return jsonify({'success': True})

@app.route('/api/stats')
def get_stats():
    """Get pool statistics"""
    conn = get_db()

    total_blocks = conn.execute('SELECT COUNT(*) FROM blocks').fetchone()[0]

    # Blocks in last 24 hours
    recent_blocks = conn.execute('''
        SELECT COUNT(*) FROM blocks
        WHERE timestamp > datetime('now', '-1 day')
    ''').fetchone()[0]

    # Top workers
    top_workers = conn.execute('''
        SELECT worker, COUNT(*) as blocks FROM blocks
        GROUP BY worker ORDER BY blocks DESC LIMIT 10
    ''').fetchall()

    conn.close()

    return jsonify({
        'total_blocks': total_blocks,
        'blocks_24h': recent_blocks,
        'top_workers': [{'worker': w['worker'], 'blocks': w['blocks']} for w in top_workers]
    })

@app.route('/api/worker/<worker>')
def get_worker_stats(worker):
    """Get stats for a specific worker"""
    conn = get_db()

    blocks = conn.execute('''
        SELECT * FROM blocks WHERE worker LIKE ? ORDER BY timestamp DESC
    ''', (f'%{worker}%',)).fetchall()

    conn.close()

    return jsonify({
        'worker': worker,
        'total_blocks': len(blocks),
        'blocks': [dict(row) for row in blocks]
    })

if __name__ == '__main__':
    init_db()
    # SECURITY: Debug mode MUST be False in production (allows RCE)
    port = int(os.environ.get('POOL_UI_PORT', 5555))
    app.run(host='0.0.0.0', port=port, debug=False)
