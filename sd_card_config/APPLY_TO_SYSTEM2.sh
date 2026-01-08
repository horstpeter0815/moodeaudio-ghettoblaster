#!/bin/bash
# Apply working configuration to System 2 (Moode Pi)
# Run this when System 2 is booted

set -e

PI_HOST="${1:-moode.local}"
PI_USER="${2:-moode}"

echo "=========================================="
echo "APPLYING CONFIGURATION TO SYSTEM 2"
echo "=========================================="
echo ""

# Try to connect
if ! ping -c 1 -W 2 "$PI_HOST" &>/dev/null; then
    echo "⚠️  Cannot reach $PI_HOST"
    echo "Try: $0 <hostname_or_ip> [username]"
    exit 1
fi

echo "Connecting to $PI_HOST as $PI_USER..."

ssh -o StrictHostKeyChecking=no "$PI_USER@$PI_HOST" << 'ENDSSH'
set -e

echo "=== Backing up current config ==="
sudo cp /boot/firmware/config.txt /boot/firmware/config.txt.backup.$(date +%Y%m%d_%H%M%S)
sudo cp /boot/firmware/cmdline.txt /boot/firmware/cmdline.txt.backup.$(date +%Y%m%d_%H%M%S)

# Get PARTUUID
PARTUUID=$(grep -o "PARTUUID=[^ ]*" /boot/firmware/cmdline.txt | cut -d= -f2 | head -1)
echo "PARTUUID: $PARTUUID"

# Apply cmdline.txt
echo "=== Applying cmdline.txt ==="
sudo tee /boot/firmware/cmdline.txt > /dev/null << EOF
console=serial0,115200 console=tty1 root=PARTUUID=$PARTUUID rootfstype=ext4 fsck.repair=yes rootwait video=HDMI-A-2:400x1280M@60,rotate=90 cfg80211.ieee80211_regdom=DE
EOF

# Apply config.txt
echo "=== Applying config.txt ==="
# Ensure [pi5] section has correct settings
if grep -q "^\[pi5\]" /boot/firmware/config.txt; then
    # Remove old [pi5] section and add new one
    sudo sed -i '/^\[pi5\]/,/^\[/{/^\[pi5\]/!{/^\[/!d}}' /boot/firmware/config.txt
    sudo sed -i '/^\[pi5\]/a\
dtoverlay=vc4-kms-v3d-pi5,noaudio\
hdmi_enable_4kp60=0\
display_rotate=0' /boot/firmware/config.txt
else
    # Add [pi5] section before [all]
    sudo sed -i '/^\[all\]/i\
[pi5]\
dtoverlay=vc4-kms-v3d-pi5,noaudio\
hdmi_enable_4kp60=0\
display_rotate=0\
' /boot/firmware/config.txt
fi

# Ensure [all] section has correct settings
sudo sed -i 's/disable_fw_kms_setup=1/disable_fw_kms_setup=0/' /boot/firmware/config.txt

# Add HDMI settings to [all] if not present
if ! grep -q "hdmi_cvt=1280 480" /boot/firmware/config.txt; then
    sudo sed -i '/^\[all\]/a\
hdmi_group=2\
hdmi_mode=87\
hdmi_cvt=1280 480 60 6 0 0 0\
hdmi_force_hotplug=1\
hdmi_drive=2' /boot/firmware/config.txt
fi

echo "✅ Configuration applied"
echo ""
echo "REBOOT REQUIRED: sudo reboot"
ENDSSH

echo ""
echo "✅ Configuration applied to System 2"
echo "System 2 needs to be rebooted for changes to take effect"

