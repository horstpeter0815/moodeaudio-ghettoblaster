#!/bin/bash
#
# Create Working Image from Current SD Card
# Date: 2026-01-21
#
# This script creates a .img file from your current working SD card
# so you can share it with your friend - complete working configuration!

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
OUTPUT_DIR="$HOME/Downloads"
IMAGE_NAME="moode-10.2-working-$(date +%Y%m%d).img"

echo "=========================================="
echo "Create Working Image from SD Card"
echo "=========================================="
echo ""

# Check if running on macOS
if [[ "$(uname)" != "Darwin" ]]; then
    echo "❌ This script must run on macOS (for diskutil access)"
    exit 1
fi

# Check for SD card
echo "Step 1: Checking for SD card..."
if ! diskutil list | grep -q "disk[0-9]"; then
    echo "❌ No SD card detected. Please insert SD card with working moOde."
    exit 1
fi

SD_DISK=$(diskutil list | grep "disk[0-9]" | tail -1 | awk '{print $NF}')
echo "✅ SD card detected: $SD_DISK"

# Check if SD card is mounted
if diskutil info "/dev/$SD_DISK" | grep -q "Mounted:.*Yes"; then
    echo "✅ SD card is mounted"
else
    echo "❌ SD card is not mounted. Please mount it first."
    exit 1
fi

# Confirm before proceeding
echo ""
echo "=========================================="
echo "WARNING: This will create an image file"
echo "=========================================="
echo "SD Card: $SD_DISK"
echo "Output: $OUTPUT_DIR/$IMAGE_NAME"
echo "Size: Will be same as SD card (check diskutil list)"
echo ""
read -p "Continue? (yes/no): " CONFIRM
if [[ "$CONFIRM" != "yes" ]]; then
    echo "Aborted."
    exit 0
fi

# Unmount SD card
echo ""
echo "Step 2: Unmounting SD card..."
diskutil unmountDisk "/dev/$SD_DISK" 2>/dev/null || true
sleep 2

# Get SD card size
echo ""
echo "Step 3: Getting SD card size..."
SD_SIZE=$(diskutil info "/dev/$SD_DISK" | grep "Disk Size" | awk '{print $3}' | sed 's/[^0-9]//g')
echo "SD card size: ${SD_SIZE} bytes"

# Create image file
echo ""
echo "Step 4: Creating image file..."
echo "This will take 5-10 minutes depending on SD card size..."
echo "Output: $OUTPUT_DIR/$IMAGE_NAME"
echo ""

# Create image using dd
sudo dd if="/dev/r${SD_DISK}" of="$OUTPUT_DIR/$IMAGE_NAME" bs=1m status=progress
sync

# Get image size
IMAGE_SIZE=$(ls -lh "$OUTPUT_DIR/$IMAGE_NAME" | awk '{print $5}')
echo ""
echo "✅ Image created successfully!"
echo "   File: $OUTPUT_DIR/$IMAGE_NAME"
echo "   Size: $IMAGE_SIZE"

# Compress image (optional but recommended for sharing)
echo ""
read -p "Compress image to .zip for easier sharing? (yes/no): " COMPRESS
if [[ "$COMPRESS" == "yes" ]]; then
    echo "Compressing image..."
    cd "$OUTPUT_DIR"
    zip -9 "${IMAGE_NAME}.zip" "$IMAGE_NAME"
    ZIP_SIZE=$(ls -lh "${IMAGE_NAME}.zip" | awk '{print $5}')
    echo "✅ Compressed: ${IMAGE_NAME}.zip ($ZIP_SIZE)"
    echo ""
    echo "Share this file with your friend: ${IMAGE_NAME}.zip"
else
    echo ""
    echo "Share this file with your friend: $IMAGE_NAME"
fi

# Remount SD card
echo ""
echo "Remounting SD card..."
diskutil mountDisk "/dev/$SD_DISK" 2>/dev/null || true

echo ""
echo "=========================================="
echo "✅ Image Creation Complete!"
echo "=========================================="
echo ""
echo "Your friend can:"
echo "  1. Download the image file"
echo "  2. Use Balena Etcher or dd to burn to SD card"
echo "  3. Boot and have complete working system!"
echo ""
echo "Image contains:"
echo "  ✅ Complete moOde 10.2 installation"
echo "  ✅ Display: 1280x400 landscape, touch calibrated"
echo "  ✅ Audio: HiFiBerry AMP100, volume optimized"
echo "  ✅ Network: WiFi (NAM YANG 2) configured"
echo "  ✅ Filters: CamillaDSP ready"
echo "  ✅ Radio: 6 stations"
echo "  ✅ All working settings"
