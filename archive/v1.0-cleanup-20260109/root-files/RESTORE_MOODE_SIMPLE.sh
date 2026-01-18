#!/bin/bash
# Simple Restore: Flash moOde image fresh, then add our fixes
# Run: sudo ./RESTORE_MOODE_SIMPLE.sh

cd ~/moodeaudio-cursor

IMAGE="2025-12-07-moode-r1001-arm64-lite.img"
ROOTFS="/Volumes/rootfs"
BOOTFS="/Volumes/bootfs"

echo "=== SIMPLE RESTORE: FLASH IMAGE THEN ADD FIXES ==="
echo ""
echo "This will:"
echo "1. Flash moOde image to SD card (fresh install)"
echo "2. Add our fixes (SSH, network, user)"
echo ""
read -p "Continue? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
fi

# Check if SD card is mounted
if [ -d "$ROOTFS" ]; then
    echo "⚠️  SD card is mounted. Please eject it first."
    echo "Then run: sudo dd if=$IMAGE of=/dev/diskX bs=1m"
    echo ""
    echo "To find disk: diskutil list"
    exit 1
fi

echo ""
echo "✅ Ready to flash"
echo ""
echo "Next steps:"
echo "1. Find SD card: diskutil list"
echo "2. Flash image: sudo dd if=$IMAGE of=/dev/diskX bs=1m"
echo "3. Mount SD card"
echo "4. Run: sudo ./INSTALL_FIXES_AFTER_FLASH.sh"
echo ""

