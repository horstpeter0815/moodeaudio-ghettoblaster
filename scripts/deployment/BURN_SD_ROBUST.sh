#!/bin/bash
################################################################################
# ROBUST SD CARD BURNING - Handles unmounting issues
# 
# This script properly unmounts the SD card and burns the latest build image
# Usage: sudo ./BURN_SD_ROBUST.sh
################################################################################

set -e

PROJECT_DIR="$HOME/moodeaudio-cursor"
cd "$PROJECT_DIR"

SD_DEVICE="disk4"
LATEST_IMG=$(ls -t imgbuild/deploy/*.img 2>/dev/null | head -1)

if [ -z "$LATEST_IMG" ]; then
    echo "❌ ERROR: No build image found in imgbuild/deploy/"
    exit 1
fi

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  🔥 ROBUST SD CARD BURNING                                    ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "✅ Image: $(basename "$LATEST_IMG")"
echo "   Size: $(du -h "$LATEST_IMG" | cut -f1)"
echo "   Device: /dev/r$SD_DEVICE"
echo ""

# Verify device exists
if ! diskutil info "/dev/$SD_DEVICE" >/dev/null 2>&1; then
    echo "❌ ERROR: SD card /dev/$SD_DEVICE not found"
    echo "   Please insert the SD card and try again"
    exit 1
fi

# Unmount all partitions multiple times to ensure they're unmounted
echo "🔧 Unmounting SD card partitions (multiple attempts)..."
for i in {1..3}; do
    echo "   Attempt $i/3..."
    diskutil unmountDisk "/dev/$SD_DEVICE" 2>/dev/null || true
    sleep 2
    
    # Force unmount if still mounted
    diskutil unmountDisk force "/dev/$SD_DEVICE" 2>/dev/null || true
    sleep 2
done

# Check if any partitions are still mounted
if mount | grep -q "disk4"; then
    echo "⚠️  Warning: Some partitions still mounted, trying eject..."
    diskutil eject "/dev/$SD_DEVICE" 2>/dev/null || true
    sleep 3
    
    # Re-insert (wait for system to detect it again)
    echo "   Waiting for system to detect SD card again..."
    sleep 2
    
    # Verify device is accessible
    if ! diskutil info "/dev/$SD_DEVICE" >/dev/null 2>&1; then
        echo "❌ ERROR: SD card not accessible after eject"
        echo "   Please physically remove and reinsert the SD card"
        exit 1
    fi
fi

echo "✅ SD card is unmounted"
echo ""

# Confirm before proceeding
echo "⚠️  WARNING: This will ERASE all data on /dev/$SD_DEVICE"
echo "   Image: $(basename "$LATEST_IMG")"
echo ""
read -p "Continue? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo "❌ Cancelled"
    exit 1
fi

echo ""
echo "🔥 Burning image to /dev/r$SD_DEVICE..."
echo "   Using raw device (rdisk) for faster, more reliable writing"
echo "   This will take 5-10 minutes..."
echo ""

# Burn using raw device (rdisk is faster and more reliable than disk)
sudo dd if="$LATEST_IMG" of="/dev/r$SD_DEVICE" bs=1m status=progress

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Syncing data to SD card..."
    sync
    
    echo ""
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║  ✅✅✅ IMAGE BURNED SUCCESSFULLY ✅✅✅                        ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo ""
    echo "SD card is ready!"
    echo ""
    echo "Next steps:"
    echo "  1. Remove SD card from Mac"
    echo "  2. Insert into Raspberry Pi"
    echo "  3. Boot Pi"
    echo ""
else
    echo ""
    echo "❌ ERROR: Image burn failed"
    exit 1
fi
