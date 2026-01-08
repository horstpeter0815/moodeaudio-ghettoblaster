#!/bin/bash
# Inline fix - executes directly on Pi 5 without copying files
# Usage: ./INLINE_FIX.sh [username] [password]

PI5_IP="192.168.178.178"
PI5_USER="${1:-pi}"
PI5_PASS="${2}"

if [ -z "$PI5_PASS" ]; then
    echo "Usage: $0 [username] [password]"
    echo "Example: $0 pi moodeaudio"
    exit 1
fi

echo "=========================================="
echo "Executing fix directly on Pi 5"
echo "=========================================="

# Check if sshpass is available
if ! command -v sshpass &> /dev/null; then
    echo "Installing sshpass..."
    brew install hudochenkov/sshpass/sshpass 2>/dev/null || {
        echo "ERROR: Could not install sshpass"
        echo "Please install manually: brew install hudochenkov/sshpass/sshpass"
        exit 1
    }
fi

# Execute inline script on Pi 5
sshpass -p "$PI5_PASS" ssh -o StrictHostKeyChecking=no "$PI5_USER@$PI5_IP" bash << 'REMOTE_SCRIPT'
set -e
echo "FIXING DISPLAY NOW..."
USER=$(whoami)
HOME_DIR=$(eval echo ~$USER)
killall -9 chromium chromium-browser X Xorg startx 2>/dev/null || true
systemctl stop lightdm gdm 2>/dev/null || true
systemctl disable lightdm gdm 2>/dev/null || true
sleep 2
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
fuser -k /dev/tty7 2>/dev/null || true
sleep 1
export DISPLAY=:0
nohup startx > /tmp/startx.log 2>&1 &
sleep 5
echo "DONE - Check display in 10 seconds"
REMOTE_SCRIPT

echo ""
echo "=========================================="
echo "Fix executed! Check Pi 5 display now."
echo "=========================================="

