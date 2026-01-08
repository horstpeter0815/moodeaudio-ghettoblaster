#!/bin/bash
# Copy moOde from mounted image to SD card
# Run: sudo ./COPY_MOODE_FROM_IMAGE.sh

# Find image mount point
IMAGE_ROOTFS=""
for vol in "/Volumes/rootfs 1" "/Volumes/rootfs 1"; do
    if [ -d "$vol/var/www" ] || [ -d "$vol/var/www/html" ]; then
        IMAGE_ROOTFS="$vol"
        break
    fi
done

SD_ROOTFS="/Volumes/rootfs"

echo "=== COPYING MOODE FROM IMAGE TO SD CARD ==="
echo ""

if [ -z "$IMAGE_ROOTFS" ]; then
    echo "❌ Image not mounted or not found"
    echo "Mount it first: cd ~/moodeaudio-cursor && hdiutil attach -imagekey diskimage-class=CRawDiskImage 2025-12-07-moode-r1001-arm64-lite.img"
    exit 1
fi

echo "✅ Found image at: $IMAGE_ROOTFS"

if [ ! -d "$SD_ROOTFS" ]; then
    echo "❌ SD card not mounted at $SD_ROOTFS"
    exit 1
fi

echo "✅ Image: $IMAGE_ROOTFS"
echo "✅ SD card: $SD_ROOTFS"
echo ""

# Check image contents
echo "=== CHECKING IMAGE CONTENTS ==="
if [ -d "$IMAGE_ROOTFS/var/www" ]; then
    echo "✅ Image has /var/www"
    find "$IMAGE_ROOTFS/var/www" -type f 2>/dev/null | wc -l | xargs echo "Files in image:"
elif [ -d "$IMAGE_ROOTFS/var/www/html" ]; then
    echo "✅ Image has /var/www/html"
    find "$IMAGE_ROOTFS/var/www/html" -type f 2>/dev/null | wc -l | xargs echo "Files in image:"
else
    echo "❌ Image missing /var/www"
    exit 1
fi

echo ""
echo "=== COPYING MOODE WEB FILES ==="
# moOde uses /var/www directly, not /var/www/html
if [ -d "$IMAGE_ROOTFS/var/www" ] && [ ! -d "$IMAGE_ROOTFS/var/www/html" ]; then
    # Copy /var/www to /var/www/html on SD card
    rsync -av --progress "$IMAGE_ROOTFS/var/www/" "$SD_ROOTFS/var/www/html/" 2>&1 | tail -20
else
    # Standard /var/www/html structure
    rsync -av --progress "$IMAGE_ROOTFS/var/www/html/" "$SD_ROOTFS/var/www/html/" 2>&1 | tail -20
fi

echo ""
echo "=== COPYING MOODE CONFIGURATION ==="
mkdir -p "$SD_ROOTFS/var/local/www"
rsync -av --progress "$IMAGE_ROOTFS/var/local/www/" "$SD_ROOTFS/var/local/www/" 2>&1 | tail -20

echo ""
echo "=== VERIFYING ==="
echo "SD card /var/www/html size:"
du -sh "$SD_ROOTFS/var/www/html/" 2>/dev/null
echo ""
echo "Files copied:"
find "$SD_ROOTFS/var/www/html" -type f 2>/dev/null | wc -l | xargs echo "Total files:"

echo ""
echo "✅✅✅ COPY COMPLETE ✅✅✅"
echo ""

