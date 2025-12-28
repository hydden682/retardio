# Changelog

All notable changes to Retardio will be documented in this file.

## [1.1.0] - 2025-12-27

### Security Fixes
- **CRITICAL**: Fixed wallet generation to use proper secp256k1 elliptic curve cryptography
  - Previous versions used SHA256 hash instead of EC point multiplication
  - Wallets generated with previous versions should be considered insecure
- **CRITICAL**: Fixed coinbase output to use proper P2PKH instead of OP_TRUE
  - Previous versions had anyone-can-spend coinbase outputs
- Removed hardcoded credentials from all setup scripts
  - Setup scripts now generate secure random passwords using `openssl rand`
- Disabled Flask debug mode in pool_ui (prevented potential RCE)
- Added API key authentication to block submission endpoint

### Added
- `wallet_standalone.html` now uses noble-secp256k1 library for proper cryptography
- Settings modal in `wallet_gui.html` for configurable RPC credentials
- Credentials file generation (`~/.retardio/credentials`) during setup
- Environment variable configuration for pool_v8.py:
  - `RETARDIO_CLI` - Path to retardio-cli
  - `RETARDIO_DATADIR` - Data directory path
  - `POOL_PORT` - Stratum pool port
  - `POOL_ADDRESS` - Mining reward address
- API key authentication for pool dashboard (`POOL_API_KEY` env var)

### Changed
- pool_v8.py version bumped to 8.1
- pool_ui/app.py version bumped to 1.1
- Improved BIP34 height encoding in coinbase transactions
- Job history limited to prevent memory leaks

### Removed
- Obsolete pool versions: pool_debug.py, pool_fixed.py, pool_server.py, pool_v4.py through pool_v7.py
- Hardcoded credentials from all configuration files

### Migration Notes
- **Wallet Migration**: If you generated wallets with version 1.0.0, those private keys may not correspond to valid addresses. Generate new wallets with this version.
- **Pool Operators**: Set the `POOL_API_KEY` environment variable before starting the pool UI service.
- **Existing Installations**: Re-run setup scripts to regenerate secure credentials.

## [1.0.0] - 2025-12-26

### Added
- Initial release
- Bitcoin fork with Retardio branding
- Stratum mining pool (pool_v8.py)
- Pool dashboard UI
- Browser-based wallet generation
- VPS setup script
- Raspberry Pi 5 setup script
