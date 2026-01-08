#!/bin/bash

# APPLY THE ONE WORKING CONFIGURATION
# Based on WORKING_CONFIGURATION_PI5.md - the config that actually worked

set -e

echo "=========================================="
echo "APPLYING THE ONE WORKING CONFIG"
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

# Apply cmdline.txt - THE WORKING ONE
echo "Applying cmdline.txt..."
cat > "$BOOT_DIR/cmdline.txt" << EOF
console=serial0,115200 console=tty1 root=PARTUUID=${PARTUUID} rootfstype=ext4 fsck.repair=yes rootwait video=HDMI-A-2:400x1280M@60,rotate=90 cfg80211.ieee80211_regdom=DE
EOF
echo "✅ cmdline.txt applied"
echo ""

# Restore config.txt from backup (moOde-managed)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$SCRIPT_DIR/backups/20251128_010229"

if [ -f "$BACKUP_DIR/config.txt.backup" ]; then
    echo "Restoring config.txt from backup..."
    cp "$BACKUP_DIR/config.txt.backup" "$BOOT_DIR/config.txt"
    echo "✅ config.txt restored"
else
    echo "⚠️  Backup not found, keeping current config.txt"
fi

# Ensure [pi5] section has correct settings
echo ""
echo "Updating [pi5] section..."

# Remove existing [pi5] section if it exists
sed -i '' '/^\[pi5\]/,/^\[/{ /^\[pi5\]/!{ /^\[/!d; }; }' "$BOOT_DIR/config.txt" 2>/dev/null || true

# Add [pi5] section after [all] or at end
if grep -q "^\[all\]" "$BOOT_DIR/config.txt"; then
    # Insert after [all] section
    sed -i '' '/^\[all\]/a\
\
[pi5]\
dtoverlay=vc4-kms-v3d-pi5,noaudio\
hdmi_enable_4kp60=0\
display_rotate=0
' "$BOOT_DIR/config.txt"
else
    # Add at end
    echo "" >> "$BOOT_DIR/config.txt"
    echo "[pi5]" >> "$BOOT_DIR/config.txt"
    echo "dtoverlay=vc4-kms-v3d-pi5,noaudio" >> "$BOOT_DIR/config.txt"
    echo "hdmi_enable_4kp60=0" >> "$BOOT_DIR/config.txt"
    echo "display_rotate=0" >> "$BOOT_DIR/config.txt"
fi

# Ensure hdmi_cvt is set (1280 480 as per working config)
if ! grep -q "hdmi_cvt.*1280.*480" "$BOOT_DIR/config.txt"; then
    if grep -q "hdmi_cvt.*1280.*400" "$BOOT_DIR/config.txt"; then
        sed -i '' 's/hdmi_cvt.*1280.*400.*/hdmi_cvt=1280 480 60 6 0 0 0/' "$BOOT_DIR/config.txt"
        echo "✅ Updated hdmi_cvt to 1280 480"
    else
        echo "hdmi_cvt=1280 480 60 6 0 0 0" >> "$BOOT_DIR/config.txt"
        echo "✅ Added hdmi_cvt 1280 480"
    fi
fi

echo ""
echo "=========================================="
echo "✅ THE ONE WORKING CONFIG APPLIED"
echo "=========================================="
echo ""
echo "cmdline.txt: video=HDMI-A-2:400x1280M@60,rotate=90 ✓"
echo "config.txt: [pi5] section with dtoverlay=vc4-kms-v3d-pi5,noaudio ✓"
echo "config.txt: hdmi_cvt=1280 480 60 6 0 0 0 ✓"
echo ""
echo "SD card is ready. Eject and boot the Pi."
echo ""

