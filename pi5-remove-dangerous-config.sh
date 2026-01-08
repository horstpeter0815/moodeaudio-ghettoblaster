#!/bin/bash
# PI 5 REMOVE DANGEROUS CONFIGURATION
# Remove custom 1280x400 resolution that may be damaging displays

set -e

echo "=========================================="
echo "PI 5 REMOVE DANGEROUS CONFIGURATION"
echo "STOP using custom resolution that damages displays!"
echo "=========================================="
echo ""

ssh pi2 << 'REMOVECONFIG'
BACKUP_DIR="/home/andre/backup_safe_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

echo "=== CRITICAL: CUSTOM RESOLUTION MAY BE DAMAGING DISPLAYS ==="
echo ""
echo "The 1280x400 custom resolution may have caused:"
echo "  - Wrong video timings"
echo "  - Overvoltage to displays"
echo "  - Display controller damage"
echo ""

echo "=== REMOVING DANGEROUS CONFIGURATION ==="
# Find config.txt
if [ -f "/boot/firmware/config.txt" ]; then
    CONFIG_FILE="/boot/firmware/config.txt"
elif [ -f "/boot/config.txt" ]; then
    CONFIG_FILE="/boot/config.txt"
else
    echo "ERROR: Cannot find config.txt"
    exit 1
fi

sudo cp "$CONFIG_FILE" "$BACKUP_DIR/config.txt.backup"

# Remove dangerous custom resolution settings
echo "Removing custom resolution settings..."

# Remove hdmi_cvt for 1280x400
sudo sed -i '/hdmi_cvt=1280 400/d' "$CONFIG_FILE"
sudo sed -i '/hdmi_cvt 1280 400/d' "$CONFIG_FILE"

# Remove hdmi_mode=87 (custom mode)
sudo sed -i '/hdmi_mode=87/d' "$CONFIG_FILE"

# Remove framebuffer_width/height
sudo sed -i '/framebuffer_width=1280/d' "$CONFIG_FILE"
sudo sed -i '/framebuffer_height=400/d' "$CONFIG_FILE"

# Remove video parameter from cmdline
if [ -f "/boot/firmware/cmdline.txt" ]; then
    CMDLINE_FILE="/boot/firmware/cmdline.txt"
elif [ -f "/boot/cmdline.txt" ]; then
    CMDLINE_FILE="/boot/cmdline.txt"
fi

if [ -n "$CMDLINE_FILE" ]; then
    sudo cp "$CMDLINE_FILE" "$BACKUP_DIR/cmdline.txt.backup"
    sudo sed -i 's/video=[^ ]* *//g' "$CMDLINE_FILE"
    echo "Removed video parameter from cmdline.txt"
fi

# Create SAFE config.txt with standard HDMI mode
echo ""
echo "=== CREATING SAFE CONFIGURATION ==="
sudo tee -a "$CONFIG_FILE" > /dev/null << 'SAFECONFIG'

# SAFE CONFIGURATION - Standard HDMI modes only
# DO NOT use custom resolutions - they may damage displays!

[pi5]
dtoverlay=vc4-kms-v3d-pi5,noaudio
hdmi_enable_4kp60=0

[all]
max_framebuffers=2
disable_fw_kms_setup=0
arm_64bit=1
arm_boost=1
disable_splash=0
disable_overscan=1

# Standard HDMI - let display negotiate
hdmi_ignore_hotplug=0
display_auto_detect=1
hdmi_force_hotplug=1
hdmi_blanking=0
# Use standard HDMI mode, not custom!
# hdmi_group=2
# hdmi_mode=87  REMOVED - dangerous custom mode

# I2C & Audio
dtparam=i2c_arm=on
dtparam=i2c_arm_baudrate=100000
dtparam=i2c_vc=on
dtparam=i2s=on
dtparam=audio=off
dtoverlay=hifiberry-amp100

SAFECONFIG

echo "✅ Dangerous configuration removed"
echo ""
echo "=== NEXT STEPS ==="
echo "1. DO NOT connect any displays to Pi 5 yet"
echo "2. Test displays on other devices first"
echo "3. If displays work elsewhere, Pi 5 HDMI port may be damaged"
echo "4. Consider using Pi 4 instead of Pi 5 for displays"

REMOVECONFIG

echo ""
echo "=========================================="
echo "DANGEROUS CONFIGURATION REMOVED"
echo "=========================================="
echo ""
echo "⚠️ IMPORTANT:"
echo "  - Do NOT connect displays to Pi 5 yet"
echo "  - Test displays on Pi 4 or laptop first"
echo "  - Pi 5 may have damaged HDMI port"
echo ""
echo "Configuration has been made safe with standard HDMI only."

