#!/bin/bash
# Final window fix - ensures correct size after Chromium starts

echo "=========================================="
echo "FINAL WINDOW SIZE FIX"
echo "=========================================="

# System 3: Fix window size
echo "=== SYSTEM 3: Fixing window size ==="
ssh pi3 << 'EOF'
export DISPLAY=:0

echo "1. Finding all Chromium windows..."
xdotool search --class Chromium 2>/dev/null | while read win; do
    echo "   Window: $win"
    xdotool getwindowgeometry $win 2>/dev/null | head -2
done

echo ""
echo "2. Resizing main window to 400x1280..."
# Get the main Chromium window (not popup/clipboard)
MAIN_WIN=$(xdotool search --class Chromium --name "Player" 2>/dev/null | head -1)
if [ -z "$MAIN_WIN" ]; then
    MAIN_WIN=$(xdotool search --class Chromium 2>/dev/null | head -1)
fi

if [ -n "$MAIN_WIN" ]; then
    echo "   Main window ID: $MAIN_WIN"
    xdotool windowsize $MAIN_WIN 400 1280
    xdotool windowmove $MAIN_WIN 0 0
    sleep 1
    
    echo "3. Verifying..."
    xdotool getwindowgeometry $MAIN_WIN
else
    echo "   ERROR: Could not find main window"
fi

echo ""
echo "4. Final window tree:"
xwininfo -root -tree 2>/dev/null | grep -i chromium | head -3
EOF

echo ""
echo "=== SYSTEM 2: Checking status ==="
ssh pi2 << 'EOF'
export DISPLAY=:0
echo "1. X server status:"
xrandr --query | grep "HDMI-2 connected" || echo "X not ready"

echo ""
echo "2. Chromium processes:"
ps aux | grep chromium | grep -v grep | wc -l

echo ""
echo "3. Checking service logs:"
journalctl -u localdisplay -n 20 --no-pager | tail -10
EOF

echo ""
echo "=========================================="

