# Retardio Alpine Linux RPi5 Image

Pre-built Alpine Linux image with Retardio node ready to run on Raspberry Pi 5.

## Quick Start

### Option 1: Download Pre-Built Image (Easiest)

```bash
# Download the image
wget https://github.com/hydden682/retardio/releases/download/v29.2.0/retardio-alpine-rpi5.img.gz

# Flash to SD card (replace /dev/sdX with your SD card)
gunzip -c retardio-alpine-rpi5.img.gz | sudo dd of=/dev/sdX bs=4M status=progress
sync
```

Or use **Balena Etcher** to flash the `.img.gz` file directly.

### Option 2: Build Image Yourself

```bash
git clone https://github.com/hydden682/retardio.git -b 29.x-knots
cd retardio/alpine-rpi5-image
sudo ./build_image.sh
```

---

## First Boot

1. Insert SD card into RPi5
2. Connect power and Ethernet
3. Wait 2-3 minutes for first-boot setup
4. SSH into the Pi:

```bash
ssh retardio@retardio-node.local
# Password: retardio
```

1. **Change the default password!**

```bash
passwd
```

---

## Default Credentials

| Item | Value |
|------|-------|
| Username | `retardio` |
| Password | `retardio` |
| RPC Port | `22555` |
| P2P Port | `22556` |

---

## Check Node Status

```bash
# Blockchain info
retardio-cli getblockchaininfo

# Network info  
retardio-cli getnetworkinfo

# View logs
rc-service retardiod status
tail -f /home/retardio/.retardio/debug.log
```

---

## Service Commands (Alpine/OpenRC)

```bash
# Start node
rc-service retardiod start

# Stop node
rc-service retardiod stop

# Restart node
rc-service retardiod restart

# Enable at boot
rc-update add retardiod default
```

---

## Configuration

Edit: `/home/retardio/.retardio/retardio.conf`

```bash
nano /home/retardio/.retardio/retardio.conf
rc-service retardiod restart
```

---

## What's Included

- **Alpine Linux 3.19** (64-bit ARM)
- **Retardio Node** pre-compiled for ARM64
- **OpenRC service** for automatic startup
- **First-boot setup** with auto-generated RPC password
- **Optimized config** for 4GB RAM RPi5

---

## Image Contents

```
/
├── home/retardio/
│   └── .retardio/
│       └── retardio.conf      # Node configuration
├── usr/local/bin/
│   ├── retardiod              # Node daemon
│   └── retardio-cli           # CLI tool
└── etc/
    ├── init.d/retardiod       # OpenRC init script
    └── local.d/retardio-setup.start  # First-boot script
```

---

## Building from Source (on the Pi)

If you need to rebuild from source:

```bash
# Install build dependencies
apk add build-base cmake ninja git python3 \
    boost-dev libressl-dev libevent-dev \
    sqlite-dev miniupnpc-dev

# Clone and build
git clone https://github.com/hydden682/retardio.git -b 29.x-knots
cd retardio && mkdir build && cd build
cmake -G Ninja .. -DBUILD_GUI=OFF -DCMAKE_BUILD_TYPE=Release
ninja -j2
sudo ninja install
```

---

## Troubleshooting

### Can't SSH in

- Wait 3-5 minutes for first boot
- Check if Pi got IP: `arp -a | grep raspberry`
- Connect monitor to see boot messages

### Node won't start

```bash
cat /home/retardio/.retardio/debug.log
```

### Out of memory

Edit `/home/retardio/.retardio/retardio.conf`:

```
dbcache=256
maxmempool=50
```
