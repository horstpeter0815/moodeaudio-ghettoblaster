#!/bin/bash
################################################################################
# FORCE SD CARD BURNING - Closes Finder, kills processes, force unmounts
# 
# This script aggressively unmounts the SD card by closing Finder windows
# and killing processes that might be accessing it
# Usage: sudo ./BURN_SD_FORCE.sh
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
echo "║  🔥 FORCE SD CARD BURNING (closes Finder, kills processes)   ║"
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

# Close Finder windows showing SD card volumes
echo "🔧 Closing Finder windows on SD card volumes..."
osascript -e 'tell application "Finder" to close windows whose name contains "bootfs"' 2>/dev/null || true
osascript -e 'tell application "Finder" to close windows whose name contains "rootfs"' 2>/dev/null || true
sleep 1

# Kill processes accessing the SD card
echo "🔧 Killing processes accessing SD card..."
lsof 2>/dev/null | grep -i "disk4\|bootfs\|rootfs" | awk '{print $2}' | sort -u | xargs kill -9 2>/dev/null || true
sleep 2

# Force unmount all partitions
echo "🔧 Force unmounting SD card partitions..."
for i in {1..5}; do
    diskutil unmountDisk force "/dev/$SD_DEVICE" 2>/dev/null || true
    sleep 1
done

# Verify unmounted
sleep 2
if mount | grep -q "disk4"; then
    echo "⚠️  Warning: Partitions still mounted after force unmount"
    echo "   Trying eject and wait..."
    diskutil eject "/dev/$SD_DEVICE" 2>/dev/null || true
    sleep 5
    
    # Check if device is still accessible
    if ! diskutil info "/dev/$SD_DEVICE" >/dev/null 2>&1; then
        echo "❌ ERROR: SD card ejected and not accessible"
        echo "   Please physically remove and reinsert the SD card"
        exit 1
    fi
else
    echo "✅ SD card is unmounted"
fi

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
