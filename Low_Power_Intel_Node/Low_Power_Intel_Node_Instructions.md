# Low Power Intel Node Instructions

**Target Hardware:** Intel N100 / N95 / N5105 Mini PCs
**Target OS:** Ubuntu 22.04 LTS or Debian 12 (Bookworm)
**Recommended Specs:** 16GB RAM, 500GB+ SSD

## 1. Preparation

Copy the deployment script to your Mini PC.

**Option A: If you have SSH access**
Run this from your main computer (replace `user@minipc-ip` with your actual login):

```bash
scp Low_Power_Intel_Node.sh user@192.168.1.XX:~/
```

**Option B: Download directly on the Mini PC**
If you are on the Mini PC's terminal:

1. Create the file:

   ```bash
   nano Low_Power_Intel_Node.sh
   ```

2. Paste the contents of the script.
3. Save and exit (`Ctrl+O`, `Enter`, `Ctrl+X`).

## 2. Installation

1. **Make the script executable:**

   ```bash
   chmod +x Low_Power_Intel_Node.sh
   ```

2. **Run the installer:**

   ```bash
   ./Low_Power_Intel_Node.sh
   ```

   *Note: You will be prompted for your `sudo` password to install dependencies.*

3. **Wait for completion:**
   The script will:
   - Install all necessary build tools.
   - Clone the Retardio repository.
   - Compile the node using all available CPU cores.
   - Configure the node settings optimized for 16GB RAM.
   - Create and enable a systemd service (`retardiod`).

## 3. Post-Installation

The node is configured to start automatically on boot.

**Check Status:**

```bash
sudo systemctl status retardiod
```

**Follow Logs:**

```bash
sudo journalctl -fn 100 -u retardiod
```

**Check Block Height:**

```bash
retardio-cli -conf=$HOME/.retardio/retardio.conf getblockchaininfo
```

## 4. Optimization Details

This setup is tuned for Low Power Intel chips (N-series):

- **DB Cache:** Set to 4096MB (4GB) to utilize the 16GB RAM effectively, reducing disk I/O.
- **Parallel Build:** Uses all 4 cores (`-j4`) for faster compilation.
- **Connections:** Max connections set to 125 to balance network load with CPU usage.
