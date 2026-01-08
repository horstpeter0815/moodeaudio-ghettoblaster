#!/bin/bash
# PI 5 COMPREHENSIVE DISPLAY DIAGNOSIS
# Chief Engineer - Complete Analysis

set -e

echo "=========================================="
echo "PI 5 COMPREHENSIVE DISPLAY DIAGNOSIS"
echo "Chief Engineer - Deep Analysis"
echo "=========================================="
echo ""

ssh pi2 << 'DIAGNOSIS'
export DISPLAY=:0

echo "=== 1. CURRENT DISPLAY STATE ==="
echo "HDMI-2 Status:"
xrandr --query | grep "HDMI-2"
echo ""

echo "=== 2. ALL AVAILABLE MODES ==="
echo "Available modes for HDMI-2:"
xrandr | grep -A 20 "HDMI-2 connected" | grep -E "^[[:space:]]+[0-9]" | head -10
echo ""

echo "=== 3. CURRENT MODE DETAILS ==="
MODE=$(xrandr --query | grep "HDMI-2" | grep -oP '\d+x\d+@\d+' | head -1)
echo "Current mode: $MODE"
cvt 1280 400 60 | grep Modeline
echo ""

echo "=== 4. DISPLAY TIMINGS ==="
xrandr --verbose | grep -A 10 "HDMI-2 connected" | grep -E "CRTC|EDID|refresh" | head -10
echo ""

echo "=== 5. WINDOW STATE ==="
xwininfo -root -tree 2>/dev/null | grep -i chromium | head -5
echo ""

echo "=== 6. CHROMIUM PROCESSES ==="
ps aux | grep chromium | grep -v grep | wc -l | xargs echo "Processes:"
echo ""

echo "=== 7. X SERVER LOG ERRORS ==="
tail -50 /var/log/Xorg.0.log | grep -iE "error|warn|fail" | head -10
echo ""

echo "=== 8. DISPLAY HARDWARE INFO ==="
cat /sys/class/drm/card0-HDMI-A-2/status 2>/dev/null || echo "Cannot read DRM status"
echo ""

echo "=== 9. VIDEO MODE SETTINGS ==="
cat /sys/class/drm/card0-HDMI-A-2/modes 2>/dev/null || echo "Cannot read modes"
echo ""

echo "=== 10. CURRENT RESOLUTION FROM DRM ==="
cat /sys/class/drm/card0-HDMI-A-2/current_mode 2>/dev/null || echo "Cannot read current mode"
echo ""

echo "=== 11. FRAMEBUFFER STATE ==="
cat /sys/class/graphics/fb0/virtual_size 2>/dev/null || echo "Cannot read framebuffer"
cat /sys/class/graphics/fb0/mode 2>/dev/null || echo "Cannot read framebuffer mode"
echo ""

echo "=== 12. GPU MEMORY ==="
vcgencmd get_mem gpu 2>/dev/null || echo "vcgencmd not available"
echo ""

echo "=== 13. DISPLAY POWER STATE ==="
xset q | grep -E "DPMS|Screen Saver" || echo "Cannot query power state"
echo ""

echo "=== 14. ALL DISPLAY OUTPUTS ==="
xrandr --listmonitors
echo ""

echo "=== 15. DISPLAY PROPERTIES ==="
xrandr --props | grep -A 15 "HDMI-2" | head -20
echo ""

echo "=== 16. CURRENT ROTATION STATE ==="
xrandr --query | grep "HDMI-2" | grep -oE "normal|left|right|inverted"
echo ""

echo "=== 17. CHROMIUM WINDOW PROPERTIES ==="
WINDOW=$(xdotool search --class Chromium 2>/dev/null | head -1)
if [ -n "$WINDOW" ]; then
    echo "Window ID: $WINDOW"
    xdotool getwindowgeometry $WINDOW
    xdotool getwindowname $WINDOW
fi
echo ""

echo "=== 18. SYSTEM TIMING ==="
systemd-analyze time | head -5
echo ""

echo "=== 19. DISPLAY SERVICE STATUS ==="
systemctl status localdisplay --no-pager | head -15
echo ""

echo "=== 20. RECENT X ERRORS ==="
journalctl -u localdisplay -n 50 --no-pager | grep -iE "error|warn|fail" | tail -10
echo ""
DIAGNOSIS

echo ""
echo "=== COLLECTING COMPLETE INFORMATION ==="
echo "Diagnosis complete. Analyzing results..."

