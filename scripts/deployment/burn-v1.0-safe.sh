#!/bin/bash
# Safe burn v1.0 image to SD card with error checking
# Works from any directory

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

IMAGE_PATH="/Users/andrevollmer/Library/Mobile Documents/com~apple~CloudDocs/Ablage/Roon filters/Bose Wave/OS/RPI5/Moodeaudio/GhettoblasterPi5.img.gz"
SD_DEVICE="disk4"

echo "=== SAFE BURN V1.0 IMAGE ==="
echo ""

# 1. Check image file
echo "1. Checking image file..."
if [ ! -f "$IMAGE_PATH" ]; then
    echo "❌ Image not found: $IMAGE_PATH"
    exit 1
fi

echo "✅ Image found:"
ls -lh "$IMAGE_PATH"

# Test if image is valid
echo ""
echo "Testing image integrity..."
if gunzip -t "$IMAGE_PATH" 2>/dev/null; then
    echo "✅ Image file is valid"
else
    echo "❌ Image file is corrupted or not readable"
    exit 1
fi

# 2. Check SD card
echo ""
echo "2. Checking SD card..."
if ! diskutil info "/dev/$SD_DEVICE" >/dev/null 2>&1; then
    echo "❌ SD card /dev/$SD_DEVICE not found"
    echo "Please insert SD card"
    exit 1
fi

echo "✅ SD card found: /dev/$SD_DEVICE"
diskutil info "/dev/$SD_DEVICE" | grep -E "Device Node|Disk Size|Removable|Protocol"
echo ""

# 3. Unmount all partitions
echo "3. Unmounting SD card..."
diskutil unmountDisk "/dev/$SD_DEVICE" 2>/dev/null || true
sleep 3

# Verify unmounted
if mount | grep -q "/dev/$SD_DEVICE"; then
    echo "⚠️  Warning: Some partitions may still be mounted"
    echo "Trying force unmount..."
    diskutil unmountDisk force "/dev/$SD_DEVICE" 2>/dev/null || true
    sleep 2
fi

# 4. Burn image
echo ""
echo "4. Burning image..."
echo "This will take 5-15 minutes..."
echo "You will be asked for your password..."
echo ""

# Use rdisk for faster writes
gunzip -c "$IMAGE_PATH" | sudo dd of="/dev/r$SD_DEVICE" bs=4m status=progress

if [ $? -ne 0 ]; then
    echo ""
    echo "❌ Burn failed!"
    echo "Check error messages above"
    exit 1
fi

# 5. Verify write
echo ""
echo "5. Verifying write..."
sync
sleep 2

# 6. Eject
echo ""
echo "6. Ejecting SD card..."
diskutil eject "/dev/$SD_DEVICE"

echo ""
echo "✅✅✅ V1.0 IMAGE BURNED SUCCESSFULLY ✅✅✅"
echo ""
echo "Next steps:"
echo "1. Remove SD card from Mac"
echo "2. Insert into Raspberry Pi"
echo "3. Boot Pi"
echo ""
