#!/bin/bash

# APPLY EXACT WORKING CONFIGURATION
# Based on WORKING_CONFIGURATION_PI5.md - the config that ACTUALLY worked

set -e

echo "=========================================="
echo "APPLYING EXACT WORKING CONFIGURATION"
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

# Backup current config
BACKUP_DIR="/tmp/sd_backup_$(date +%s)"
mkdir -p "$BACKUP_DIR"
cp "$BOOT_DIR/config.txt" "$BACKUP_DIR/config.txt.backup" 2>/dev/null || true
cp "$BOOT_DIR/cmdline.txt" "$BACKUP_DIR/cmdline.txt.backup" 2>/dev/null || true
echo "✓ Backed up current config to $BACKUP_DIR"
echo ""

# Get PARTUUID from existing cmdline.txt
PARTUUID=$(grep -o 'root=PARTUUID=[^ ]*' "$BOOT_DIR/cmdline.txt" | sed 's/root=PARTUUID=//' || echo "738a4d67-02")
echo "✓ Using PARTUUID: $PARTUUID"
echo ""

# Apply EXACT working cmdline.txt
echo "Applying cmdline.txt..."
cat > "$BOOT_DIR/cmdline.txt" << EOF
console=serial0,115200 console=tty1 root=PARTUUID=${PARTUUID} rootfstype=ext4 fsck.repair=yes rootwait video=HDMI-A-2:400x1280M@60,rotate=90 cfg80211.ieee80211_regdom=DE
EOF
echo "✅ cmdline.txt applied (with video parameter)"
echo ""

# For config.txt - we need to MERGE with moOde's config, not replace it
# The working config had specific HDMI settings that need to be added/updated
echo "Updating config.txt (merging with moOde settings)..."
echo ""

# Check if [pi5] section exists, if not add it
if ! grep -q "^\[pi5\]" "$BOOT_DIR/config.txt"; then
    echo "" >> "$BOOT_DIR/config.txt"
    echo "[pi5]" >> "$BOOT_DIR/config.txt"
    echo "dtoverlay=vc4-kms-v3d-pi5,noaudio" >> "$BOOT_DIR/config.txt"
    echo "hdmi_enable_4kp60=0" >> "$BOOT_DIR/config.txt"
    echo "✅ Added [pi5] section"
fi

# Ensure hdmi_cvt is set correctly (1280 400, not 480)
if grep -q "hdmi_cvt.*1280.*480" "$BOOT_DIR/config.txt"; then
    sed -i '' 's/hdmi_cvt.*1280.*480.*/hdmi_cvt=1280 400 60 6 0 0 0/' "$BOOT_DIR/config.txt"
    echo "✅ Updated hdmi_cvt to 1280 400"
elif ! grep -q "hdmi_cvt.*1280.*400" "$BOOT_DIR/config.txt"; then
    echo "hdmi_cvt=1280 400 60 6 0 0 0" >> "$BOOT_DIR/config.txt"
    echo "✅ Added hdmi_cvt 1280 400"
fi

# Ensure display_rotate=0 in [pi5] section
if ! grep -A 5 "^\[pi5\]" "$BOOT_DIR/config.txt" | grep -q "display_rotate=0"; then
    sed -i '' '/^\[pi5\]/a\
display_rotate=0
' "$BOOT_DIR/config.txt"
    echo "✅ Added display_rotate=0 to [pi5] section"
fi

echo ""
echo "=========================================="
echo "✅ CONFIGURATION APPLIED"
echo "=========================================="
echo ""
echo "cmdline.txt: Has video=HDMI-A-2:400x1280M@60,rotate=90"
echo "config.txt: Updated with working HDMI settings"
echo ""
echo "SD card is ready. Eject and boot the Pi."
echo ""

