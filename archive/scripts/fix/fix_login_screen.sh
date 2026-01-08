#!/bin/bash
# Fix Login Screen Issue
# Moode Audio should start automatically, not show login screen

echo "=========================================="
echo "Fixing Login Screen Issue"
echo "=========================================="
echo ""

# Check 1: Is X11 running?
echo "Check 1: X11 Status"
if pgrep -x "X" > /dev/null || pgrep -x "Xorg" > /dev/null; then
    echo "✅ X11 is running"
    export DISPLAY=:0
else
    echo "⚠️  X11 is not running"
    echo "   This might be why you see login screen"
fi
echo ""

# Check 2: Is Chromium running?
echo "Check 2: Chromium Status"
if pgrep -x "chromium" > /dev/null || pgrep -f "chromium" > /dev/null; then
    echo "✅ Chromium is running"
else
    echo "❌ Chromium is NOT running"
    echo "   This is why you see login screen instead of Moode"
fi
echo ""

# Check 3: Check xinitrc
echo "Check 3: xinitrc Configuration"
XINITRC="$HOME/.xinitrc"
if [ -f "$XINITRC" ]; then
    echo "✅ xinitrc exists"
    if grep -q "chromium" "$XINITRC"; then
        echo "✅ Chromium is configured in xinitrc"
    else
        echo "❌ Chromium NOT in xinitrc!"
        echo "   This is the problem!"
    fi
else
    echo "❌ xinitrc does NOT exist!"
    echo "   This is the problem!"
fi
echo ""

# Check 4: Check if startx is configured
echo "Check 4: startx Configuration"
if [ -f "$HOME/.xinitrc" ]; then
    echo "✅ xinitrc exists"
    if [ -x "$HOME/.xinitrc" ]; then
        echo "✅ xinitrc is executable"
    else
        echo "⚠️  xinitrc is not executable, fixing..."
        chmod +x "$HOME/.xinitrc"
    fi
else
    echo "❌ xinitrc missing!"
fi
echo ""

# Check 5: Check systemd service for X11
echo "Check 5: X11 Service Status"
if systemctl is-active --quiet graphical.target 2>/dev/null; then
    echo "✅ Graphical target is active"
else
    echo "⚠️  Graphical target not active"
fi

if systemctl is-active --quiet lightdm 2>/dev/null; then
    echo "⚠️  LightDM is running (display manager)"
    echo "   This might be showing login screen"
elif systemctl is-active --quiet gdm 2>/dev/null; then
    echo "⚠️  GDM is running (display manager)"
    echo "   This might be showing login screen"
else
    echo "✅ No display manager running (good for Moode)"
fi
echo ""

# Fix: Ensure xinitrc has Chromium
echo "=========================================="
echo "Fixing xinitrc"
echo "=========================================="

if [ ! -f "$XINITRC" ] || ! grep -q "chromium" "$XINITRC"; then
    echo "Creating/fixing xinitrc..."
    
    # Backup
    if [ -f "$XINITRC" ]; then
        cp "$XINITRC" "$XINITRC.backup.$(date +%Y%m%d_%H%M%S)"
    fi
    
    # Create basic xinitrc with Chromium
    cat > "$XINITRC" << 'XINITRC_EOF'
#!/bin/bash

# Wait for X11 to be ready
sleep 2

# Set display
export DISPLAY=:0

# Get screen resolution
SCREEN_RES=$(xrandr | grep " connected" | head -1 | awk '{print $3}' | cut -d+ -f1 | tr 'x' ',' || echo "1280,400")

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
# Use explicit window size if SCREEN_RES is wrong
if [ "$SCREEN_RES" = "400,1280" ] || [ -z "$SCREEN_RES" ]; then
    WINDOW_SIZE="1280,400"
else
    WINDOW_SIZE="$SCREEN_RES"
fi

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
    echo "✅ xinitrc already has Chromium"
fi
echo ""

# Fix: Start X11 if not running
echo "=========================================="
echo "Starting X11"
echo "=========================================="

if ! pgrep -x "X" > /dev/null && ! pgrep -x "Xorg" > /dev/null; then
    echo "Starting X11..."
    export DISPLAY=:0
    
    # Kill any processes using display
    fuser -k /dev/tty7 2>/dev/null || true
    sleep 1
    
    # Start X11 in background
    nohup startx > /tmp/startx.log 2>&1 &
    sleep 5
    
    # Check if started
    if pgrep -x "X" > /dev/null || pgrep -x "Xorg" > /dev/null; then
        echo "✅ X11 started"
    else
        echo "⚠️  X11 may have failed to start"
        echo "   Check: cat /tmp/startx.log"
        echo "   Try manually: startx"
    fi
else
    echo "✅ X11 already running"
fi
echo ""

# Summary
echo "=========================================="
echo "Fix Complete"
echo "=========================================="
echo ""
echo "If you still see login screen:"
echo "  1. Press Ctrl+Alt+F1 to get to console"
echo "  2. Login"
echo "  3. Run: startx"
echo "  4. Or reboot: sudo reboot"
echo ""
echo "To check status:"
echo "  ps aux | grep chromium"
echo "  ps aux | grep X"
echo ""

