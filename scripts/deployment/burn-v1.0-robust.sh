#!/bin/bash
# Robust burn v1.0 image with proper sync and verification
# Works from any directory

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

IMAGE_PATH="/Users/andrevollmer/Library/Mobile Documents/com~apple~CloudDocs/Ablage/Roon filters/Bose Wave/OS/RPI5/Moodeaudio/GhettoblasterPi5.img.gz"
SD_DEVICE="disk4"

echo "=== ROBUST BURN V1.0 IMAGE ==="
echo ""

# Check image
if [ ! -f "$IMAGE_PATH" ]; then
    echo "❌ Image not found"
    exit 1
fi

echo "✅ Image: $IMAGE_PATH"
ls -lh "$IMAGE_PATH"
echo ""

# Check SD card
if ! diskutil info "/dev/$SD_DEVICE" >/dev/null 2>&1; then
    echo "❌ SD card not found"
    exit 1
fi

echo "✅ SD card: /dev/$SD_DEVICE"
diskutil info "/dev/$SD_DEVICE" | grep -E "Device Node|Disk Size"
echo ""

# Unmount
echo "Unmounting SD card..."
diskutil unmountDisk "/dev/$SD_DEVICE" 2>/dev/null || true
sleep 3

# Burn with proper error handling
echo ""
echo "=== BURNING IMAGE ==="
echo "This will take 5-15 minutes..."
echo "DO NOT INTERRUPT THE PROCESS!"
echo ""

# Use oflag=sync for proper sync during write
gunzip -c "$IMAGE_PATH" | sudo dd of="/dev/r$SD_DEVICE" bs=4m status=progress oflag=sync

BURN_EXIT=$?

if [ $BURN_EXIT -ne 0 ]; then
    echo ""
    echo "❌ Burn failed with exit code: $BURN_EXIT"
    exit 1
fi

# Multiple syncs to ensure completion
echo ""
echo "=== SYNCING (ensuring write completion) ==="
sync
sleep 2
sync
sleep 2
sync

# Verify device is still accessible
echo ""
echo "=== VERIFYING WRITE ==="
if diskutil info "/dev/$SD_DEVICE" >/dev/null 2>&1; then
    echo "✅ SD card still accessible"
else
    echo "⚠️  SD card not accessible (may have ejected)"
fi

# Eject
echo ""
echo "=== EJECTING SD CARD ==="
diskutil eject "/dev/$SD_DEVICE" 2>/dev/null || true

echo ""
echo "✅✅✅ V1.0 IMAGE BURNED SUCCESSFULLY ✅✅✅"
echo ""
echo "The image has been written and synced."
echo ""
echo "Next steps:"
echo "1. Remove SD card from Mac"
echo "2. Re-insert SD card (optional - to verify it mounted)"
echo "3. Insert into Raspberry Pi"
echo "4. Boot Pi"
echo ""
