#!/bin/bash
#########################################################################
# Burn to SD Card Tool - Burn any image to SD card
# Usage: ./burn-to-sd.sh <image-path> [device]
# Example: ./burn-to-sd.sh moode-FIXED.img /dev/disk4
#########################################################################

set -e

IMAGE_PATH="${1}"
SD_DISK="${2:-/dev/disk4}"
SD_RDISK="${SD_DISK/disk/rdisk}"

if [ -z "$IMAGE_PATH" ]; then
    echo "Usage: $0 <image-path> [device]"
    echo "Example: $0 /path/to/moode.img /dev/disk4"
    exit 1
fi

if [ ! -f "$IMAGE_PATH" ]; then
    echo "❌ Error: Image file not found: $IMAGE_PATH"
    exit 1
fi

echo "========================================="
echo "BURN IMAGE TO SD CARD"
echo "========================================="
echo ""
echo "Image: $IMAGE_PATH"
echo "Size: $(ls -lh "$IMAGE_PATH" | awk '{print $5}')"
echo "Target: $SD_RDISK"
echo ""
echo "⚠️  WARNING: This will ERASE all data on $SD_DISK!"
echo ""
read -p "Continue? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo "❌ Cancelled"
    exit 1
fi

echo ""
echo "=== Unmounting SD card ==="
diskutil unmountDisk force "$SD_DISK"

echo ""
echo "=== Burning image (this will take 5-10 minutes) ==="
echo "Progress will be shown..."
sudo dd if="$IMAGE_PATH" of="$SD_RDISK" bs=1m conv=sync status=progress

echo ""
echo "=== Syncing ==="
sync

echo ""
echo "=== Ejecting SD card ==="
diskutil eject "$SD_DISK"

echo ""
echo "========================================="
echo "✅ SD CARD READY!"
echo "========================================="
echo ""
echo "Next steps:"
echo "  1. Insert SD card into Raspberry Pi"
echo "  2. Power on"
echo "  3. Wait for first boot"
echo ""
