#!/bin/bash
#
# Retardio Alpine Linux RPi5 Image Builder
# Creates a flashable SD card image with pre-installed Retardio node
#

set -e

echo "=============================================="
echo "  Retardio Alpine RPi5 Image Builder"
echo "=============================================="

# Configuration
ALPINE_VERSION="3.19"
ALPINE_ARCH="aarch64"
IMAGE_SIZE="4G"
WORKDIR="$(pwd)/build"
OUTPUT_IMAGE="retardio-alpine-rpi5.img"
ALPINE_URL="https://dl-cdn.alpinelinux.org/alpine/v${ALPINE_VERSION}/releases/${ALPINE_ARCH}/alpine-rpi-${ALPINE_VERSION}.0-${ALPINE_ARCH}.tar.gz"

# Check for root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root or with sudo"
    exit 1
fi

# Check dependencies
for cmd in wget parted mkfs.vfat mkfs.ext4 losetup mount; do
    if ! command -v $cmd &> /dev/null; then
        echo "Required command not found: $cmd"
        exit 1
    fi
done

# Create work directory
mkdir -p "$WORKDIR"
cd "$WORKDIR"

echo ""
echo "[1/8] Downloading Alpine Linux ${ALPINE_VERSION} for ARM64..."
if [ ! -f "alpine-rpi.tar.gz" ]; then
    wget -O alpine-rpi.tar.gz "$ALPINE_URL"
fi

echo ""
echo "[2/8] Creating disk image ($IMAGE_SIZE)..."
dd if=/dev/zero of="$OUTPUT_IMAGE" bs=1M count=4096 status=progress

echo ""
echo "[3/8] Partitioning image..."
parted -s "$OUTPUT_IMAGE" mklabel msdos
parted -s "$OUTPUT_IMAGE" mkpart primary fat32 1MiB 256MiB
parted -s "$OUTPUT_IMAGE" mkpart primary ext4 256MiB 100%
parted -s "$OUTPUT_IMAGE" set 1 boot on

echo ""
echo "[4/8] Setting up loop device..."
LOOP_DEV=$(losetup -f --show -P "$OUTPUT_IMAGE")
BOOT_PART="${LOOP_DEV}p1"
ROOT_PART="${LOOP_DEV}p2"

echo ""
echo "[5/8] Formatting partitions..."
mkfs.vfat -F32 "$BOOT_PART"
mkfs.ext4 "$ROOT_PART"

echo ""
echo "[6/8] Mounting and extracting Alpine..."
mkdir -p mnt/boot mnt/root
mount "$BOOT_PART" mnt/boot
mount "$ROOT_PART" mnt/root

tar -xzf alpine-rpi.tar.gz -C mnt/boot

# Move root filesystem
mv mnt/boot/boot/* mnt/boot/ 2>/dev/null || true

echo ""
echo "[7/8] Installing Retardio overlay..."

# Create retardio user home
mkdir -p mnt/root/home/retardio/.retardio
mkdir -p mnt/root/etc/init.d
mkdir -p mnt/root/etc/local.d
mkdir -p mnt/root/usr/local/bin

# Copy overlay files
cp -r ../overlay/* mnt/root/

# Create headless setup file for Alpine
cat > mnt/boot/headless.apkovl.tar.gz.marker << 'EOF'
# This triggers headless setup
EOF

# Create usercfg.txt for RPi5
cat > mnt/boot/usercfg.txt << 'EOF'
# Retardio Node - RPi5 Configuration
enable_uart=1
dtparam=audio=off
gpu_mem=16
arm_64bit=1
EOF

# Create cmdline.txt
cat > mnt/boot/cmdline.txt << 'EOF'
modules=loop,squashfs,sd-mod,usb-storage quiet console=tty1
EOF

echo ""
echo "[8/8] Cleaning up..."
sync
umount mnt/boot
umount mnt/root
losetup -d "$LOOP_DEV"
rmdir mnt/boot mnt/root mnt

# Compress
echo ""
echo "Compressing image..."
gzip -k "$OUTPUT_IMAGE"

echo ""
echo "=============================================="
echo "  Image created successfully!"
echo "=============================================="
echo ""
echo "Output: $WORKDIR/$OUTPUT_IMAGE"
echo "Compressed: $WORKDIR/${OUTPUT_IMAGE}.gz"
echo ""
echo "Flash to SD card with:"
echo "  gunzip -c ${OUTPUT_IMAGE}.gz | sudo dd of=/dev/sdX bs=4M status=progress"
echo ""
echo "Or use Balena Etcher with the .img file"
echo ""
