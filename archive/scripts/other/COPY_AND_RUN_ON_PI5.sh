#!/bin/bash
# ==========================================
# COPY THIS ENTIRE SCRIPT TO PI 5 AND RUN IT
# ==========================================
# On Pi 5, paste this entire script and run:
# bash <(cat << 'SCRIPT_EOF'
# [paste entire script here]
# SCRIPT_EOF
# )

set -e

echo "=========================================="
echo "FIXING DISPLAY - EXECUTING NOW"
echo "=========================================="

USER=$(whoami)
HOME_DIR=$(eval echo ~$USER)

# Kill everything
echo "Stopping processes..."
killall -9 chromium chromium-browser X Xorg startx 2>/dev/null || true
systemctl stop lightdm gdm 2>/dev/null || true
systemctl disable lightdm gdm 2>/dev/null || true
sleep 2

# Fix xinitrc
echo "Fixing xinitrc..."
XINITRC="$HOME_DIR/.xinitrc"
[ -f "$XINITRC" ] && cp "$XINITRC" "$XINITRC.backup.$(date +%Y%m%d_%H%M%S)"

cat > "$XINITRC" << 'EOF'
#!/bin/bash
sleep 2
export DISPLAY=:0
HDMI_PORT=$(xrandr | grep " connected" | head -1 | awk '{print $1}' || echo "HDMI-2")
HDMI_SCN_ORIENT=$(moodeutl -q "SELECT value FROM cfg_system WHERE param='hdmi_scn_orient'" 2>/dev/null || echo "landscape")
[ "$HDMI_SCN_ORIENT" = "portrait" ] && xrandr --output "$HDMI_PORT" --rotate left || xrandr --output "$HDMI_PORT" --rotate normal
sleep 1
TOUCH_DEVICE=$(xinput list | grep -i "WaveShare" | head -1 | grep -oP 'id=\K[0-9]+' || echo "")
[ ! -z "$TOUCH_DEVICE" ] && xinput set-prop "$TOUCH_DEVICE" "Coordinate Transformation Matrix" 1 0 0 0 1 0 0 0 1
SCREEN_RES=$(xrandr | grep " connected" | head -1 | awk '{print $3}' | cut -d+ -f1 | tr 'x' ',' || echo "1280,400")
[ "$SCREEN_RES" = "400,1280" ] && WINDOW_SIZE="1280,400" || WINDOW_SIZE="$SCREEN_RES"
chromium --app="http://localhost/" --window-size="$WINDOW_SIZE" --window-position="0,0" --enable-features="OverlayScrollbar" --no-first-run --disable-infobars --disable-session-crashed-bubble --kiosk
EOF

chmod +x "$XINITRC"

# Fix touchscreen
echo "Fixing touchscreen..."
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

# Start X11
echo "Starting X11..."
fuser -k /dev/tty7 2>/dev/null || true
sleep 1
export DISPLAY=:0
nohup startx > /tmp/startx.log 2>&1 &
sleep 5

echo "=========================================="
echo "DONE - Check display in 10 seconds"
echo "=========================================="

