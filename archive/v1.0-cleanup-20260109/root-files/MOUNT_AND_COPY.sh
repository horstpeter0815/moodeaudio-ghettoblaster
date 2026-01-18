#!/bin/bash
# Mount image and copy moOde files
# Run: sudo ./MOUNT_AND_COPY.sh

cd ~/moodeaudio-cursor

IMAGE="2025-12-07-moode-r1001-arm64-lite.img"
SD_ROOTFS="/Volumes/rootfs"

echo "=== MOUNTING IMAGE AND COPYING MOODE ==="
echo ""

# Check if image exists
if [ ! -f "$IMAGE" ]; then
    echo "❌ Image not found: $IMAGE"
    exit 1
fi

# Check if SD card is mounted
if [ ! -d "$SD_ROOTFS" ]; then
    echo "❌ SD card not mounted at $SD_ROOTFS"
    exit 1
fi

echo "✅ Image: $IMAGE"
echo "✅ SD card: $SD_ROOTFS"
echo ""

# Mount image
echo "1. Mounting image..."
hdiutil attach -imagekey diskimage-class=CRawDiskImage "$IMAGE" > /dev/null 2>&1
sleep 3

# Find image mount point
IMAGE_ROOTFS=""
for vol in "/Volumes/rootfs 1" "/Volumes/rootfs 1"; do
    if [ -d "$vol/var/www" ]; then
        IMAGE_ROOTFS="$vol"
        break
    fi
done

if [ -z "$IMAGE_ROOTFS" ]; then
    echo "❌ Could not find mounted image"
    exit 1
fi

echo "✅ Image mounted at: $IMAGE_ROOTFS"
echo ""

# Copy files
echo "2. Copying moOde web files..."
rsync -av --progress "$IMAGE_ROOTFS/var/www/" "$SD_ROOTFS/var/www/html/" 2>&1 | tail -20

echo ""
echo "3. Copying moOde configuration..."
mkdir -p "$SD_ROOTFS/var/local/www"
if [ -d "$IMAGE_ROOTFS/var/local/www" ]; then
    rsync -av --progress "$IMAGE_ROOTFS/var/local/www/" "$SD_ROOTFS/var/local/www/" 2>&1 | tail -20
fi

echo ""
echo "=== VERIFYING ==="
du -sh "$SD_ROOTFS/var/www/html/" 2>/dev/null
find "$SD_ROOTFS/var/www/html" -type f 2>/dev/null | wc -l | xargs echo "Files:"

echo ""
echo "✅✅✅ COPY COMPLETE ✅✅✅"
echo ""

# Unmount image
echo "4. Unmounting image..."
hdiutil detach "$IMAGE_ROOTFS" > /dev/null 2>&1

echo ""
echo "Next: sudo ./INSTALL_FIXES_AFTER_FLASH.sh"
echo ""

