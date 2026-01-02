# AMD System Node Instructions

**Target Hardware:** AMD Ryzen 5/7/9, Threadripper, or EPYC Systems
**Target OS:** Ubuntu 22.04 LTS or Debian 12 (Bookworm)
**Recommended Specs:** 16GB+ RAM (32GB+ for Max Performance), NVMe SSD at least 1TB

## 1. Preparation

Copy the deployment script to your AMD System.

**Option A: If you have SSH access**
Run this from your main computer (replace `user@amd-ip` with your actual login):

```bash
scp AMD_System_Node.sh user@192.168.1.XX:~/
```

**Option B: Download directly on the Machine**
If you are on the terminal:

1. Create the file:

   ```bash
   nano AMD_System_Node.sh
   ```

2. Paste the contents of the script.
3. Save and exit (`Ctrl+O`, `Enter`, `Ctrl+X`).

## 2. Installation

1. **Make the script executable:**

   ```bash
   chmod +x AMD_System_Node.sh
   ```

2. **Run the installer:**

   ```bash
   ./AMD_System_Node.sh
   ```

3. **Wait for completion:**
   The script will:
   - Install build tools.
   - Clone the Retardio repository.
   - **Auto-Detect RAM**:
     - > 32GB RAM: Sets `dbcache=16384` (16GB) and `maxconnections=250` for high performance.
     - > 16GB RAM: Sets `dbcache=4096` (4GB) and `maxconnections=125`.
   - Compile utilizing **all available threads** (Ryzen CPUs benefit greatly here).
   - Configure the node and auto-start service.

## 3. Post-Installation

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

## 4. Performance Tuning

This script is optimized for Multi-Core AMD Performance:

- **Parallel Compilation**: Uses every core available to speed up the build process significantly.
- **Large Mempool**: `maxmempool` set to 512MB to handle higher transaction throughput.
- **High Concurrency**: Adjusted thread counts (`par` parameter) to match your CPU cores.
