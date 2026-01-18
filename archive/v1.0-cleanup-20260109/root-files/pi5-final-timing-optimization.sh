#!/bin/bash
# PI 5 FINAL TIMING OPTIMIZATION
# Optimize all timing and ensure proper sequencing

set -e

echo "=========================================="
echo "PI 5 FINAL TIMING OPTIMIZATION"
echo "=========================================="
echo ""

ssh pi2 << 'FIX'
# Create optimized .xinitrc with better timing
cat > /tmp/.xinitrc_optimized << 'EOF'
#!/bin/bash
export DISPLAY=:0

# Wait for X server - smarter polling
echo "Waiting for X server..." >> /tmp/xinit-start.log
for i in {1..20}; do
    if xrandr --query >/dev/null 2>&1; then
        echo "X server ready after ${i} attempts" >> /tmp/xinit-start.log
        break
    fi
    sleep 0.3
done

# CRITICAL FOR PI 5: Allow user andre to access X server
xhost +SI:localuser:andre 2>/dev/null || true

# Set up display resolution (NO rotation - landscape 1280x400)
xrandr --newmode "1280x400_60.00" 27.00 1280 1328 1456 1632 400 403 413 421 -hsync +vsync 2>&1
xrandr --addmode HDMI-2 "1280x400_60.00" 2>&1
xrandr --output HDMI-2 --mode "1280x400_60.00" --rotate normal 2>&1

# Verify display is ready
for i in {1..10}; do
    RES=$(xrandr --query 2>/dev/null | grep "HDMI-2" | grep -oP '\d+x\d+' | head -1)
    if [ "$RES" == "1280x400" ]; then
        echo "Display ready: $RES" >> /tmp/xinit-start.log
        break
    fi
    sleep 0.5
done

# Disable screen blanking
xset s off 2>/dev/null || true
xset -dpms 2>/dev/null || true
xset s noblank 2>/dev/null || true

# Start Chromium
echo "Starting Chromium..." >> /tmp/xinit-start.log
chromium-browser \
    --kiosk \
    --no-sandbox \
    --user-data-dir=/tmp/chromium-data \
    --window-size=1280,400 \
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
    http://localhost >/dev/null 2>&1 &

CHROMIUM_PID=$!
echo "Chromium PID: $CHROMIUM_PID" >> /tmp/xinit-start.log

# Wait for Chromium to create window - smart polling
echo "Waiting for Chromium window..." >> /tmp/xinit-start.log
for i in {1..15}; do
    WINDOW=$(xdotool search --class Chromium 2>/dev/null | head -1)
    if [ -n "$WINDOW" ]; then
        echo "Window found: $WINDOW" >> /tmp/xinit-start.log
        break
    fi
    sleep 1
done

# Fix window size with retry logic
if [ -n "$WINDOW" ]; then
    echo "Fixing window size..." >> /tmp/xinit-start.log
    for attempt in {1..5}; do
        xdotool windowsize $WINDOW 1280 400 2>/dev/null
        xdotool windowmove $WINDOW 0 0 2>/dev/null
        sleep 0.5
        
        SIZE=$(xdotool getwindowgeometry $WINDOW 2>/dev/null | grep Geometry | awk '{print $2}' || echo "")
        if [ "$SIZE" == "1280x400" ]; then
            echo "Window fixed: $SIZE" >> /tmp/xinit-start.log
            break
        fi
    done
fi

# Keep process alive
wait $CHROMIUM_PID
EOF

sudo cp /tmp/.xinitrc_optimized /home/andre/.xinitrc
sudo chown andre:andre /home/andre/.xinitrc
sudo chmod +x /home/andre/.xinitrc

echo "✅ Optimized .xinitrc created"
FIX

echo ""
echo "=== RESTARTING WITH OPTIMIZED TIMING ==="
ssh pi2 "sudo systemctl restart localdisplay"

echo "Waiting 25 seconds for full initialization..."
sleep 25

echo ""
echo "=== VERIFICATION ==="
ssh pi2 << 'VERIFY'
export DISPLAY=:0

echo "1. Display:"
xrandr --query | grep "HDMI-2" | head -1

echo ""
echo "2. Resolution:"
xrandr --query | grep "HDMI-2" | grep -oP '\d+x\d+' | head -1

echo ""
echo "3. Rotation:"
xrandr --query | grep "HDMI-2" | grep -E "normal|left|right|inverted"

echo ""
echo "4. Chromium:"
ps aux | grep chromium | grep -v grep | wc -l | xargs echo "Processes:"

echo ""
echo "5. Window:"
xwininfo -root -tree 2>/dev/null | grep -i chromium | head -1

echo ""
echo "6. Window size:"
WINDOW=$(xdotool search --class Chromium 2>/dev/null | head -1)
if [ -n "$WINDOW" ]; then
    xdotool getwindowgeometry $WINDOW 2>/dev/null | grep Geometry
fi

echo ""
echo "7. Startup log:"
cat /tmp/xinit-start.log 2>/dev/null | tail -10 || echo "No log yet"
VERIFY

echo ""
echo "=========================================="
echo "TIMING OPTIMIZATION COMPLETE"
echo "=========================================="

