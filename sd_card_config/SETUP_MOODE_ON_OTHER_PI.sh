#!/bin/bash

# SETUP MOODE AUDIO ON OTHER PI (Raspberry Pi OS)
# With working HDMI and touchscreen configuration

set -e

PI_IP="$1"

if [ -z "$PI_IP" ]; then
    echo "Usage: $0 <PI_IP_ADDRESS>"
    echo "Example: $0 192.168.1.100"
    exit 1
fi

echo "=========================================="
echo "SETTING UP MOODE ON PI AT $PI_IP"
echo "=========================================="
echo ""

# Connect and setup
ssh pi@"$PI_IP" << 'ENDSSH'
set -e

echo "=== STEP 1: CHECKING SYSTEM ==="
cat /proc/device-tree/model
echo ""

echo "=== STEP 2: APPLYING WORKING CONFIG ==="

# Backup current config
sudo cp /boot/firmware/config.txt /boot/firmware/config.txt.backup.$(date +%s) 2>/dev/null || sudo cp /boot/config.txt /boot/config.txt.backup.$(date +%s)
sudo cp /boot/firmware/cmdline.txt /boot/firmware/cmdline.txt.backup.$(date +%s) 2>/dev/null || sudo cp /boot/cmdline.txt /boot/cmdline.txt.backup.$(date +%s)

CONFIG_FILE="/boot/firmware/config.txt"
CMDLINE_FILE="/boot/firmware/cmdline.txt"
[ ! -f "$CONFIG_FILE" ] && CONFIG_FILE="/boot/config.txt"
[ ! -f "$CMDLINE_FILE" ] && CMDLINE_FILE="/boot/cmdline.txt"

# Get PARTUUID
PARTUUID=$(grep -o 'root=PARTUUID=[^ ]*' "$CMDLINE_FILE" | sed 's/root=PARTUUID=//' || echo "")

# Apply cmdline.txt with video parameter
echo "Setting cmdline.txt..."
if [ -n "$PARTUUID" ]; then
    echo "console=serial0,115200 console=tty1 root=PARTUUID=${PARTUUID} rootfstype=ext4 fsck.repair=yes rootwait video=HDMI-A-2:400x1280M@60,rotate=90 cfg80211.ieee80211_regdom=DE" | sudo tee "$CMDLINE_FILE" > /dev/null
else
    echo "console=serial0,115200 console=tty1 root=PARTUUID=CHANGE_ME rootfstype=ext4 fsck.repair=yes rootwait video=HDMI-A-2:400x1280M@60,rotate=90 cfg80211.ieee80211_regdom=DE" | sudo tee "$CMDLINE_FILE" > /dev/null
fi

# Apply config.txt - ensure [pi5] section
echo "Setting config.txt..."
if ! grep -q "^\[pi5\]" "$CONFIG_FILE"; then
    echo "" | sudo tee -a "$CONFIG_FILE" > /dev/null
    echo "[pi5]" | sudo tee -a "$CONFIG_FILE" > /dev/null
fi

# Ensure disable_fw_kms_setup=0
sudo sed -i 's/disable_fw_kms_setup=1/disable_fw_kms_setup=0/' "$CONFIG_FILE" 2>/dev/null || true
if ! grep -q "disable_fw_kms_setup=0" "$CONFIG_FILE"; then
    echo "disable_fw_kms_setup=0" | sudo tee -a "$CONFIG_FILE" > /dev/null
fi

# Ensure dtoverlay=vc4-kms-v3d-pi5,noaudio in [pi5]
if ! sed -n '/^\[pi5\]/,/^\[/p' "$CONFIG_FILE" | grep -q "dtoverlay=vc4-kms-v3d-pi5"; then
    sudo sed -i '/^\[pi5\]/a\dtoverlay=vc4-kms-v3d-pi5,noaudio' "$CONFIG_FILE"
fi

# Ensure hdmi_cvt
if ! grep -q "hdmi_cvt.*1280.*480" "$CONFIG_FILE"; then
    echo "hdmi_cvt=1280 480 60 6 0 0 0" | sudo tee -a "$CONFIG_FILE" > /dev/null
fi

echo "✅ Config applied"
echo ""

echo "=== STEP 3: VERIFYING ==="
echo "disable_fw_kms_setup:"
grep "disable_fw_kms_setup" "$CONFIG_FILE"
echo ""
echo "cmdline.txt video:"
grep "video=" "$CMDLINE_FILE"
echo ""
echo "[pi5] section:"
sed -n '/^\[pi5\]/,/^\[/p' "$CONFIG_FILE" | head -5
echo ""

echo "=== STEP 4: TOUCHSCREEN CONFIG (if needed) ==="
if [ -f /etc/X11/xorg.conf.d/99-touchscreen.conf ]; then
    echo "Touchscreen config already exists"
else
    echo "Creating touchscreen config..."
    sudo mkdir -p /etc/X11/xorg.conf.d
    sudo tee /etc/X11/xorg.conf.d/99-touchscreen.conf > /dev/null << 'EOF'
Section "InputClass"
    Identifier "WaveShare Touchscreen"
    MatchUSBID "0712:000a"
    Driver "libinput"
    Option "TransformationMatrix" "1 0 0 0 1 0 0 0 1"
EndSection
EOF
    echo "✅ Touchscreen config created"
fi
echo ""

echo "=========================================="
echo "✅ SETUP COMPLETE"
echo "=========================================="
echo ""
echo "Config applied:"
echo "  - disable_fw_kms_setup=0"
echo "  - video=HDMI-A-2:400x1280M@60,rotate=90"
echo "  - dtoverlay=vc4-kms-v3d-pi5,noaudio"
echo ""
echo "Reboot required. Run: sudo reboot"
echo ""
ENDSSH

echo ""
echo "✅ Setup complete on Pi at $PI_IP"
echo ""

