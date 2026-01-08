#!/bin/bash
# PI 5 LANDSCAPE FIX - DIRECT EXECUTION
# Run this directly on Pi 5 or via SSH when connection works

set -e

export DISPLAY=:0

echo "=========================================="
echo "PI 5 LANDSCAPE FIX - DIRECT"
echo "Fix cutoff and flickering"
echo "=========================================="
echo ""

# Find config.txt
CONFIG_FILE="/boot/config.txt"
[ -f "/boot/firmware/config.txt" ] && CONFIG_FILE="/boot/firmware/config.txt"

echo "=== STEP 1: FIX CONFIG.TXT ==="
sudo sed -i '/^display_rotate=/d' "$CONFIG_FILE"
sudo sed -i '/display_rotate=/d' "$CONFIG_FILE"
sudo sed -i '/^hdmi_group=/d' "$CONFIG_FILE"
echo "display_rotate=3" | sudo tee -a "$CONFIG_FILE" > /dev/null
echo "hdmi_group=0" | sudo tee -a "$CONFIG_FILE" > /dev/null
echo "✅ Config.txt fixed"

echo ""
echo "=== STEP 2: FIX .xinitrc ==="
cat > /tmp/.xinitrc_landscape << 'XINITEOF'
#!/bin/bash
export DISPLAY=:0

for i in {1..40}; do
    xrandr --query >/dev/null 2>&1 && break
    sleep 0.25
done

xhost +SI:localuser:andre 2>/dev/null || true
sleep 2

# Portrait mode - rotated to Landscape by display_rotate=3
if xrandr | grep -q "400x1280"; then
    xrandr --output HDMI-2 --mode 400x1280 --rotate normal 2>&1
else
    TIMING=$(cvt 400 1280 60 | grep Modeline | sed 's/Modeline //')
    MODE_NAME=$(echo $TIMING | awk '{print $1}' | tr -d '"')
    xrandr --newmode $TIMING 2>&1 | grep -v "already exists" || true
    xrandr --addmode HDMI-2 "$MODE_NAME" 2>&1 | grep -v "already exists" || true
    xrandr --output HDMI-2 --mode "$MODE_NAME" --rotate normal 2>&1
fi

xset s off 2>/dev/null || true
xset -dpms 2>/dev/null || true
xset s noblank 2>/dev/null || true

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
    http://localhost >/dev/null 2>&1 &

sleep 12

for i in {1..20}; do
    WINDOW=$(xdotool search --class Chromium 2>/dev/null | head -1)
    if [ -n "$WINDOW" ]; then
        xdotool windowsize $WINDOW 400 1280 2>/dev/null
        xdotool windowmove $WINDOW 0 0 2>/dev/null
        break
    fi
    sleep 1
done

wait
XINITEOF

sudo cp /tmp/.xinitrc_landscape /home/andre/.xinitrc
sudo chown andre:andre /home/andre/.xinitrc
sudo chmod +x /home/andre/.xinitrc
echo "✅ .xinitrc fixed"

echo ""
echo "=== STEP 3: RESTART DISPLAY SERVICE ==="
sudo systemctl restart localdisplay
echo "✅ Display service restarted"

echo ""
echo "=========================================="
echo "FIX APPLIED - CHECK DISPLAY!"
echo "=========================================="
echo ""
echo "Display should now:"
echo "  - Show full Landscape (not cut off)"
echo "  - No flickering"
echo ""

