# Raspberry Pi Zero 2 W "Firmware" Instructions

**Objective:** Turn a generic Raspberry Pi Zero 2 W into a dedicated Retardio Miner.
**Hardware:** Raspberry Pi Zero 2 W (512MB RAM), 16GB+ MicroSD Card.
**OS:** Raspberry Pi OS Lite (64-bit recommended, or 32-bit if unstable).

## 1. Prepare the SD Card

Since the Pi Zero 2 W is slow to setup, we start with a clean OS.

1. Download **Raspberry Pi Imager**.
2. Choose OS: **Raspberry Pi OS (other) -> Raspberry Pi OS Lite (64-bit)**.
3. Choose Storage: Your MicroSD card.
4. **Settings (Gear Icon)**:
    * Set Hostname: `retardio-miner`
    * Enable SSH: Use password authentication.
    * Set Username: `retardio` (or your preference).
    * Set Password.
    * Configure Wireless LAN: **Crucial** - Enter your WiFi SSID and Password correctly.
5. **Write** the image.

## 2. Install the Firmware Script

Power on the Pi Zero 2 W and wait 2-3 minutes for it to connect to WiFi.

**Option A: SSH from PC**

```bash
scp RPi_Zero_2W_Setup.sh retardio@retardio-miner.local:~/
ssh retardio@retardio-miner.local
```

**Option B: On the Device**
(If you have a monitor/keyboard attached)

1. Login.
2. Create file: `nano RPi_Zero_2W_Setup.sh`
3. Paste the script content.
4. Save and exit.

## 3. Flash & Build

**WARNING: This process will take 2-4 hours due to the slow CPU.**

1. Run the setup:

    ```bash
    chmod +x RPi_Zero_2W_Setup.sh
    ./RPi_Zero_2W_Setup.sh
    ```

2. **What it does:**
    * Creates a **2GB Swap File** (Essential - do not skip).
    * Installs dependencies.
    * Downloads Retardio Switch.
    * Compiles the miner in "Low Memory Mode".
    * Configures `retardiod` to **mine automatically** (`gen=1`).
    * Installs a system boot service.

## 4. Mining

Once the script finishes, the device will output "Setup Complete".

* **Reboot** to ensure everything starts clean: `sudo reboot`.
* The miner starts automatically in the background.

**Monitor Mining:**

```bash
# Check if running
sudo systemctl status retardio-miner

# Check mining hashrate
retardio-cli -conf=~/.retardio/retardio.conf getmininginfo
```

Your Pi Zero 2 W is now a dedicated Retardio mining node.
