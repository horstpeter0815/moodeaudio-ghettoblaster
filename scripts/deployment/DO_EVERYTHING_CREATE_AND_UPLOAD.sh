#!/bin/bash
#
# DO EVERYTHING: Create Image and Upload to GitHub
# This script does it all in one go!
#

set -e

SD_DISK="disk4"
REPO_OWNER="horstpeter0815"
REPO_NAME="moode-working-image"
IMAGE_NAME="$HOME/Downloads/moode-10.2-working-$(date +%Y%m%d).img"
ZIP_NAME="${IMAGE_NAME}.zip"

echo "=========================================="
echo "CREATE IMAGE AND UPLOAD TO GITHUB"
echo "=========================================="
echo ""

# Step 1: Create image
echo "Step 1: Creating image from SD card ($SD_DISK)..."
echo "This will take 5-10 minutes..."
echo ""

diskutil unmountDisk "/dev/$SD_DISK" 2>/dev/null || true
sleep 2

sudo dd if="/dev/r${SD_DISK}" of="$IMAGE_NAME" bs=1m status=progress
sync

echo ""
echo "✅ Image created: $IMAGE_NAME"

# Step 2: Compress
echo ""
echo "Step 2: Compressing image..."
cd "$HOME/Downloads"
zip -9 "$ZIP_NAME" "$(basename $IMAGE_NAME)"
ZIP_SIZE=$(ls -lh "$ZIP_NAME" | awk '{print $5}')
echo "✅ Compressed: $ZIP_NAME ($ZIP_SIZE)"

# Step 3: Create GitHub release and upload
echo ""
echo "Step 3: Creating GitHub release and uploading..."
echo ""

# Check if gh is authenticated
if ! gh auth status &>/dev/null; then
    echo "⚠️  GitHub CLI not authenticated"
    echo "Run: gh auth login"
    exit 1
fi

# Create release with file
gh release create v1.0-working \
    --repo "$REPO_OWNER/$REPO_NAME" \
    --title "moOde 10.2 Working Image - Complete Setup" \
    --notes "Complete working moOde 10.2 image ready to burn!

**What's Included:**
- Complete moOde 10.2 installation
- Display: 1280x400 landscape, touchscreen calibrated
- Audio: HiFiBerry AMP100, volume optimized (Digital 75%, Analogue 100%)
- Network: WiFi (NAM YANG 2) configured
- Filters: CamillaDSP ready (Bose Wave filters available)
- Radio: 6 curated stations
- Volume: Optimized settings (MPD software volume control)

**Quick Start:**
1. Download the image zip file
2. Extract: \`unzip moode-10.2-working-*.img.zip\`
3. Burn to SD card using Balena Etcher or dd
4. Boot Raspberry Pi 5
5. Access: http://moode.local

**Hardware:**
- Raspberry Pi 5 (8GB)
- HiFiBerry AMP100
- 1280x400 touchscreen (WaveShare)

Ready to use! Just download, burn, and boot! 🎵" \
    "$ZIP_NAME"

echo ""
echo "=========================================="
echo "✅ COMPLETE!"
echo "=========================================="
echo ""
echo "Release created: https://github.com/$REPO_OWNER/$REPO_NAME/releases/latest"
echo ""
echo "Share this link with your friend:"
echo "https://github.com/$REPO_OWNER/$REPO_NAME/releases/latest"
echo ""

# Remount SD card
diskutil mountDisk "/dev/$SD_DISK" 2>/dev/null || true
