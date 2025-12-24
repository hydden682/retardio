# Retardio Pool Configuration Files

This directory contains configuration files for setting up a Retardio mining pool.

## Files

### retardio-coin.json
Coin-specific configuration for pool software (NOMP, node-stratum-pool, etc.)

**Key parameters:**
- Algorithm: SHA-256
- Network magic bytes: 0xfecabeef
- Address prefix: 35 (addresses start with 'F')
- Bech32 prefix: ret

### retardio-pool.json
Pool-specific configuration including:
- Stratum port settings (3032, 3256, 3512)
- Difficulty settings for different miner types
- Payment processing configuration
- RPC connection to Retardio node
- Redis configuration for share tracking

## Usage

### For NOMP (Node Open Mining Portal)

1. **Copy to NOMP directories:**
```bash
cp retardio-coin.json /path/to/node-open-mining-portal/coins/
cp retardio-pool.json /path/to/node-open-mining-portal/pool_configs/
```

2. **Edit retardio-pool.json:**
- Change `CHANGE_THIS_TO_YOUR_POOL_ADDRESS` to your pool's payout address
- Change `CHANGE_THIS_TO_FEE_ADDRESS` to address that receives pool fees
- Update `rpcuser` and `rpcpassword` to match your Retardio node config

3. **Start NOMP:**
```bash
cd /path/to/node-open-mining-portal
node init.js
```

### For Other Pool Software

These configs can be adapted for other stratum pool implementations:
- **node-stratum-pool** - Use similar JSON structure
- **MPOS + stratum-mining** - Convert to Python config format
- **ckpool** - Convert to ckpool's config format

## Configuration Details

### Stratum Port

| Port | Difficulty | Target Miners |
|------|------------|---------------|
| 3032 | 8 (adjusts 1-16384) | All miners (CPU/GPU/ASIC) |

**Note:** The pool uses variable difficulty (VarDiff) to automatically adjust each miner's difficulty based on their hashrate. One port handles all miner types efficiently.

### Variable Difficulty Settings

The pool uses variable difficulty (varDiff) to optimize share submission:
- **targetTime:** 15 seconds per share (optimal for 30s blocks)
- **retargetTime:** 90 seconds to adjust difficulty
- **variancePercent:** 30% allowed variance

### Payment Processing

- **paymentInterval:** 120 seconds (2 minutes)
- **minimumPayment:** 10.0 RET (adjust as needed)
- **maxBlocksPerPayment:** 10 blocks per cycle

## Customization

### Adjusting Difficulty

For faster/slower block times, adjust `diff` values:
```json
"ports": {
    "3032": {
        "diff": 16,  // Increase for faster blocks
        "varDiff": {
            "minDiff": 2,
            "maxDiff": 1024
        }
    }
}
```

### Changing Pool Fees

Adjust the percentage in `rewardRecipients`:
```json
"rewardRecipients": {
    "YOUR_FEE_ADDRESS": 2.0  // 2% pool fee
}
```

### Payment Thresholds

Modify payment settings:
```json
"paymentProcessing": {
    "minimumPayment": 5.0,      // Lower = more frequent payouts
    "paymentInterval": 300       // Higher = less frequent checks
}
```

## Prerequisites

### Retardio Node Requirements

Your node must have these settings in `retardio.conf`:
```ini
server=1
rpcuser=retardiouser
rpcpassword=your_secure_password
rpcport=18332
txindex=1
```

### Redis Server

Pool requires Redis for share tracking:
```bash
# Install Redis
sudo apt-get install redis-server

# Start Redis
sudo systemctl start redis-server
sudo systemctl enable redis-server
```

## Testing Pool Configuration

1. **Start your Retardio node:**
```bash
./start_node.sh
```

2. **Verify RPC connection:**
```bash
curl --user retardiouser:password --data-binary '{"jsonrpc":"1.0","method":"getblockchaininfo","params":[]}' http://127.0.0.1:18332/
```

3. **Start the pool:**
```bash
cd node-open-mining-portal
node init.js
```

4. **Test with a miner:**
```bash
cpuminer -a sha256d -o stratum+tcp://127.0.0.1:3032 -u FyourAddress -p x
```

## Troubleshooting

### Pool won't start

**Check Redis:**
```bash
redis-cli ping
# Should respond with: PONG
```

**Check node connection:**
```bash
# In pool logs, look for:
# "RPC connected to Retardio daemon"
```

### No shares submitted

**Verify difficulty:**
- Too high: Miners can't find shares
- Too low: Too many shares, pool overloaded

**Check miner connection:**
```bash
# In pool logs, look for:
# "Client connected: 192.168.1.100"
```

### Payments not processing

**Verify:**
- Node wallet is unlocked
- Pool address has sufficient balance for tx fees
- Minimum payment threshold is reached

**Check logs:**
```bash
tail -f /path/to/node-open-mining-portal/logs/payments.log
```

## Security Recommendations

1. **Change default RPC password** - Use a strong, unique password
2. **Firewall RPC port** - Only allow localhost or trusted IPs
3. **Use SSL/TLS** - For production pools, use SSL for stratum
4. **Monitor pool wallet** - Keep only necessary funds in hot wallet
5. **Regular backups** - Backup pool database and wallet.dat

## Support

For more information:
- **NOMP Documentation:** https://github.com/zone117x/node-open-mining-portal
- **Retardio Mining Guide:** See ../MINING_SETUP.md
- **Quick Start:** See ../QUICKSTART.md

---

**Note:** These configurations are designed for NOMP but can be adapted for other pool software. The key parameters (algorithm, ports, difficulty) remain the same across different implementations.
