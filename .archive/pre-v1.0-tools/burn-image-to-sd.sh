#!/bin/bash
# Check for built image and burn to SD card
# Interactive script to find image and SD card, then burn

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "=========================================="
echo "Burn Image to SD Card"
echo "=========================================="
echo ""

# Check if running on macOS
if [[ "$(uname)" != "Darwin" ]]; then
    echo -e "${RED}✗${NC} This script is for macOS only"
    exit 1
fi

# Look for image files
echo -e "${BLUE}[1]${NC} Looking for built images..."
echo ""

IMAGE_FILE=""
IMAGE_ZIP=""

# Check deploy directory
DEPLOY_DIR="${WORKSPACE_ROOT}/imgbuild/deploy"
if [ -d "$DEPLOY_DIR" ]; then
    # Look for .img files
    if ls "$DEPLOY_DIR"/*.img 2>/dev/null | grep -q .; then
        IMAGE_FILE=$(ls -t "$DEPLOY_DIR"/*.img 2>/dev/null | head -1)
        echo -e "${GREEN}✓${NC} Found image: $IMAGE_FILE"
    fi
    
    # Look for .zip files
    if ls "$DEPLOY_DIR"/*.zip 2>/dev/null | grep -q .; then
        IMAGE_ZIP=$(ls -t "$DEPLOY_DIR"/*.zip 2>/dev/null | head -1)
        echo -e "${GREEN}✓${NC} Found zip: $IMAGE_ZIP"
    fi
fi

# Check alternative locations
if [ -z "$IMAGE_FILE" ] && [ -z "$IMAGE_ZIP" ]; then
    # Check iCloud location (from burn scripts)
    ICLOUD_IMG="/Users/andrevollmer/Library/Mobile Documents/com~apple~CloudDocs/Ablage/Roon filters/Bose Wave/OS/RPI5/Moodeaudio/GhettoblasterPi5.img.gz"
    if [ -f "$ICLOUD_IMG" ]; then
        echo -e "${GREEN}✓${NC} Found image in iCloud: $ICLOUD_IMG"
        IMAGE_FILE="$ICLOUD_IMG"
    fi
fi

# If still no image, check if deploy directory exists but is empty
if [ -z "$IMAGE_FILE" ] && [ -z "$IMAGE_ZIP" ]; then
    echo -e "${YELLOW}⚠${NC} No image file found"
    echo ""
    echo "Checked locations:"
    echo "  - ${DEPLOY_DIR}/*.img"
    echo "  - ${DEPLOY_DIR}/*.zip"
    echo "  - iCloud location"
    echo ""
    echo "The build may not be complete yet, or the image is in a different location."
    echo ""
    echo "To check build status:"
    echo "  ./scripts/check-build-status.sh"
    echo ""
    echo "Or check manually:"
    echo "  ls -lh imgbuild/deploy/"
    echo ""
    exit 1
fi

# Determine which image to use
FINAL_IMAGE=""
if [ -n "$IMAGE_FILE" ]; then
    FINAL_IMAGE="$IMAGE_FILE"
    echo -e "${GREEN}✓${NC} Using image: $FINAL_IMAGE"
elif [ -n "$IMAGE_ZIP" ]; then
    echo -e "${YELLOW}⚠${NC} Found zip file, need to extract first"
    echo "  $IMAGE_ZIP"
    echo ""
    read -p "Extract zip file now? (y/n) " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Extracting..."
        cd "$DEPLOY_DIR"
        unzip -o "$IMAGE_ZIP"
        FINAL_IMAGE=$(ls -t *.img 2>/dev/null | head -1)
        if [ -n "$FINAL_IMAGE" ]; then
            FINAL_IMAGE="${DEPLOY_DIR}/${FINAL_IMAGE}"
            echo -e "${GREEN}✓${NC} Extracted: $FINAL_IMAGE"
        else
            echo -e "${RED}✗${NC} Failed to extract image"
            exit 1
        fi
    else
        echo "Exiting. Extract manually and run again."
        exit 0
    fi
fi

echo ""

# Find SD card
echo -e "${BLUE}[2]${NC} Looking for SD card..."
echo ""

SD_DEVICE=""
SD_DEVICES=$(diskutil list | grep -i "external\|physical" | grep -E "disk[0-9]+" | awk '{print $1}' || true)

if [ -z "$SD_DEVICES" ]; then
    echo -e "${RED}✗${NC} No SD card found!"
    echo ""
    echo "Please:"
    echo "  1. Insert SD card"
    echo "  2. Wait for it to mount"
    echo "  3. Run this script again"
    echo ""
    echo "Or check manually:"
    echo "  diskutil list"
    exit 1
fi

# If multiple devices, let user choose
if [ $(echo "$SD_DEVICES" | wc -l) -gt 1 ]; then
    echo "Multiple SD card devices found:"
    echo "$SD_DEVICES" | nl
    echo ""
    read -p "Enter device number (e.g., 1 for disk2): " DEV_NUM
    SD_DEVICE=$(echo "$SD_DEVICES" | sed -n "${DEV_NUM}p" | awk '{print $1}')
else
    SD_DEVICE=$(echo "$SD_DEVICES" | head -1 | awk '{print $1}')
fi

if [ -z "$SD_DEVICE" ]; then
    echo -e "${RED}✗${NC} Invalid device selection"
    exit 1
fi

echo -e "${GREEN}✓${NC} Selected SD card: $SD_DEVICE"
diskutil info "/dev/$SD_DEVICE" | grep -E "Device Node|Disk Size|Removable" || true
echo ""

# Confirm before burning
echo "=========================================="
echo "Ready to Burn"
echo "=========================================="
echo ""
echo "Image: $FINAL_IMAGE"
echo "SD Card: /dev/$SD_DEVICE"
echo ""
echo -e "${YELLOW}⚠${NC} WARNING: This will erase all data on the SD card!"
echo ""
read -p "Continue? (y/n) " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cancelled."
    exit 0
fi

echo ""
echo "=========================================="
echo "Burning Image"
echo "=========================================="
echo ""

# Unmount SD card
echo "[1/4] Unmounting SD card..."
diskutil unmountDisk "/dev/$SD_DEVICE" 2>/dev/null || true
sleep 2

# Check if image is compressed
if [[ "$FINAL_IMAGE" == *.gz ]]; then
    echo "[2/4] Decompressing and burning image..."
    echo "      (This will take 5-15 minutes...)"
    gunzip -c "$FINAL_IMAGE" | sudo dd of="/dev/r$SD_DEVICE" bs=4m status=progress
else
    echo "[2/4] Burning image..."
    echo "      (This will take 5-15 minutes...)"
    sudo dd if="$FINAL_IMAGE" of="/dev/r$SD_DEVICE" bs=4m status=progress
fi

if [ $? -ne 0 ]; then
    echo ""
    echo -e "${RED}✗${NC} Burn failed!"
    exit 1
fi

# Sync
echo ""
echo "[3/4] Syncing..."
sync
sleep 2

# Eject
echo "[4/4] Ejecting SD card..."
diskutil eject "/dev/$SD_DEVICE"

echo ""
echo "=========================================="
echo -e "${GREEN}✅ Image burned successfully!${NC}"
echo "=========================================="
echo ""
echo "Next steps:"
echo "  1. Remove SD card from Mac"
echo "  2. Insert into Raspberry Pi"
echo "  3. Boot Pi"
echo ""
