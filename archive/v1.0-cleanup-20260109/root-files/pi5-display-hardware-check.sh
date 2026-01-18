#!/bin/bash
# PI 5 DISPLAY HARDWARE CHECK
# Check new display - backlight only issue

set -e

echo "=========================================="
echo "PI 5 DISPLAY HARDWARE CHECK"
echo "New display: Backlight only"
echo "=========================================="
echo ""

ssh pi2 << 'HARDWARECHECK'
export DISPLAY=:0

echo "=== CURRENT STATUS ==="
echo "1. HDMI ports:"
xrandr --query | grep HDMI
echo ""

echo "2. Active display:"
xrandr --query | grep "connected"
echo ""

echo "3. Display resolution:"
xrandr --query | grep "HDMI-2" | grep -oP '\d+x\d+' | head -1
echo ""

echo "=== TROUBLESHOOTING ==="
echo ""
echo "4. Try HDMI-A-1 port (other HDMI port on Pi 5):"
echo "   Current: HDMI-A-2"
echo "   Alternative: HDMI-A-1"
echo ""

echo "5. Check HDMI status:"
cat /sys/class/drm/card1-HDMI-A-1/status 2>/dev/null && echo "HDMI-A-1 status"
cat /sys/class/drm/card1-HDMI-A-2/status 2>/dev/null && echo "HDMI-A-2 status"
echo ""

echo "6. Try standard mode to test display:"
echo "   Testing with 1280x720 (standard HDMI)..."
xrandr --output HDMI-2 --mode 1280x720 2>&1
sleep 3
echo "   Did image appear? Checking resolution:"
xrandr --query | grep "HDMI-2" | grep -oP '\d+x\d+' | head -1
echo ""

echo "7. Return to 1280x400:"
xrandr --output HDMI-2 --mode "1280x400_60.00" 2>&1 || xrandr --output HDMI-2 --auto
echo ""

echo "=== RECOMMENDATIONS ==="
echo ""
echo "If display shows only backlight:"
echo "  1. Try different HDMI cable"
echo "  2. Try HDMI-A-1 port on Pi 5"
echo "  3. Test display on another device (laptop/computer)"
echo "  4. Check if display works at 1280x720"
echo ""
echo "If old displays flickered even on Pi 4:"
echo "  - Displays are likely damaged/defective"
echo "  - Need replacement displays"
HARDWARECHECK

echo ""
echo "=========================================="
echo "HARDWARE CHECK COMPLETE"
echo "=========================================="

