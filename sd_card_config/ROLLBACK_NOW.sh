#!/bin/bash

# EMERGENCY ROLLBACK - Restore working configuration
# Run this immediately to fix the boot issue

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$SCRIPT_DIR/backups/20251128_010229"

echo "=========================================="
echo "EMERGENCY ROLLBACK - Restoring Backup"
echo "=========================================="
echo ""

# Find SD card
echo "Step 1: Finding SD card..."
SD_CARD_MOUNT=""

for mount in /Volumes/boot /Volumes/firmware /Volumes/bootfs /Volumes/*; do
    if [ -d "$mount" ] && ([ -f "$mount/config.txt" ] || [ -f "$mount/start4.elf" ] || [ -f "$mount/start.elf" ]); then
        SD_CARD_MOUNT="$mount"
        echo "✓ Found SD card at: $SD_CARD_MOUNT"
        break
    fi
done

if [ -z "$SD_CARD_MOUNT" ]; then
    echo "❌ ERROR: SD card not found!"
    echo ""
    echo "Please:"
    echo "  1. Insert SD card into Mac"
    echo "  2. Wait for it to mount"
    echo "  3. Run this script again"
    echo ""
    echo "Or manually restore:"
    echo "  cp $BACKUP_DIR/config.txt.backup /Volumes/bootfs/config.txt"
    echo "  cp $BACKUP_DIR/cmdline.txt.backup /Volumes/bootfs/cmdline.txt"
    exit 1
fi

# Determine boot directory
BOOT_DIR=""
if [ -d "$SD_CARD_MOUNT/firmware" ]; then
    BOOT_DIR="$SD_CARD_MOUNT/firmware"
elif [ -f "$SD_CARD_MOUNT/config.txt" ]; then
    BOOT_DIR="$SD_CARD_MOUNT"
else
    echo "❌ ERROR: Could not find boot directory!"
    exit 1
fi

echo "✓ Boot directory: $BOOT_DIR"
echo ""

# Restore config.txt
echo "Step 2: Restoring config.txt..."
if [ -f "$BACKUP_DIR/config.txt.backup" ]; then
    cp "$BACKUP_DIR/config.txt.backup" "$BOOT_DIR/config.txt"
    echo "✅ Restored config.txt"
else
    echo "❌ ERROR: Backup file not found: $BACKUP_DIR/config.txt.backup"
    exit 1
fi

# Restore cmdline.txt
echo "Step 3: Restoring cmdline.txt..."
if [ -f "$BACKUP_DIR/cmdline.txt.backup" ]; then
    cp "$BACKUP_DIR/cmdline.txt.backup" "$BOOT_DIR/cmdline.txt"
    echo "✅ Restored cmdline.txt"
else
    echo "❌ ERROR: Backup file not found: $BACKUP_DIR/cmdline.txt.backup"
    exit 1
fi

echo ""
echo "=========================================="
echo "✅ ROLLBACK COMPLETE!"
echo "=========================================="
echo ""
echo "Configuration restored from backup."
echo ""
echo "Next steps:"
echo "  1. Eject SD card safely"
echo "  2. Insert into Pi 5"
echo "  3. Boot should work now"
echo ""
echo "The Pi should boot with the previous working configuration."
echo ""

