# Retardio Wallet 🚀

> **A high-performance, secure cryptocurrency wallet built with pure-Rust and compiled to WebAssembly (WASM).**

![License](https://img.shields.io/badge/license-MIT-blue.svg)
![Rust](https://img.shields.io/badge/built_with-Rust-orange.svg)
![WASM](https://img.shields.io/badge/compiles_to-WASM-purple.svg)

## Overview

Retardio Wallet represents the next generation of browser-based crypto storage. By leveraging **Rust** for all cryptographic operations and **WebAssembly (WASM)** for execution, it offers native-level performance and type safety within a standard web environment.

**Key Features:**

* **🛡️ Pure-Rust Core**: No JS crypto libraries. All logic uses `k256`, `sha2`, and `ripemd` from the Rust ecosystem.
* **🔐 HD Wallet Support (BIP-32)**: Implements Hierarchical Deterministic key derivation with hardened paths (`m/44'/0'/0'/0/0`).
* **📝 RIP-0 Mnemonic Standard**: Supports 24-word recovery phrases with optional **Passphrase (Salt)** protection (BIP-39).
* **💎 Premium UI**: A futuristic, glassmorphic interface built with Vanilla JS and CSS variables (Dark/Gold theme).
* **🦊 Dashboard Experience**: Includes a MetaMask-style balance and token management view.
* **⚡ Electron Ready**: Can be run as a standalone desktop application.

## Prerequisites

* **Rust**: Stable toolchain (`rustc`, `cargo`).
* **Wasm-Pack**: `cargo install wasm-pack`.
* **Node.js**: v14+ (for development server and Electron).

## Quick Start

1. **Clone the repository:**

    ```bash
    git clone https://github.com/gfdhefhsfhsfhsfhsff/retardio-wallet.git
    cd retardio-wallet
    ```

2. **Install JS Dependencies:**

    ```bash
    npm install
    ```

3. **Build WASM Module:**

    ```bash
    # For Web Target
    wasm-pack build --target web
    ```

4. **Run Application:**

    ```bash
    # Runs Electron Desktop App
    npm start
    ```

    *Alternatively, serve `index.html` with any static server (e.g., `npx serve .`).*

## Security Architecture

* **Private Keys**: Never leave the WASM memory space until explicitly requested by the user.
* **Memory Hygiene**: Mnemonic phrases are cleared from UI elements immediately after backup.
* **Key Derivation**: Uses `PBKDF2` with HMAC-SHA512 for seed generation (BIP-39 standard).
* **Address Format**: Base58Check encoding with custom version bytes for the Retardio network.

## Testing

Run the Node.js validation script to verify cryptographic correctness without the browser:

```bash
# Build for Node.js
wasm-pack build --target nodejs

# Run Test Script
node test_wallet.js
```

## Disclaimer

This wallet is strictly for educational purposes and the Retardio Network. Use at your own risk. Always back up your 24-word recovery phrase.
