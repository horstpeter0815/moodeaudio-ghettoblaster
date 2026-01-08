#!/bin/bash

# APPLY EXACT WORKING CONFIGURATION - FINAL VERSION
# Based on WORKING_CONFIGURATION_PI5.md - the config that ACTUALLY worked this afternoon

set -e

echo "=========================================="
echo "APPLYING EXACT WORKING CONFIG - FINAL"
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

# Get PARTUUID from existing cmdline.txt
PARTUUID=$(grep -o 'root=PARTUUID=[^ ]*' "$BOOT_DIR/cmdline.txt" | sed 's/root=PARTUUID=//' || echo "738a4d67-02")
echo "✓ Using PARTUUID: $PARTUUID"
echo ""

# Apply EXACT working cmdline.txt
echo "Applying cmdline.txt (EXACT working version)..."
cat > "$BOOT_DIR/cmdline.txt" << EOF
console=serial0,115200 console=tty1 root=PARTUUID=${PARTUUID} rootfstype=ext4 fsck.repair=yes rootwait video=HDMI-A-2:400x1280M@60,rotate=90 cfg80211.ieee80211_regdom=DE
EOF
echo "✅ cmdline.txt applied"
echo ""

# For config.txt - ensure [pi5] section has correct settings
echo "Updating config.txt..."
echo ""

# Ensure [pi5] section exists with correct settings
if ! grep -q "^\[pi5\]" "$BOOT_DIR/config.txt"; then
    # Add [pi5] section after [all] or at end
    if grep -q "^\[all\]" "$BOOT_DIR/config.txt"; then
        sed -i '' '/^\[all\]/a\
\
[pi5]\
dtoverlay=vc4-kms-v3d-pi5,noaudio\
hdmi_enable_4kp60=0\
display_rotate=0
' "$BOOT_DIR/config.txt"
    else
        echo "" >> "$BOOT_DIR/config.txt"
        echo "[pi5]" >> "$BOOT_DIR/config.txt"
        echo "dtoverlay=vc4-kms-v3d-pi5,noaudio" >> "$BOOT_DIR/config.txt"
        echo "hdmi_enable_4kp60=0" >> "$BOOT_DIR/config.txt"
        echo "display_rotate=0" >> "$BOOT_DIR/config.txt"
    fi
    echo "✅ Added [pi5] section"
fi

# Ensure dtoverlay=vc4-kms-v3d-pi5,noaudio in [pi5] section
if ! sed -n '/^\[pi5\]/,/^\[/p' "$BOOT_DIR/config.txt" | grep -q "dtoverlay=vc4-kms-v3d-pi5"; then
    sed -i '' '/^\[pi5\]/a\
dtoverlay=vc4-kms-v3d-pi5,noaudio
' "$BOOT_DIR/config.txt"
    echo "✅ Added dtoverlay=vc4-kms-v3d-pi5,noaudio"
fi

# Ensure hdmi_cvt is set (1280 400 or 1280 480 - check what works)
if ! grep -q "hdmi_cvt.*1280" "$BOOT_DIR/config.txt"; then
    echo "hdmi_cvt=1280 400 60 6 0 0 0" >> "$BOOT_DIR/config.txt"
    echo "✅ Added hdmi_cvt 1280 400"
fi

echo ""
echo "=========================================="
echo "✅ CONFIGURATION APPLIED - FINAL"
echo "=========================================="
echo ""
echo "cmdline.txt: video=HDMI-A-2:400x1280M@60,rotate=90 ✓"
echo "config.txt: [pi5] section with dtoverlay=vc4-kms-v3d-pi5,noaudio ✓"
echo ""
echo "SD card is ready. Eject and boot the Pi."
echo "After boot, the Pi should be reachable at moode.local or raspberrypi.local"
echo ""

