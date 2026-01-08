#!/bin/bash
# PI 5 FIX LANDSCAPE CUTOFF
# Fix display to show full landscape, no cutoff, no flickering

set -e

echo "=========================================="
echo "PI 5 FIX LANDSCAPE CUTOFF"
echo "Ensure full landscape display, no cutoff"
echo "=========================================="
echo ""

ssh pi2 << 'FIXLANDSCAPE'
BACKUP_DIR="/home/andre/backup_landscape_fix_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

export DISPLAY=:0

echo "=== CURRENT STATUS ==="
CURRENT_RES=$(xrandr --query 2>/dev/null | grep "HDMI-2" | grep -oP '\d+x\d+' | head -1)
CURRENT_ROT=$(xrandr --query 2>/dev/null | grep "HDMI-2" | grep -oE "normal|left|right|inverted" | head -1)
FB_SIZE=$(cat /sys/class/graphics/fb0/virtual_size 2>/dev/null || echo "")

echo "Current resolution: $CURRENT_RES"
echo "Current rotation: $CURRENT_ROT"
echo "Framebuffer: $FB_SIZE"
echo ""

echo "=== FIX STRATEGY ==="
echo "For Landscape 1280x400 display:"
echo "  1. Ensure display_rotate=3 (270° - rotates Portrait to Landscape)"
echo "  2. Use Portrait framebuffer (400x1280)"
echo "  3. X11 should use Portrait mode (400x1280)"
echo "  4. Rotation happens at framebuffer level"
echo ""

# Find config.txt
if [ -f "/boot/firmware/config.txt" ]; then
    CONFIG_FILE="/boot/firmware/config.txt"
elif [ -f "/boot/config.txt" ]; then
    CONFIG_FILE="/boot/config.txt"
else
    echo "ERROR: Cannot find config.txt"
    exit 1
fi

sudo cp "$CONFIG_FILE" "$BACKUP_DIR/config.txt.backup"

echo "=== STEP 1: ENSURE CORRECT CONFIG.TXT ==="
# Remove old rotate setting
sudo sed -i '/^display_rotate=/d' "$CONFIG_FILE"
sudo sed -i '/display_rotate=/d' "$CONFIG_FILE"

# Ensure display_rotate=3 is set
if ! grep -q "^display_rotate=3" "$CONFIG_FILE"; then
    echo "display_rotate=3" | sudo tee -a "$CONFIG_FILE"
    echo "✅ Added display_rotate=3"
else
    echo "✅ display_rotate=3 already set"
fi

# Ensure hdmi_group=0
sudo sed -i '/^hdmi_group=/d' "$CONFIG_FILE"
if ! grep -q "^hdmi_group=0" "$CONFIG_FILE"; then
    echo "hdmi_group=0" | sudo tee -a "$CONFIG_FILE"
    echo "✅ Added hdmi_group=0"
else
    echo "✅ hdmi_group=0 already set"
fi

echo ""
echo "=== STEP 2: UPDATE .xinitrc FOR PROPER LANDSCAPE ==="
cat > /tmp/.xinitrc_landscape << 'XINITEOF'
#!/bin/bash
export DISPLAY=:0

# Wait for X server
for i in {1..40}; do
    xrandr --query >/dev/null 2>&1 && break
    sleep 0.25
done

xhost +SI:localuser:andre 2>/dev/null || true
sleep 2

echo "Setting up Landscape display..." >> /tmp/xinit.log

# Use Portrait mode (400x1280) - will be rotated to Landscape by display_rotate=3
# Check if 400x1280 mode exists
if xrandr | grep -q "400x1280"; then
    echo "Using existing 400x1280 mode" >> /tmp/xinit.log
    xrandr --output HDMI-2 --mode 400x1280 --rotate normal 2>&1
else
    echo "Creating 400x1280 mode" >> /tmp/xinit.log
    TIMING=$(cvt 400 1280 60 | grep Modeline | sed 's/Modeline //')
    MODE_NAME=$(echo $TIMING | awk '{print $1}' | tr -d '"')
    xrandr --newmode $TIMING 2>&1 | grep -v "already exists" || true
    xrandr --addmode HDMI-2 "$MODE_NAME" 2>&1 | grep -v "already exists" || true
    xrandr --output HDMI-2 --mode "$MODE_NAME" --rotate normal 2>&1
