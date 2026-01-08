#!/bin/bash

# RESTORE WORKING CONFIGURATION - THE ONE THAT ACTUALLY WORKED
# Based on WORKING_CONFIGURATION_PI5.md

set -e

echo "=========================================="
echo "RESTORING WORKING CONFIGURATION"
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
    echo "Please insert SD card and wait for it to mount."
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

# Get PARTUUID
PARTUUID=$(grep -o 'root=PARTUUID=[^ ]*' "$BOOT_DIR/cmdline.txt" | sed 's/root=PARTUUID=//' || echo "738a4d67-02")
echo "✓ Using PARTUUID: $PARTUUID"
echo ""

# Restore cmdline.txt with WORKING video parameter
echo "Restoring cmdline.txt (WITH video parameter)..."
cat > "$BOOT_DIR/cmdline.txt" << EOF
console=serial0,115200 console=tty1 root=PARTUUID=${PARTUUID} rootfstype=ext4 fsck.repair=yes rootwait video=HDMI-A-2:400x1280M@60,rotate=90 cfg80211.ieee80211_regdom=DE
EOF
echo "✅ cmdline.txt restored with video parameter"
echo ""

# Restore config.txt from backup (the moOde-managed one)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$SCRIPT_DIR/backups/20251128_010229"

if [ -f "$BACKUP_DIR/config.txt.backup" ]; then
    echo "Restoring config.txt from backup..."
    cp "$BACKUP_DIR/config.txt.backup" "$BOOT_DIR/config.txt"
    echo "✅ config.txt restored"
    
    # Ensure [pi5] section has dtoverlay
    if ! sed -n '/^\[pi5\]/,/^\[/p' "$BOOT_DIR/config.txt" | grep -q "dtoverlay=vc4-kms-v3d-pi5"; then
        sed -i '' '/^\[pi5\]/a\
dtoverlay=vc4-kms-v3d-pi5,noaudio
' "$BOOT_DIR/config.txt"
        echo "✅ Added dtoverlay=vc4-kms-v3d-pi5,noaudio to [pi5] section"
    fi
else
    echo "⚠️  Backup not found, keeping current config.txt"
fi

echo ""
echo "=========================================="
echo "✅ RESTORATION COMPLETE"
echo "=========================================="
echo ""
echo "cmdline.txt: Has video=HDMI-A-2:400x1280M@60,rotate=90 ✓"
echo "config.txt: Restored from backup ✓"
echo ""
echo "SD card is ready. Eject and boot the Pi."
echo ""

