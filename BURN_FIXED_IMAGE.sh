#!/bin/bash
#########################################################################
# Burn Fixed moOde Image to SD Card
# Image: moode-r1001-arm64-20260119_132811-lite-FIXED.img
#########################################################################

set -e

IMG_FILE="/Users/andrevollmer/moodeaudio-cursor/imgbuild/deploy/moode-r1001-arm64-20260119_132811-lite-FIXED.img"
SD_DISK="/dev/disk4"
SD_RDISK="/dev/rdisk4"

echo "========================================="
echo "BURN FIXED MOODE IMAGE TO SD CARD"
echo "========================================="
echo ""
echo "Image: $IMG_FILE"
echo "Size: $(ls -lh "$IMG_FILE" | awk '{print $5}')"
echo "Target: $SD_RDISK"
echo ""
echo "⚠️  WARNING: This will ERASE all data on $SD_DISK!"
echo ""
read -p "Continue? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo "❌ Cancelled"
    exit 1
fi

echo ""
echo "=== Unmounting SD card ==="
diskutil unmountDisk force "$SD_DISK"

echo ""
echo "=== Burning image (this will take 5-10 minutes) ==="
echo "Progress will be shown..."
sudo dd if="$IMG_FILE" of="$SD_RDISK" bs=1m conv=sync status=progress

echo ""
echo "=== Syncing ==="
sync

echo ""
echo "=== Ejecting SD card ==="
diskutil eject "$SD_DISK"

echo ""
echo "========================================="
echo "✅ SD CARD READY!"
echo "========================================="
echo ""
echo "Configurations applied:"
echo "  ✅ cmdline.txt: video=HDMI-A-1:1280x400@60 (landscape)"
echo "  ✅ config.txt: arm_boost=1, audio disabled, HiFiBerry enabled"
echo "  ✅ Database: HiFiBerry AMP100, landscape orientation, Bose filters"
echo "  ✅ ALSA: plughw:1,0 (HiFiBerry)"
echo "  ✅ Local display enabled"
echo ""
echo "Next steps:"
echo "  1. Insert SD card into Raspberry Pi 5"
echo "  2. Power on"
echo "  3. Wait for first boot (may resize filesystem)"
echo "  4. Display should show in landscape 1280x400"
echo ""
