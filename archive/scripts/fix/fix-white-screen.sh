#!/bin/bash
# FIX WHITE SCREEN ON PI 5
# Chromium showing white screen - fix immediately

set -e

echo "=========================================="
echo "FIX WHITE SCREEN - PI 5"
echo "=========================================="
echo ""

ssh pi2 << 'FIXWHITE'
export DISPLAY=:0

echo "=== DIAGNOSING WHITE SCREEN ==="
echo ""

# Check Chromium
CHROMIUM_COUNT=$(ps aux | grep chromium | grep -v grep | wc -l)
echo "Chromium processes: $CHROMIUM_COUNT"

# Check display
echo ""
echo "Display status:"
xrandr --query | grep "HDMI-2 connected"

# Check window
echo ""
echo "Window status:"
WINDOW=$(xdotool search --class Chromium 2>/dev/null | head -1)
if [ -n "$WINDOW" ]; then
    echo "Window found: $WINDOW"
    xdotool getwindowgeometry $WINDOW
else
    echo "No Chromium window found"
fi

echo ""
echo "=== FIXING WHITE SCREEN ==="

# Kill existing Chromium
echo "Stopping existing Chromium..."
pkill -f chromium-browser || true
sleep 2

# Clear Chromium cache
echo "Clearing Chromium cache..."
rm -rf /tmp/chromium-data/* 2>/dev/null || true

# Ensure display is correct
echo "Setting display mode..."
if xrandr | grep -q "400x1280"; then
    xrandr --output HDMI-2 --mode 400x1280 --rotate normal 2>&1
else
    TIMING=$(cvt 400 1280 60 | grep Modeline | sed 's/Modeline //')
    MODE_NAME=$(echo $TIMING | awk '{print $1}' | tr -d '"')
    xrandr --newmode $TIMING 2>&1 | grep -v "already exists" || true
    xrandr --addmode HDMI-2 "$MODE_NAME" 2>&1 | grep -v "already exists" || true
    xrandr --output HDMI-2 --mode "$MODE_NAME" --rotate normal 2>&1
fi

sleep 2

# Start Chromium fresh
echo "Starting Chromium..."
chromium-browser \
    --kiosk \
    --no-sandbox \
    --user-data-dir=/tmp/chromium-data \
    --window-size=400,1280 \
    --window-position=0,0 \
    --start-fullscreen \
    --noerrdialogs \
    --disable-infobars \
    --disable-session-crashed-bubble \
    --disable-restore-session-state \
    --disable-web-security \
    --autoplay-policy=no-user-gesture-required \
    --check-for-update-interval=31536000 \
    --disable-features=TranslateUI \
    --disable-gpu \
    --disable-software-rasterizer \
    --disable-dev-shm-usage \
    http://localhost >/dev/null 2>&1 &

sleep 10

# Fix window
echo "Fixing window size..."
for i in {1..15}; do
    WINDOW=$(xdotool search --class Chromium 2>/dev/null | head -1)
    if [ -n "$WINDOW" ]; then
        xdotool windowsize $WINDOW 400 1280 2>/dev/null
        xdotool windowmove $WINDOW 0 0 2>/dev/null
        
        # Try to ensure page loads
        xdotool key --window $WINDOW F5
        sleep 2
        
        break
    fi
    sleep 1
done

echo ""
echo "✅ White screen fix applied"
echo ""
echo "If still white, checking if moOde web interface is running..."
systemctl is-active nginx && echo "✅ Nginx running" || echo "⚠️ Nginx not running"
systemctl is-active mpd && echo "✅ MPD running" || echo "⚠️ MPD not running"
FIXWHITE

echo ""
echo "=========================================="
echo "WHITE SCREEN FIX COMPLETE"
echo "=========================================="


