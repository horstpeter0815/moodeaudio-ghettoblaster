#!/bin/bash

# FIX CONFIG WITH disable_fw_kms_setup=0
# This is what worked today at lunch

set -e

echo "=========================================="
echo "FIXING CONFIG - disable_fw_kms_setup=0"
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

# Restore config.txt from backup
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$SCRIPT_DIR/backups/20251128_010229"

echo "Restoring config.txt from backup..."
cp "$BACKUP_DIR/config.txt.backup" "$BOOT_DIR/config.txt"
echo "✅ config.txt restored"
echo ""

# CRITICAL: Change disable_fw_kms_setup=1 to disable_fw_kms_setup=0
echo "Setting disable_fw_kms_setup=0 (this is what worked!)..."
sed -i '' 's/disable_fw_kms_setup=1/disable_fw_kms_setup=0/' "$BOOT_DIR/config.txt"
if grep -q "disable_fw_kms_setup=0" "$BOOT_DIR/config.txt"; then
    echo "✅ disable_fw_kms_setup=0 set"
else
    echo "⚠️  disable_fw_kms_setup not found, adding it..."
    echo "disable_fw_kms_setup=0" >> "$BOOT_DIR/config.txt"
fi
echo ""

# Ensure [pi5] section with dtoverlay
echo "Ensuring [pi5] section..."
if ! grep -q "^\[pi5\]" "$BOOT_DIR/config.txt"; then
    echo "" >> "$BOOT_DIR/config.txt"
    echo "[pi5]" >> "$BOOT_DIR/config.txt"
fi

if ! sed -n '/^\[pi5\]/,/^\[/p' "$BOOT_DIR/config.txt" | grep -q "dtoverlay=vc4-kms-v3d-pi5"; then
    sed -i '' '/^\[pi5\]/a\
dtoverlay=vc4-kms-v3d-pi5,noaudio\
hdmi_enable_4kp60=0
' "$BOOT_DIR/config.txt"
    echo "✅ Added dtoverlay=vc4-kms-v3d-pi5,noaudio to [pi5]"
fi
echo ""

# Set cmdline.txt with video parameter
echo "Setting cmdline.txt..."
cat > "$BOOT_DIR/cmdline.txt" << EOF
console=serial0,115200 console=tty1 root=PARTUUID=${PARTUUID} rootfstype=ext4 fsck.repair=yes rootwait video=HDMI-A-2:400x1280M@60,rotate=90 cfg80211.ieee80211_regdom=DE
EOF
echo "✅ cmdline.txt set with video parameter"
echo ""

echo "=========================================="
echo "✅ CONFIG FIXED"
echo "=========================================="
echo ""
echo "disable_fw_kms_setup=0 ✓ (this is what worked!)"
echo "video=HDMI-A-2:400x1280M@60,rotate=90 ✓"
echo "dtoverlay=vc4-kms-v3d-pi5,noaudio ✓"
echo ""
echo "SD card is ready. Eject and boot the Pi."
echo ""