fi

sleep 1
RES=$(xrandr --query 2>/dev/null | grep "HDMI-2" | grep -oP '\d+x\d+' | head -1)
echo "Display resolution set to: $RES" >> /tmp/xinit.log

# Disable blanking and flickering
xset s off 2>/dev/null || true
xset -dpms 2>/dev/null || true
xset s noblank 2>/dev/null || true

# Reduce flickering - disable compositing
export COMPOSITOR_DISABLE=1

# Start Chromium - Portrait size (will be rotated by display_rotate=3 to Landscape)
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

sleep 12

# Fix window to Portrait size (400x1280) - rotation happens at framebuffer level
for attempt in {1..20}; do
    WINDOW=$(xdotool search --class Chromium 2>/dev/null | head -1)
    if [ -n "$WINDOW" ]; then
        xdotool windowsize $WINDOW 400 1280 2>/dev/null
        xdotool windowmove $WINDOW 0 0 2>/dev/null
        
        SIZE=$(xdotool getwindowgeometry $WINDOW 2>/dev/null | grep Geometry | awk '{print $2}' || echo "")
        if [ "$SIZE" == "400x1280" ]; then
            echo "Window fixed: $SIZE (attempt $attempt)" >> /tmp/xinit.log
            break
        fi
    fi
    sleep 1
done

wait
XINITEOF

sudo cp /tmp/.xinitrc_landscape /home/andre/.xinitrc
sudo chown andre:andre /home/andre/.xinitrc
sudo chmod +x /home/andre/.xinitrc

echo "✅ .xinitrc updated for Landscape (via rotation)"

echo ""
echo "=== STEP 3: VERIFY CONFIG ==="
echo "Config.txt settings:"
sudo grep -E "display_rotate|hdmi_group" "$CONFIG_FILE" | grep -v "^#" | sort -u

echo ""
echo "=== READY FOR REBOOT ==="
FIXLANDSCAPE

echo ""
echo "=== REBOOTING PI 5 ==="
ssh pi2 "sudo reboot" || true

echo "Waiting for reboot..."
sleep 10

MAX_WAIT=120
WAITED=0
while [ $WAITED -lt $MAX_WAIT ]; do
    if ping -c 1 -W 2000 192.168.178.134 >/dev/null 2>&1; then
        echo "✅ Pi 5 online after ${WAITED}s"
        break
    fi
    sleep 3
    WAITED=$((WAITED + 3))
    echo -n "."
done

echo ""
echo "Waiting for services..."
sleep 45

echo ""
echo "=== VERIFICATION ==="
ssh pi2 << 'VERIFY'
export DISPLAY=:0

echo "1. Config:"
sudo grep -E "display_rotate|hdmi_group" /boot/config.txt 2>/dev/null | grep -v "^#" | sort -u

echo ""
echo "2. Framebuffer:"
cat /sys/class/graphics/fb0/virtual_size 2>/dev/null || echo "Cannot read"

echo ""
echo "3. Display:"
xrandr --query | grep "HDMI-2 connected"

echo ""
echo "4. Resolution:"
xrandr --query | grep "HDMI-2" | grep -oP '\d+x\d+' | head -1

echo ""
echo "5. Chromium:"
ps aux | grep chromium | grep -v grep | wc -l | xargs echo "Processes:"

echo ""
echo "6. Window:"
WINDOW=$(xdotool search --class Chromium 2>/dev/null | head -1)
if [ -n "$WINDOW" ]; then
    xdotool getwindowgeometry $WINDOW | grep Geometry
fi
VERIFY

echo ""
echo "=========================================="
echo "LANDSCAPE FIX APPLIED"
echo "=========================================="
echo ""
echo "Display should now:"
echo "  - Show full Landscape (rotated from Portrait)"
echo "  - Not be cut off"
echo "  - Have minimal flickering"
echo ""
echo "Please check display visually!"

