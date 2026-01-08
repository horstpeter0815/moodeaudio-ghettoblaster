#!/bin/bash
# MASTER FIX - EXECUTE THIS ON PI 5
# This script fixes EVERYTHING: login screen, display, touchscreen

set -e

echo "=========================================="
echo "MASTER FIX - FIXING EVERYTHING NOW"
echo "=========================================="
echo ""

# Get current user
USER=$(whoami)
HOME_DIR=$(eval echo ~$USER)

# Step 1: Kill all X11/Chromium processes
echo "Step 1: Stopping existing processes..."
killall -9 chromium chromium-browser X Xorg startx 2>/dev/null || true
sleep 2

# Step 2: Disable display managers
echo "Step 2: Disabling display managers..."
systemctl stop lightdm 2>/dev/null || true
systemctl stop gdm 2>/dev/null || true
systemctl disable lightdm 2>/dev/null || true
systemctl disable gdm 2>/dev/null || true
sleep 1

# Step 3: Fix xinitrc
echo "Step 3: Fixing xinitrc..."
XINITRC="$HOME_DIR/.xinitrc"

# Backup
if [ -f "$XINITRC" ]; then
    cp "$XINITRC" "$XINITRC.backup.$(date +%Y%m%d_%H%M%S)"
fi

# Create proper xinitrc
cat > "$XINITRC" << 'XINITRC_EOF'
#!/bin/bash

# Wait for X11
sleep 2
export DISPLAY=:0

# Get HDMI port
HDMI_PORT=$(xrandr | grep " connected" | head -1 | awk '{print $1}' || echo "HDMI-2")

# Get Moode orientation setting
HDMI_SCN_ORIENT=$(moodeutl -q "SELECT value FROM cfg_system WHERE param='hdmi_scn_orient'" 2>/dev/null || echo "landscape")

# Set rotation based on Moode setting
if [ "$HDMI_SCN_ORIENT" = "portrait" ]; then
    xrandr --output "$HDMI_PORT" --rotate left
else
    xrandr --output "$HDMI_PORT" --rotate normal
fi

# Touchscreen fix
sleep 1
TOUCH_DEVICE=$(xinput list | grep -i "WaveShare" | head -1 | grep -oP 'id=\K[0-9]+' || echo "")
if [ ! -z "$TOUCH_DEVICE" ]; then
    xinput set-prop "$TOUCH_DEVICE" "Coordinate Transformation Matrix" 1 0 0 0 1 0 0 0 1
fi

# Launch Chromium
SCREEN_RES=$(xrandr | grep " connected" | head -1 | awk '{print $3}' | cut -d+ -f1 | tr 'x' ',' || echo "1280,400")
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
echo "✅ xinitrc fixed"

# Step 4: Fix touchscreen X11 config
echo "Step 4: Fixing touchscreen..."
sudo mkdir -p /etc/X11/xorg.conf.d
sudo tee /etc/X11/xorg.conf.d/99-touchscreen.conf > /dev/null << 'EOF'
Section "InputClass"
    Identifier "WaveShare Touchscreen"
    MatchUSBID "0712:000a"
    MatchIsTouchscreen "on"
    Driver "libinput"
    Option "TransformationMatrix" "1 0 0 0 1 0 0 0 1"
EndSection
EOF
echo "✅ Touchscreen config fixed"

# Step 5: Start X11
echo "Step 5: Starting X11..."
fuser -k /dev/tty7 2>/dev/null || true
sleep 1

# Start X11 as current user
export DISPLAY=:0
nohup startx > /tmp/startx.log 2>&1 &
sleep 5

# Step 6: Verify
echo "Step 6: Verifying..."
sleep 3

if pgrep -x "X" > /dev/null || pgrep -x "Xorg" > /dev/null; then
    echo "✅ X11 is running"
else
    echo "⚠️  X11 may not have started"
    echo "   Check: cat /tmp/startx.log"
fi

if pgrep -f "chromium" > /dev/null; then
    echo "✅ Chromium is running"
else
    echo "⚠️  Chromium not running yet (may need a moment)"
fi

echo ""
echo "=========================================="
echo "FIX COMPLETE"
echo "=========================================="
echo ""
echo "If Moode UI doesn't appear:"
echo "  1. Wait 10 seconds"
echo "  2. Check: ps aux | grep chromium"
echo "  3. Try: startx"
echo "  4. Or reboot: sudo reboot"
echo ""

