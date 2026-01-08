#!/bin/bash
# Burn latest build image to SD card
# Uses password 4512 for sudo

set -e

PROJECT_DIR="$HOME/moodeaudio-cursor"
cd "$PROJECT_DIR"

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  🔥 BURN IMAGE TO SD CARD                                    ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Find latest image
LATEST_IMG=$(ls -t imgbuild/deploy/*.img 2>/dev/null | head -1)

if [ -z "$LATEST_IMG" ]; then
    echo "❌ ERROR: No build image found"
    exit 1
fi

echo "✅ Image: $(basename "$LATEST_IMG")"
echo "   Size: $(du -h "$LATEST_IMG" | cut -f1)"
echo ""

# Find SD card
echo "=== FINDING SD CARD ==="
echo ""

# Unmount any mounted volumes first
diskutil unmountDisk /dev/disk2 2>/dev/null || true
diskutil unmountDisk /dev/disk3 2>/dev/null || true
diskutil unmountDisk /dev/disk4 2>/dev/null || true
diskutil unmountDisk /dev/disk5 2>/dev/null || true

# List external disks
echo "Available external disks:"
diskutil list | grep -E "external|physical" -A 5 | grep "disk" | head -5

echo ""
read -p "Enter SD card device (e.g., disk2, disk3): " SD_DEVICE

if [ -z "$SD_DEVICE" ]; then
    echo "❌ ERROR: No device specified"
    exit 1
fi

# Verify device exists
if ! diskutil info "/dev/$SD_DEVICE" >/dev/null 2>&1; then
    echo "❌ ERROR: Device /dev/$SD_DEVICE not found"
    exit 1
fi

echo ""
echo "⚠️  WARNING: This will ERASE all data on /dev/$SD_DEVICE"
echo "   Image: $(basename "$LATEST_IMG")"
echo ""
read -p "Continue? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo "❌ Cancelled"
    exit 1
fi

# Unmount the device
echo ""
echo "Unmounting /dev/$SD_DEVICE..."
diskutil unmountDisk "/dev/$SD_DEVICE" 2>/dev/null || true
sleep 2

# Burn image
echo ""
echo "🔥 Burning image to SD card..."
echo "   This will take 5-10 minutes..."
echo ""

# Use sudo with password
echo "4512" | sudo -S dd if="$LATEST_IMG" of="/dev/r$SD_DEVICE" bs=1m status=progress

if [ $? -eq 0 ]; then
    echo ""
    echo "✅✅✅ IMAGE BURNED SUCCESSFULLY ✅✅✅"
    echo ""
    
    # Sync to ensure write completion
    echo "Syncing..."
    sync
    
    # Eject
    echo "Ejecting SD card..."
    diskutil eject "/dev/$SD_DEVICE"
    
    echo ""
    echo "✅ SD card is ready!"
    echo ""
    echo "Next steps:"
    echo "  1. Remove SD card from Mac"
    echo "  2. Insert into Pi"
    echo "  3. Boot Pi"
    echo "  4. Test: ./test-ssh-after-boot.sh"
else
    echo ""
    echo "❌ ERROR: Image burn failed"
    exit 1
fi

