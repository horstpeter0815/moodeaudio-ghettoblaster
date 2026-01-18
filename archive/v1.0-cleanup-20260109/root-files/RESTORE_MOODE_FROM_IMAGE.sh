#!/bin/bash
# Restore moOde from Image - Extract files from image and copy to SD card
# Run: sudo ./RESTORE_MOODE_FROM_IMAGE.sh

cd ~/moodeaudio-cursor

IMAGE="image_2025-12-07-moode-r1001-arm64-lite.img"
ROOTFS="/Volumes/rootfs"
MOUNT_POINT="/tmp/moode-image-mount"

echo "=== RESTORING MOODE FROM IMAGE ==="
echo ""

if [ ! -f "$IMAGE" ]; then
    echo "❌ Image not found: $IMAGE"
    exit 1
fi

if [ ! -d "$ROOTFS" ]; then
    echo "❌ SD card not mounted at $ROOTFS"
    exit 1
fi

echo "✅ Image: $IMAGE"
echo "✅ SD card: $ROOTFS"
echo ""

# Mount the image
echo "1. Mounting image..."
sudo mkdir -p "$MOUNT_POINT"
# Get partition offset (usually partition 2 is rootfs)
PARTITION_OFFSET=$(sudo fdisk -l "$IMAGE" 2>/dev/null | grep "Linux" | head -1 | awk '{print $2 * 512}' || echo "27262976")
echo "   Partition offset: $PARTITION_OFFSET"

sudo mount -o loop,offset=$PARTITION_OFFSET "$IMAGE" "$MOUNT_POINT" 2>/dev/null || {
    echo "⚠️  Loop mount failed, trying hdiutil..."
    # On macOS, use hdiutil
    hdiutil attach -imagekey diskimage-class=CRawDiskImage "$IMAGE" 2>/dev/null || {
        echo "❌ Failed to mount image"
        exit 1
    }
    # Find mounted volume
    MOUNT_POINT=$(diskutil list | grep -A 5 "$IMAGE" | grep "Linux" | awk '{print "/Volumes/" $NF}' | head -1)
    if [ -z "$MOUNT_POINT" ] || [ ! -d "$MOUNT_POINT" ]; then
        echo "❌ Could not find mounted image"
        exit 1
    fi
    echo "✅ Image mounted at: $MOUNT_POINT"
}

echo "✅ Image mounted"
echo ""

# Copy moOde files
echo "2. Copying moOde web files..."
if [ -d "$MOUNT_POINT/var/www/html" ]; then
    sudo rsync -av --delete "$MOUNT_POINT/var/www/html/" "$ROOTFS/var/www/html/"
    echo "✅ Web files copied"
else
    echo "⚠️  /var/www/html not found in image"
fi

echo "3. Copying moOde configuration..."
if [ -d "$MOUNT_POINT/var/local/www" ]; then
    sudo mkdir -p "$ROOTFS/var/local/www"
    sudo rsync -av --delete "$MOUNT_POINT/var/local/www/" "$ROOTFS/var/local/www/"
    echo "✅ Configuration copied"
fi

echo "4. Copying system configuration..."
if [ -d "$MOUNT_POINT/etc" ]; then
    sudo rsync -av "$MOUNT_POINT/etc/" "$ROOTFS/etc/" --exclude="ssh" --exclude="network" || true
    echo "✅ System config copied (excluding network/ssh - we'll use our fixes)"
fi

echo ""
echo "✅✅✅ MOODE RESTORED FROM IMAGE ✅✅✅"
echo ""

# Unmount
echo "5. Unmounting image..."
if [ "$MOUNT_POINT" != "/tmp/moode-image-mount" ]; then
    hdiutil detach "$MOUNT_POINT" 2>/dev/null || true
else
    sudo umount "$MOUNT_POINT" 2>/dev/null || true
fi

echo ""
echo "Next steps:"
echo "1. Install our fixes (SSH, network, user)"
echo "2. Eject SD card"
echo "3. Boot Pi"
echo ""

