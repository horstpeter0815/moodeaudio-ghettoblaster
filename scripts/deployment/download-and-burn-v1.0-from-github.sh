#!/bin/bash
# Download v1.0 image from GitHub and burn to SD card
# Works from any directory

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

GITHUB_REPO="horstpeter0815/moodeaudio-ghettoblaster"
IMAGE_NAME="GhettoblasterPi5.img.gz"

echo "=== DOWNLOAD V1.0 IMAGE FROM GITHUB ==="
echo ""
echo "Repository: $GITHUB_REPO"
echo ""

# Check for local image first
LOCAL_IMAGE="$HOME/Library/Mobile Documents/com~apple~CloudDocs/Ablage/Roon filters/Bose Wave/OS/RPI5/Moodeaudio/$IMAGE_NAME"
if [ -f "$LOCAL_IMAGE" ]; then
    echo "✅ Found local image: $LOCAL_IMAGE"
    IMAGE_PATH="$LOCAL_IMAGE"
else
    echo "⚠️  Local image not found, checking GitHub releases..."
    
    # Try to download from GitHub releases
    RELEASES_URL="https://api.github.com/repos/$GITHUB_REPO/releases/latest"
    DOWNLOAD_URL=$(curl -s "$RELEASES_URL" | grep "browser_download_url.*$IMAGE_NAME" | cut -d '"' -f 4 | head -1)
    
    if [ -n "$DOWNLOAD_URL" ]; then
        echo "✅ Found image in GitHub releases"
        echo "Downloading from: $DOWNLOAD_URL"
        
        DOWNLOAD_DIR="$HOME/Downloads"
        mkdir -p "$DOWNLOAD_DIR"
        IMAGE_PATH="$DOWNLOAD_DIR/$IMAGE_NAME"
        
        echo "Downloading to: $IMAGE_PATH"
        curl -L -o "$IMAGE_PATH" "$DOWNLOAD_URL"
        
        if [ $? -eq 0 ]; then
            echo "✅ Download complete"
        else
            echo "❌ Download failed"
            exit 1
        fi
    else
        echo "❌ Image not found in GitHub releases"
        echo ""
        echo "Please provide image location:"
        echo "1. Local path to image file"
        echo "2. Or ensure image is in GitHub releases"
        exit 1
    fi
fi

echo ""
echo "✅ Image ready: $IMAGE_PATH"
ls -lh "$IMAGE_PATH"
echo ""

# List disks
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
echo "✅✅✅ V1.0 IMAGE BURNED SUCCESSFULLY ✅✅✅"
echo ""
echo "Next steps:"
echo "1. Remove SD card from Mac"
echo "2. Insert into Raspberry Pi"
echo "3. Boot Pi"
echo ""
