#!/bin/bash
# Pi 5 Diagnostic Script
# Run this on the Pi 5 to gather system information

echo "=========================================="
echo "Pi 5 System Diagnostic"
echo "Date: $(date)"
echo "=========================================="
echo ""

echo "=== SYSTEM INFORMATION ==="
echo "Kernel Version:"
uname -r
echo ""
echo "Firmware Version:"
vcgencmd version
echo ""
echo "Moode Version:"
if [ -f /var/www/moode_version.txt ]; then
    cat /var/www/moode_version.txt
else
    echo "Not found - check Moode UI"
fi
echo ""

echo "=== DISPLAY INFORMATION ==="
echo "DRM Devices:"
ls -la /sys/class/drm/
echo ""
echo "xrandr Output:"
DISPLAY=:0 xrandr 2>/dev/null || echo "X11 not running or no display"
echo ""
echo "Framebuffer:"
fbset -s 2>/dev/null || echo "fbset not available"
echo ""
echo "Active Displays:"
for card in /sys/class/drm/card*/status; do
    if [ -f "$card" ]; then
        echo "$(dirname $card): $(cat $card)"
    fi
done
echo ""

echo "=== CONFIGURATION FILES ==="
echo "config.txt (first 50 lines):"
head -50 /boot/firmware/config.txt 2>/dev/null || head -50 /boot/config.txt 2>/dev/null
echo ""
echo "cmdline.txt:"
cat /boot/firmware/cmdline.txt 2>/dev/null || cat /boot/cmdline.txt 2>/dev/null
echo ""

echo "=== KMS MODULES ==="
echo "Loaded KMS modules:"
lsmod | grep -E "vc4|drm"
echo ""

echo "=== HDMI STATUS ==="
echo "HDMI Power:"
vcgencmd display_power 2>/dev/null || echo "Command not available"
echo ""
echo "HDMI Groups/Modes:"
vcgencmd get_config hdmi_group 2>/dev/null || echo "Not set"
vcgencmd get_config hdmi_mode 2>/dev/null || echo "Not set"
echo ""

echo "=== TOUCHSCREEN ==="
echo "USB Input Devices:"
ls -la /dev/input/ | grep -i touch
echo ""
echo "I2C Devices:"
i2cdetect -y 1 2>/dev/null || echo "I2C bus 1 not available"
echo ""

echo "=== MOODE DISPLAY SETTINGS ==="
if command -v moodeutl &> /dev/null; then
    echo "HDMI Screen Orientation:"
    moodeutl -q "SELECT value FROM cfg_system WHERE param='hdmi_scn_orient'" 2>/dev/null || echo "Not set"
    echo "DSI Screen Type:"
    moodeutl -q "SELECT value FROM cfg_system WHERE param='dsi_scn_type'" 2>/dev/null || echo "Not set"
else
    echo "moodeutl not available"
fi
echo ""

echo "=== X11 CONFIGURATION ==="
if [ -f /home/andre/.xinitrc ]; then
    echo "xinitrc exists (showing display-related lines):"
    grep -E "xrandr|DISPLAY|chromium|window-size" /home/andre/.xinitrc || echo "No display config found"
else
    echo "xinitrc not found at /home/andre/.xinitrc"
fi
echo ""

echo "=========================================="
echo "Diagnostic Complete"
echo "=========================================="

