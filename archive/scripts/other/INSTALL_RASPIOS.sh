#!/bin/bash
# Install Raspberry Pi OS Lite on SD Card
# Usage: ./INSTALL_RASPIOS.sh

set -e

SD_CARD="/dev/disk4"
WORK_DIR="/tmp/raspios_install"

echo "=========================================="
echo "Installing Raspberry Pi OS Lite"
echo "=========================================="

# Check if SD card exists
if [ ! -e "$SD_CARD" ]; then
    echo "ERROR: SD card not found at $SD_CARD"
    exit 1
fi

echo "SD Card: $SD_CARD"
echo ""

# Unmount SD card
echo "Step 1: Unmounting SD card..."
diskutil unmountDisk "$SD_CARD" 2>/dev/null || true
sleep 2

# Download Raspberry Pi OS Lite (if not already downloaded)
echo "Step 2: Downloading Raspberry Pi OS Lite..."
mkdir -p "$WORK_DIR"
cd "$WORK_DIR"

if [ ! -f "raspios_lite.img" ]; then
    echo "Downloading latest Raspberry Pi OS Lite..."
    # Try to get latest version
    LATEST_URL=$(curl -s "https://downloads.raspberrypi.com/raspios_lite_arm64/images/" | grep -oP 'href="raspios_lite_arm64-[0-9-]+/"' | head -1 | sed 's/href="//;s/"//')
    
    if [ -z "$LATEST_URL" ]; then
        # Fallback to known version
        LATEST_URL="raspios_lite_arm64-2024-07-04/"
    fi
    
    IMG_FILE=$(curl -s "https://downloads.raspberrypi.com/raspios_lite_arm64/images/$LATEST_URL" | grep -oP 'href="[^"]*\.img\.xz"' | head -1 | sed 's/href="//;s/"//')
    
    if [ ! -z "$IMG_FILE" ]; then
        echo "Downloading: $IMG_FILE"
        curl -L -o raspios_lite.img.xz "https://downloads.raspberrypi.com/raspios_lite_arm64/images/$LATEST_URL$IMG_FILE"
        echo "Extracting..."
        xz -d raspios_lite.img.xz
    else
        echo "ERROR: Could not find image file"
        exit 1
    fi
else
    echo "Image already downloaded"
fi

# Write image to SD card
echo ""
echo "Step 3: Writing image to SD card..."
echo "WARNING: This will erase all data on $SD_CARD"
echo "Press Ctrl+C to cancel, or wait 5 seconds to continue..."
sleep 5

sudo dd if="$WORK_DIR/raspios_lite.img" of="$SD_CARD" bs=1m status=progress

# Sync
echo ""
echo "Step 4: Syncing..."
sync

# Eject and remount
echo ""
echo "Step 5: Ejecting SD card..."
diskutil eject "$SD_CARD"

echo ""
echo "=========================================="
echo "Installation complete!"
echo "=========================================="
echo "SD card is ready. You can now:"
echo "1. Insert it into Raspberry Pi"
echo "2. Boot the Pi"
echo "3. SSH to it and install tools"
echo ""

