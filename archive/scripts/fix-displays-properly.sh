#!/bin/bash
# Proper fix for display issues - thorough verification

set -e

echo "=========================================="
echo "PROPER DISPLAY FIX - THOROUGH VERIFICATION"
echo "=========================================="
echo ""

# System 2: Pi 5
echo "=== FIXING SYSTEM 2 (Pi 5) ==="
ssh pi2 << 'EOF'
export DISPLAY=:0

echo "1. Killing all Chromium processes..."
pkill -9 chromium 2>/dev/null || true
pkill -9 chromium-browser 2>/dev/null || true
sleep 3

echo "2. Verifying display is ready..."
xrandr --query | grep "HDMI-2 connected"
RESOLUTION=$(xrandr --query | grep "HDMI-2" | grep -oP '\d+x\d+' | head -1)
echo "Resolution: $RESOLUTION"

echo "3. Starting Chromium in proper fullscreen kiosk mode..."
chromium-browser \
    --kiosk \
    --start-fullscreen \
    --noerrdialogs \
    --disable-infobars \
    --disable-session-crashed-bubble \
    --disable-restore-session-state \
    --disable-web-security \
    --disable-features=TranslateUI \
    --app=http://localhost \
    >/dev/null 2>&1 &

sleep 8

echo "4. Finding Chromium window..."
WINDOW=$(xdotool search --class Chromium 2>/dev/null | head -1)
if [ -n "$WINDOW" ]; then
    echo "Window ID: $WINDOW"
    echo "Making fullscreen..."
    xdotool windowactivate $WINDOW
    sleep 1
    xdotool key F11
    sleep 2
    
    echo "5. Verifying window size..."
    xdotool getwindowgeometry $WINDOW
fi

echo "6. Final check - window status:"
xwininfo -root -tree | grep -i chromium | grep -E "1280x400|fullscreen" || xwininfo -root -tree | grep -i chromium | head -1
EOF

echo ""
echo "=== FIXING SYSTEM 3 (Pi 4) ==="
ssh pi3 << 'EOF'
export DISPLAY=:0

echo "1. Ensuring localdisplay is running..."
sudo systemctl start localdisplay 2>/dev/null || true
sleep 5

echo "2. Verifying X server..."
ps aux | grep -E 'Xorg|X ' | grep -v grep || echo "X server not running!"
sleep 2

echo "3. Verifying display is ready..."
xrandr --query | grep "HDMI-2 connected"
RESOLUTION=$(xrandr --query | grep "HDMI-2" | grep -oP '\d+x\d+' | head -1)
echo "Resolution: $RESOLUTION"

echo "4. Killing all Chromium processes..."
pkill -9 chromium 2>/dev/null || true
pkill -9 chromium-browser 2>/dev/null || true
sleep 3

echo "5. Starting Chromium in proper fullscreen kiosk mode..."
chromium-browser \
    --kiosk \
    --start-fullscreen \
    --noerrdialogs \
    --disable-infobars \
    --disable-session-crashed-bubble \
    --disable-restore-session-state \
    --disable-web-security \
    --disable-features=TranslateUI \
    --app=http://localhost \
    >/dev/null 2>&1 &

sleep 8

echo "6. Finding Chromium window..."
WINDOW=$(xdotool search --class Chromium 2>/dev/null | head -1)
if [ -n "$WINDOW" ]; then
    echo "Window ID: $WINDOW"
    echo "Making fullscreen..."
    xdotool windowactivate $WINDOW
    sleep 1
    xdotool key F11
    sleep 2
    
    echo "7. Verifying window size..."
    xdotool getwindowgeometry $WINDOW
fi

echo "8. Final check - window status:"
xwininfo -root -tree | grep -i chromium | head -1
EOF

echo ""
echo "=== FIXING SYSTEM 1 (HiFiBerryOS) - TOUCH ==="
ssh pi1 << 'EOF'
echo "1. Checking touch screen devices..."
ls -la /dev/input/event* 2>/dev/null | head -5
echo ""

echo "2. Checking input devices..."
cat /proc/bus/input/devices | grep -A 5 -i "touch\|input" | head -20
echo ""

echo "3. Testing touch screen..."
timeout 2 cat /dev/input/event0 2>/dev/null | head -c 1 && echo "Touch device responding" || echo "Touch device check..."
echo ""

echo "4. Checking if touch is configured in weston..."
ps aux | grep weston | grep -v grep
EOF

echo ""
echo "=========================================="
echo "FIX COMPLETE - PLEASE CHECK DISPLAYS"
echo "=========================================="

