# Retardio Block Explorer

Public block explorer that connects to multiple nodes across the Retardio network.

## Features

- Multi-node support - connects to ALL registered nodes
- Real-time block syncing
- Transaction tracking
- Node health monitoring
- Search by block height, hash, transaction ID, or address
- Node registration API
- Mobile-responsive design

## Quick Start (Local Development)

```bash
cd explorer
pip install -r requirements.txt
python app.py
```

Visit http://localhost:5000

## Deployment Options

### Option 1: Heroku (Free/Cheap)

1. Install Heroku CLI: https://devcenter.heroku.com/articles/heroku-cli

2. Deploy:
```bash
cd explorer
heroku login
heroku create retardio-explorer
git init
git add .
git commit -m "Deploy explorer"
git push heroku main
```

3. Open: `heroku open`

### Option 2: DigitalOcean App Platform

1. Push to GitHub
2. Go to https://cloud.digitalocean.com/apps
3. Create App → Select your GitHub repo → Select the `explorer` folder
4. Deploy

### Option 3: VPS (DigitalOcean, Linode, AWS EC2)

1. Create a VPS with Ubuntu 22.04

2. SSH into server:
```bash
ssh root@YOUR_SERVER_IP
```

3. Install dependencies:
```bash
apt update && apt upgrade -y
apt install -y python3 python3-pip python3-venv nginx certbot python3-certbot-nginx
```

4. Clone and setup:
```bash
cd /opt
git clone https://github.com/hydden682/retardio.git
cd retardio/explorer
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

5. Create systemd service:
```bash
cat > /etc/systemd/system/retardio-explorer.service << 'EOF'
[Unit]
Description=Retardio Block Explorer
After=network.target

[Service]
User=root
WorkingDirectory=/opt/retardio/explorer
Environment="PATH=/opt/retardio/explorer/venv/bin"
ExecStart=/opt/retardio/explorer/venv/bin/gunicorn --workers 4 --bind 0.0.0.0:5000 app:app
Restart=always

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable retardio-explorer
systemctl start retardio-explorer
```

6. Setup Nginx reverse proxy:
```bash
cat > /etc/nginx/sites-available/explorer << 'EOF'
server {
    listen 80;
    server_name explorer.retardio.io;  # Change to your domain

    location / {
        proxy_pass http://127.0.0.1:5000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
EOF

ln -s /etc/nginx/sites-available/explorer /etc/nginx/sites-enabled/
nginx -t && systemctl reload nginx
```

7. Add SSL (optional but recommended):
```bash
certbot --nginx -d explorer.retardio.io
```

### Option 4: Docker

```bash
cd explorer
docker build -t retardio-explorer .
docker run -d -p 5000:5000 --name explorer retardio-explorer
```

## Registering Nodes

Nodes can register themselves with the explorer:

### Via API:
```bash
curl -X POST http://explorer.retardio.io/api/nodes/register \
  -H "Content-Type: application/json" \
  -d '{"host": "YOUR_NODE_IP", "port": 18332, "rpc_user": "user", "rpc_pass": "pass"}'
```

### Via Web Interface:
1. Go to the explorer homepage
2. Click "Register Node"
3. Enter your node details

## API Endpoints

| Endpoint | Description |
|----------|-------------|
| GET /api/status | Explorer status |
| GET /api/blocks | Recent blocks |
| GET /api/block/:id | Block details |
| GET /api/tx/:txid | Transaction details |
| GET /api/search?q= | Search |
| GET /api/nodes | Registered nodes |
| POST /api/nodes/register | Register a node |

## Node Requirements

For nodes to work with the explorer, they need:

1. RPC enabled in retardio.conf:
```
server=1
rpcuser=your_user
rpcpassword=your_password
rpcallowip=EXPLORER_SERVER_IP
rpcbind=0.0.0.0
```

2. Port 18332 accessible from the explorer server

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| PORT | 5000 | Server port |
| DATABASE_PATH | explorer.db | SQLite database path |

## Support

For issues, visit: https://github.com/hydden682/retardio/issues
