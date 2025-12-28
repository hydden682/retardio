# Retardio

A Bitcoin fork with integrated stratum mining pool, designed for solo mining with NerdMiner ESP32 devices.

## Quick Start

### For Pool Operators (VPS Setup)

Run on a fresh Ubuntu 22.04 VPS:
```bash
curl -sSL https://raw.githubusercontent.com/hydden682/retardio/29.x-knots/vps_complete_setup.sh | bash
```

This sets up:
- Retardio node
- Stratum mining pool (port 3333)
- Web dashboard
- All required services

### For Miners

1. Download `Retardio.html` from your pool operator
2. Open it in a browser
3. Generate a wallet and save your private key
4. Configure your miner:
   - Pool: `stratum+tcp://POOL_IP:3333`
   - User: `YOUR_WALLET_ADDRESS`
   - Password: `x`

## Components

| Component | Port | Description |
|-----------|------|-------------|
| Node RPC | 18332 | Bitcoin RPC interface |
| Node P2P | 18333 | Peer-to-peer network |
| Stratum Pool | 3333 | Mining pool (pool_v8.py) |
| Dashboard | 5555 | Pool statistics UI |

## Building from Source

### Linux/macOS
```bash
./autogen.sh
./configure --without-gui --disable-tests --disable-bench
make -j$(nproc)
```

### Raspberry Pi 5
```bash
./scripts/setup_rpi5.sh
```

## Configuration

### Node Configuration (`~/.retardio/data/retardio.conf`)
```
server=1
daemon=1
rpcuser=retardio
rpcpassword=YOUR_SECURE_PASSWORD
rpcport=18332
port=18333
```

### Pool Environment Variables
```bash
export RETARDIO_CLI="/path/to/retardio-cli"
export RETARDIO_DATADIR="$HOME/.retardio/data"
export POOL_PORT=3333
export POOL_ADDRESS="your_mining_address"
export POOL_API_KEY="your_api_key"
```

## Security Notes

- Always generate secure random passwords (setup scripts do this automatically)
- Never commit credentials to version control
- Pool API endpoints require authentication
- RPC should only be bound to localhost unless explicitly needed

## Files

- `pool_v8.py` - Stratum mining pool server
- `pool_ui/` - Web dashboard for pool statistics
- `wallet_standalone.html` - Browser-based wallet generator
- `retardio_all_in_one.html` - Combined wallet + miner interface
- `vps_complete_setup.sh` - One-command VPS setup

## License

Released under the MIT license. See [COPYING](COPYING) for details.

Based on Bitcoin Core and Bitcoin Knots.
