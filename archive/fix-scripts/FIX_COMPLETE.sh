#!/bin/bash
# FIX COMPLETE - CREATE FULL CONFIG
# sudo /Users/andrevollmer/moodeaudio-cursor/FIX_COMPLETE.sh

SD_MOUNT="/Volumes/bootfs"
[ ! -d "$SD_MOUNT" ] && SD_MOUNT="/Volumes/boot"

echo "=== STEP 1: SSH FLAG ==="
sudo sh -c "touch $SD_MOUNT/ssh && chmod 644 $SD_MOUNT/ssh"
sync
[ -f "$SD_MOUNT/ssh" ] && echo "✅ SSH-Flag" || echo "❌ SSH-Flag"
echo ""

echo "=== STEP 2: CREATE COMPLETE CONFIG.TXT ==="
sudo tee "$SD_MOUNT/config.txt" > /dev/null << 'EOF'
# This file is managed by moOde

# Device filters
[cm4]
otg_mode=1

[pi4]
hdmi_force_hotplug:0=1
hdmi_force_hotplug:1=1
hdmi_enable_4kp60=0

[pi5]
display_rotate=2
dtoverlay=vc4-kms-v3d-pi5,noaudio
hdmi_enable_4kp60=0
hdmi_timings=400 0 220 32 110 1280 0 10 10 10 0 0 0 60 0 59510000 0
hdmi_ignore_edid=0xa5000080
hdmi_force_hotplug=1
disable_splash=1

# General settings
[all]
hdmi_group=2
hdmi_mode=87
hdmi_drive=2
hdmi_blanking=0
dtoverlay=vc4-kms-v3d
max_framebuffers=2
display_auto_detect=1
arm_64bit=1
arm_boost=1
disable_overscan=1
dtparam=i2c_arm=on
dtparam=i2c_arm_baudrate=100000
dtparam=i2c_vc=on
dtparam=i2s=on
dtparam=audio=off

# Do not alter this section
# Integrated adapters
#dtoverlay=disable-bt
#dtoverlay=disable-wifi
# PCI Express
#dtparam=pciex1
#dtparam=pciex1_gen=3
# Pi Touch1
#dtoverlay=vc4-kms-dsi-7inch,invx,invy
# Fan speed
#dtparam=fan_temp0=50000,fan_temp0_hyst=5000,fan_temp0_speed=75

# Audio overlays
dtoverlay=hifiberry-amp100
force_eeprom_read=0
EOF

sync
echo "✅ config.txt erstellt"
echo ""

echo "=== STEP 3: FIX CMDLINE.TXT ==="
CMDLINE_FILE="$SD_MOUNT/cmdline.txt"
CMDLINE=$(cat "$CMDLINE_FILE")
CMDLINE=$(echo "$CMDLINE" | sed 's/ fbcon=rotate:[0-9]//g')
if ! echo "$CMDLINE" | grep -q "fbcon=rotate:3"; then
    CMDLINE="${CMDLINE} fbcon=rotate:3"
fi
echo "$CMDLINE" | sudo tee "$CMDLINE_FILE" > /dev/null
sync
echo "✅ cmdline.txt gefixt"
echo ""

echo "=== VERIFICATION ==="
[ -f "$SD_MOUNT/ssh" ] && echo "SSH: ✅" || echo "SSH: ❌"
grep -q "display_rotate=2" "$SD_MOUNT/config.txt" && echo "Display: ✅" || echo "Display: ❌"
grep -q "fbcon=rotate:3" "$CMDLINE_FILE" && echo "fbcon: ✅" || echo "fbcon: ❌"
echo ""
echo "✅ FERTIG"

