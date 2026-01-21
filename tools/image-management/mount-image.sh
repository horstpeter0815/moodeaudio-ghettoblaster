#!/bin/bash
#########################################################################
# Mount Image Tool - Reusable image mounting in Docker
# Usage: ./mount-image.sh <image-path>
#########################################################################

set -e

IMAGE_PATH="${1}"
CONTAINER_NAME="${2:-pigen_work}"

if [ -z "$IMAGE_PATH" ]; then
    echo "Usage: $0 <image-path> [container-name]"
    echo "Example: $0 /path/to/moode.img pigen_work"
    exit 1
fi

if [ ! -f "$IMAGE_PATH" ]; then
    echo "❌ Error: Image file not found: $IMAGE_PATH"
    exit 1
fi

echo "=== Mounting Image in Docker ==="
echo "Image: $IMAGE_PATH"
echo "Container: $CONTAINER_NAME"
echo ""

# Ensure container is running
docker start "$CONTAINER_NAME" 2>/dev/null || true
sleep 2

# Copy image to container if not already there
if ! docker exec "$CONTAINER_NAME" test -f /tmp/moode.img; then
    echo "Copying image to container..."
    docker cp "$IMAGE_PATH" "$CONTAINER_NAME":/tmp/moode.img
fi

# Mount the image
docker exec "$CONTAINER_NAME" bash -c '
set -e

# Clean up any previous mounts
losetup -d /dev/loop1 2>/dev/null || true
kpartx -d /dev/loop1 2>/dev/null || true
umount /mnt/boot 2>/dev/null || true
umount /mnt/root 2>/dev/null || true

# Setup loop device
losetup -f /tmp/moode.img
LOOP_DEV=$(losetup -j /tmp/moode.img | cut -d: -f1)
echo "Loop device: $LOOP_DEV"

# Create partition mappings
kpartx -av $LOOP_DEV

# Create mount points
mkdir -p /mnt/boot /mnt/root

# Mount partitions
mount /dev/mapper/loop1p1 /mnt/boot
mount /dev/mapper/loop1p2 /mnt/root

echo ""
echo "✅ Image mounted successfully!"
echo "Boot partition: /mnt/boot"
echo "Root partition: /mnt/root"
echo ""
df -h | grep /mnt
'

echo ""
echo "✅ Done! Use unmount-image.sh to unmount."
