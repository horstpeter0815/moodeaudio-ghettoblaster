#!/bin/bash
# Burn v1.0 Ghettoblaster image to SD card
# Works from any directory

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

IMAGE_PATH="/Users/andrevollmer/Library/Mobile Documents/com~apple~CloudDocs/Ablage/Roon filters/Bose Wave/OS/RPI5/Moodeaudio/GhettoblasterPi5.img.gz"

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

# List all disks
echo "=== AVAILABLE DISKS ==="
diskutil list
echo ""

# Ask for SD card device
echo "⚠️  IMPORTANT: Identify your SD card from the list above"
echo "   SD cards are usually: disk2, disk3, disk4, etc."
echo "   DO NOT use disk0 or disk1 (internal drives)"
echo ""
read -p "Enter SD card device (e.g., disk2): " SD_DEVICE

if [ -z "$SD_DEVICE" ]; then
    echo "❌ No device specified"
    exit 1
fi

# Verify it's not internal disk
if [ "$SD_DEVICE" = "disk0" ] || [ "$SD_DEVICE" = "disk1" ]; then
    echo "❌ ERROR: $SD_DEVICE is an internal disk!"
    echo "   Please use an external SD card (disk2, disk3, etc.)"
    exit 1
fi

# Verify device exists
if ! diskutil info "/dev/$SD_DEVICE" >/dev/null 2>&1; then
    echo "❌ Device /dev/$SD_DEVICE not found"
    exit 1
fi

# Show device info
echo ""
echo "=== SD CARD INFO ==="
diskutil info "/dev/$SD_DEVICE" | grep -E "Device Node|Disk Size|Removable|Protocol"
echo ""

# Safety confirmation
echo "⚠️  WARNING: All data on /dev/$SD_DEVICE will be ERASED!"
read -p "Continue? (type 'yes' to confirm): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo "❌ Cancelled"
    exit 0
fi

# Unmount
echo ""
echo "=== UNMOUNTING SD CARD ==="
diskutil unmountDisk "/dev/$SD_DEVICE" 2>/dev/null || true
sleep 2

# Burn image
echo ""
echo "=== BURNING IMAGE ==="
echo "Decompressing and burning (this will take 5-15 minutes)..."
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
echo "✅✅✅ IMAGE BURNED SUCCESSFULLY ✅✅✅"
echo ""
echo "Next steps:"
echo "1. Remove SD card from Mac"
echo "2. Insert into Raspberry Pi"
echo "3. Boot Pi"
echo ""
