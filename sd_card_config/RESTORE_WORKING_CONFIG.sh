#!/bin/bash

# RESTORE WORKING CONFIGURATION
# This restores the configuration that was actually working

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$SCRIPT_DIR/backups/20251128_010229"

echo "=========================================="
echo "RESTORE WORKING CONFIGURATION"
echo "=========================================="
echo ""

# Find SD card
SD_CARD_MOUNT=""
for mount in /Volumes/boot /Volumes/firmware /Volumes/bootfs /Volumes/*; do
    if [ -d "$mount" ] && ([ -f "$mount/config.txt" ] || [ -f "$mount/start4.elf" ] || [ -f "$mount/start.elf" ]); then
        SD_CARD_MOUNT="$mount"
        echo "✓ Found SD card at: $SD_CARD_MOUNT"
        break
    fi
done

if [ -z "$SD_CARD_MOUNT" ]; then
    echo "❌ SD card not mounted!"
    echo "Please insert SD card and wait for it to mount, then run this script again."
    exit 1
fi

# Determine boot directory
BOOT_DIR=""
if [ -d "$SD_CARD_MOUNT/firmware" ]; then
    BOOT_DIR="$SD_CARD_MOUNT/firmware"
elif [ -f "$SD_CARD_MOUNT/config.txt" ]; then
    BOOT_DIR="$SD_CARD_MOUNT"
else
    echo "❌ Could not find boot directory!"
    exit 1
fi

echo "✓ Boot directory: $BOOT_DIR"
echo ""

# Restore config.txt
echo "Restoring config.txt..."
if [ -f "$BACKUP_DIR/config.txt.backup" ]; then
    cp "$BACKUP_DIR/config.txt.backup" "$BOOT_DIR/config.txt"
    echo "✅ config.txt restored"
else
    echo "❌ Backup not found!"
    exit 1
fi

# Restore cmdline.txt
echo "Restoring cmdline.txt..."
if [ -f "$BACKUP_DIR/cmdline.txt.backup" ]; then
    cp "$BACKUP_DIR/cmdline.txt.backup" "$BOOT_DIR/cmdline.txt"
    echo "✅ cmdline.txt restored"
else
    echo "❌ Backup not found!"
    exit 1
fi

echo ""
echo "=========================================="
echo "✅ RESTORED - Pi should boot now"
echo "=========================================="
echo ""
echo "The working configuration has been restored."
echo "Eject SD card and boot the Pi."
echo ""

