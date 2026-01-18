#!/bin/bash
# Burn v1.0 image to SD card (disk4) - non-interactive
# Works from any directory

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

IMAGE_PATH="/Users/andrevollmer/Library/Mobile Documents/com~apple~CloudDocs/Ablage/Roon filters/Bose Wave/OS/RPI5/Moodeaudio/GhettoblasterPi5.img.gz"
SD_DEVICE="disk4"

echo "=== BURN V1.0 IMAGE TO SD CARD ==="
echo ""

# Check if image exists
if [ ! -f "$IMAGE_PATH" ]; then
    echo "❌ Image not found: $IMAGE_PATH"
    exit 1
fi

echo "✅ Image found:"
ls -lh "$IMAGE_PATH"
echo ""

# Verify SD card exists
if ! diskutil info "/dev/$SD_DEVICE" >/dev/null 2>&1; then
    echo "❌ SD card /dev/$SD_DEVICE not found"
    echo "Please insert SD card or specify different device"
    exit 1
fi

echo "✅ SD card found: /dev/$SD_DEVICE"
diskutil info "/dev/$SD_DEVICE" | grep -E "Device Node|Disk Size|Removable"
echo ""

# Unmount
echo "=== UNMOUNTING SD CARD ==="
diskutil unmountDisk "/dev/$SD_DEVICE" 2>/dev/null || true
sleep 2

# Burn image
echo ""
echo "=== BURNING IMAGE ==="
echo "Decompressing and burning (this will take 5-15 minutes)..."
echo "You will be asked for your password..."
echo ""

gunzip -c "$IMAGE_PATH" | sudo dd of="/dev/r$SD_DEVICE" bs=4m status=progress

# Sync
echo ""
echo "=== SYNCING ==="
sync

# Eject
echo ""
echo "=== EJECTING SD CARD ==="
diskutil eject "/dev/$SD_DEVICE"

echo ""
echo "✅✅✅ V1.0 IMAGE BURNED SUCCESSFULLY ✅✅✅"
echo ""
echo "Next steps:"
echo "1. Remove SD card from Mac"
echo "2. Insert into Raspberry Pi"
echo "3. Boot Pi"
echo ""
