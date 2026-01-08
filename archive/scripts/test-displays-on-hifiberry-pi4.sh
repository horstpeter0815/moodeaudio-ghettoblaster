#!/bin/bash
# TEST DISPLAYS ON HIFIBERRY PI 4
# Check if "damaged" displays actually work on working system

set -e

echo "=========================================="
echo "TEST DISPLAYS ON HIFIBERRY PI 4"
echo "Verify if displays are actually damaged"
echo "=========================================="
echo ""

echo "=== CURRENT HIFIBERRY PI 4 STATUS ==="
ssh pi3 << 'HIFISTATUS'
export DISPLAY=:0 2>/dev/null || true

echo "1. Current display configuration:"
xrandr --query 2>/dev/null | grep connected

echo ""
echo "2. Framebuffer:"
cat /sys/class/graphics/fb0/virtual_size 2>/dev/null || echo "Cannot read"

echo ""
echo "3. Config.txt key settings:"
sudo grep -E "display_rotate|hdmi_group|hdmi_mode|hdmi_cvt|dtoverlay" /boot/firmware/config.txt 2>/dev/null | grep -v "^#" | head -10

echo ""
echo "4. Display service:"
systemctl is-active localdisplay && echo "Active" || echo "Not active"

echo ""
echo "=== READY TO TEST DISPLAYS ==="
echo "If you have a 'damaged' display:"
echo "  1. Connect it to HiFiBerry Pi 4"
echo "  2. Run this script again to check status"
echo "  3. If it works: Display is OK, problem is Pi 5 config"
echo "  4. If it doesn't: Display may be damaged"
HIFISTATUS

echo ""
echo "=========================================="
echo "TEST READY"
echo "=========================================="
echo ""
echo "Next: Connect display and check if it works!"

