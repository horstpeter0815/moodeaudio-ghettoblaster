#!/bin/bash
# Start Moode Display - Force Start X11 and Chromium
# Use this if login screen appears

set -e

echo "=========================================="
echo "Starting Moode Display"
echo "=========================================="
echo ""

# Kill any existing X11
echo "Step 1: Checking for existing X11..."
if pgrep -x "X" > /dev/null || pgrep -x "Xorg" > /dev/null; then
    echo "⚠️  X11 already running, killing it..."
    pkill -9 X 2>/dev/null || true
    pkill -9 Xorg 2>/dev/null || true
    sleep 2
fi

# Kill any existing Chromium
echo "Step 2: Checking for existing Chromium..."
if pgrep -x "chromium" > /dev/null || pgrep -f "chromium" > /dev/null; then
    echo "⚠️  Chromium already running, killing it..."
    pkill -9 chromium 2>/dev/null || true
    sleep 1
fi
echo ""

# Ensure xinitrc exists and is correct
echo "Step 3: Ensuring xinitrc is correct..."
XINITRC="$HOME/.xinitrc"

if [ ! -f "$XINITRC" ] || ! grep -q "chromium" "$XINITRC"; then
    echo "Creating/fixing xinitrc..."
    
    # Backup
    if [ -f "$XINITRC" ]; then
        cp "$XINITRC" "$XINITRC.backup.$(date +%Y%m%d_%H%M%S)"
    fi
    
    # Create xinitrc
    cat > "$XINITRC" << 'XINITRC_EOF'
#!/bin/bash

# Wait for X11 to be ready
sleep 2

# Set display
export DISPLAY=:0

# Get screen resolution
SCREEN_RES=$(xrandr | grep " connected" | head -1 | awk '{print $3}' | cut -d+ -f1 | tr 'x' ',' || echo "1280,400")

# Use explicit window size if SCREEN_RES is wrong
if [ "$SCREEN_RES" = "400,1280" ] || [ -z "$SCREEN_RES" ]; then
    WINDOW_SIZE="1280,400"
else
    WINDOW_SIZE="$SCREEN_RES"
fi

# HDMI Orientation (only if portrait)
HDMI_SCN_ORIENT=$(moodeutl -q "SELECT value FROM cfg_system WHERE param='hdmi_scn_orient'" 2>/dev/null || echo "landscape")
HDMI_PORT=$(xrandr | grep " connected" | head -1 | awk '{print $1}' || echo "HDMI-2")

if [ "$HDMI_SCN_ORIENT" = "portrait" ]; then
    xrandr --output "$HDMI_PORT" --rotate left
else
    xrandr --output "$HDMI_PORT" --rotate normal
fi

# Touchscreen Configuration
sleep 1
TOUCH_DEVICE=$(xinput list | grep -i "WaveShare" | head -1 | grep -oP 'id=\K[0-9]+' || echo "")
if [ ! -z "$TOUCH_DEVICE" ]; then
    xinput set-prop "$TOUCH_DEVICE" "Coordinate Transformation Matrix" 1 0 0 0 1 0 0 0 1
fi

# Launch Chromium in kiosk mode
chromium \
    --app="http://localhost/" \
    --window-size="$WINDOW_SIZE" \
    --window-position="0,0" \
    --enable-features="OverlayScrollbar" \
    --no-first-run \
    --disable-infobars \
    --disable-session-crashed-bubble \
    --kiosk
XINITRC_EOF

    chmod +x "$XINITRC"
    echo "✅ xinitrc created/fixed"
else
    echo "✅ xinitrc already correct"
fi
echo ""

# Start X11
echo "Step 4: Starting X11..."
export DISPLAY=:0

# Kill any processes using display
fuser -k /dev/tty7 2>/dev/null || true
sleep 1

# Start X11 in background
nohup startx > /dev/null 2>&1 &
sleep 5

# Check if X11 started
if pgrep -x "X" > /dev/null || pgrep -x "Xorg" > /dev/null; then
    echo "✅ X11 started"
else
    echo "❌ X11 failed to start"
    echo "   Try: startx"
    exit 1
fi
echo ""

# Wait for Chromium
echo "Step 5: Waiting for Chromium..."
sleep 5

if pgrep -f "chromium" > /dev/null; then
    echo "✅ Chromium started"
else
    echo "⚠️  Chromium not started yet, may take a few more seconds"
    echo "   Check with: ps aux | grep chromium"
fi
echo ""

# Summary
echo "=========================================="
echo "Moode Display Started"
echo "=========================================="
echo ""
echo "Status:"
echo "  X11: $(pgrep -x X > /dev/null && echo '✅ Running' || echo '❌ Not running')"
echo "  Chromium: $(pgrep -f chromium > /dev/null && echo '✅ Running' || echo '❌ Not running')"
echo ""
echo "If Chromium is not running, wait 10 seconds and check:"
echo "  ps aux | grep chromium"
echo ""
echo "If still not working, try:"
echo "  startx"
echo ""

