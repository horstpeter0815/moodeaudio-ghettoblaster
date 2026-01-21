#!/bin/bash
#########################################################################
# Unmount Image Tool - Clean unmount and sync
# Usage: ./unmount-image.sh [container-name]
#########################################################################

set -e

CONTAINER_NAME="${1:-pigen_work}"

echo "=== Unmounting Image in Docker ==="
echo "Container: $CONTAINER_NAME"
echo ""

docker exec "$CONTAINER_NAME" bash -c '
set -e

echo "Syncing changes to disk..."
sync
sync

echo "Unmounting partitions..."
umount /mnt/boot 2>/dev/null || true
umount /mnt/root 2>/dev/null || true

echo "Removing kpartx mappings..."
kpartx -dv /dev/loop1 2>/dev/null || true

echo "Detaching loop device..."
losetup -d /dev/loop1 2>/dev/null || true

echo "Final sync..."
sync

echo "✅ Image unmounted successfully!"
'
