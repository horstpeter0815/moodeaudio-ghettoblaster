#!/bin/bash
# CHECK PI 5 AFTER REBOOT
# Verify Pi 4 approach was applied correctly

set -e

echo "=========================================="
echo "CHECK PI 5 AFTER REBOOT"
echo "Verify Pi 4 approach configuration"
echo "=========================================="
echo ""

# Wait for Pi 5 to be online
echo "Waiting for Pi 5 to come online..."
MAX_WAIT=180
WAITED=0

while [ $WAITED -lt $MAX_WAIT ]; do
    if ping -c 1 -W 2000 192.168.178.134 >/dev/null 2>&1; then
        echo "✅ Pi 5 is online after ${WAITED}s"
        break
    fi
    sleep 5
    WAITED=$((WAITED + 5))
    echo -n "."
done

if [ $WAITED -ge $MAX_WAIT ]; then
    echo ""
    echo "⚠️ Pi 5 did not come online within timeout"
    echo "Please check:"
    echo "  - Is Pi 5 powered on?"
    echo "  - Network connection?"
    echo "  - Boot issues?"
    exit 1
fi

echo ""
echo "Waiting for services to start..."
sleep 30

echo ""
echo "=== COMPREHENSIVE CHECK ==="
ssh pi2 << 'COMPCHECK'
export DISPLAY=:0

echo "=== SYSTEM STATUS ==="
echo ""
echo "1. Uptime:"
uptime

echo ""
echo "2. Config.txt - Display settings:"
sudo grep -E "display_rotate|hdmi_group|hdmi_cvt|hdmi_mode" /boot/config.txt 2>/dev/null | grep -v "^#" | sort -u

echo ""
echo "3. Framebuffer:"
cat /sys/class/graphics/fb0/virtual_size 2>/dev/null || echo "Cannot read"

echo ""
echo "4. Display (X11):"
xrandr --query | grep "HDMI-2 connected"

echo ""
echo "5. Resolution:"
xrandr --query | grep "HDMI-2" | grep -oP '\d+x\d+' | head -1

echo ""
echo "6. Display service:"
systemctl is-active localdisplay && echo "✅ Active" || echo "❌ Not active"

echo ""
echo "7. Chromium:"
ps aux | grep chromium | grep -v grep | wc -l | xargs echo "Processes:"

echo ""
echo "8. Window (if Chromium running):"
WINDOW=$(xdotool search --class Chromium 2>/dev/null | head -1)
if [ -n "$WINDOW" ]; then
    xdotool getwindowgeometry $WINDOW | grep Geometry
else
    echo "Chromium window not found"
fi

echo ""
echo "=== VERIFICATION COMPLETE ==="
echo ""
echo "Expected:"
echo "  - display_rotate=3"
echo "  - hdmi_group=0"
echo "  - Framebuffer: 400,1280"
echo "  - Display: Portrait mode"
COMPCHECK

echo ""
echo "=========================================="
echo "CHECK COMPLETE"
echo "=========================================="
echo ""
echo "Please check display visually:"
echo "  - Is image visible?"
echo "  - Is orientation correct (Landscape)?"
echo "  - Any flickering?"
echo "  - Any black noise?"

