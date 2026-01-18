#!/bin/bash
# Automatically detect and burn image to SD card
# Uses password  for sudo

set -e

PROJECT_DIR="$HOME/moodeaudio-cursor"
cd "$PROJECT_DIR"

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  🔥 AUTO BURN IMAGE TO SD CARD                                ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Find latest image
LATEST_IMG=$(ls -t imgbuild/deploy/*.img 2>/dev/null | head -1)

if [ -z "$LATEST_IMG" ]; then
    echo "❌ ERROR: No build image found"
    exit 1
fi

echo "✅ Image: $(basename "$LATEST_IMG")"
echo "   Size: $(du -h "$LATEST_IMG" | cut -f1)"
echo ""

# Find SD card (external disk, typically 4-8GB)
echo "=== DETECTING SD CARD ==="
echo ""

SD_DEVICE=""
# Check for external disks
for disk in disk2 disk3 disk4 disk5 disk6 disk7; do
    if diskutil info "/dev/$disk" >/dev/null 2>&1; then
        # Check if it's external
        if diskutil list | grep "$disk" | grep -q "external"; then
            SIZE_STR=$(diskutil info "/dev/$disk" 2>/dev/null | grep "Total Size" | awk '{print $3 $4}')
            echo "  Checking $disk: $SIZE_STR (external)"
            # Accept any external disk (SD cards can be various sizes)
            SD_DEVICE="$disk"
            echo "✅ Found SD card: $disk ($SIZE_STR)"
            break
        fi
    fi
done

if [ -z "$SD_DEVICE" ]; then
    echo "❌ ERROR: Could not automatically detect SD card"
    echo ""
    echo "Please run: ./BURN_IMAGE_TO_SD.sh (interactive)"
    exit 1
fi

echo ""
echo "⚠️  WARNING: This will ERASE all data on /dev/$SD_DEVICE"
echo "   Image: $(basename "$LATEST_IMG")"
echo ""
echo "Starting burn in 5 seconds... (Ctrl+C to cancel)"
sleep 5

# Unmount
echo ""
echo "Unmounting /dev/$SD_DEVICE..."
diskutil unmountDisk "/dev/$SD_DEVICE" 2>/dev/null || true
sleep 2

# Burn image
echo ""
echo "🔥 Burning image to SD card..."
echo "   This will take 5-10 minutes..."
echo "   Progress will be shown..."
echo ""

# Use sudo with password
echo "" | sudo -S dd if="$LATEST_IMG" of="/dev/r$SD_DEVICE" bs=1m status=progress 2>&1

BURN_EXIT=$?

if [ $BURN_EXIT -eq 0 ]; then
    echo ""
    echo "✅✅✅ IMAGE BURNED SUCCESSFULLY ✅✅✅"
    echo ""
    
    # Sync
    echo "Syncing..."
    sync
    
    # Verify
    echo ""
    echo "Verifying burn..."
    sleep 2
    
    # Eject
    echo "Ejecting SD card..."
    diskutil eject "/dev/$SD_DEVICE" 2>/dev/null || true
    
    echo ""
    echo "✅✅✅ SD CARD READY ✅✅✅"
    echo ""
    echo "Next steps:"
    echo "  1. Remove SD card from Mac"
    echo "  2. Insert into Pi"
    echo "  3. Boot Pi"
    echo "  4. Wait 2 minutes for boot"
    echo "  5. Test: ./test-ssh-after-boot.sh"
    echo ""
    echo "Services included in image:"
    echo "  ✅ 00-boot-network-ssh.service"
    echo "  ✅ 01-ssh-enable.service"
    echo "  ✅ 02-eth0-configure.service"
    echo "  ✅ fix-user-id.service"
    echo "  ✅ Password: "
else
    echo ""
    echo "❌ ERROR: Image burn failed (exit code: $BURN_EXIT)"
    exit 1
fi

