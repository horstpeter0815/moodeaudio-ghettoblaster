#!/bin/bash
# PI 5 FIX FRAMEBUFFER ORIENTATION - CHIEF ENGINEER SOLUTION
# Fix the root cause: Framebuffer is Portrait, needs to be Landscape

set -e

echo "=========================================="
echo "PI 5 FRAMEBUFFER ORIENTATION FIX"
echo "Chief Engineer - Root Cause Solution"
echo "=========================================="
echo ""

ssh pi2 << 'FRAMEBUFFERFIX'
BACKUP_DIR="/home/andre/backup_framebuffer_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

echo "=== PROBLEM IDENTIFIED ==="
FB_SIZE=$(cat /sys/class/graphics/fb0/virtual_size 2>/dev/null || echo "unknown")
echo "Current framebuffer: $FB_SIZE"
echo "Problem: Framebuffer is Portrait (400x1280), but we need Landscape (1280x400)"

echo ""
echo "=== SOLUTION: USE DISPLAY_ROTATE TO ROTATE FRAMEBUFFER ==="
echo "If framebuffer is 400x1280, we'll rotate it 270° to get 1280x400"

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

# Remove all display_rotate entries
sudo sed -i '/^display_rotate=/d' "$CONFIG_FILE"
sudo sed -i '/display_rotate=/d' "$CONFIG_FILE"

# Strategy: If framebuffer is 400x1280, rotate 270° (or -90°) to get 1280x400
# display_rotate values: 0=0°, 1=90°, 2=180°, 3=270°
# Rotating 400x1280 by 270° = 1280x400

echo ""
echo "=== ADDING DISPLAY_ROTATE=3 (270°) ==="
echo "This rotates framebuffer 270°: 400x1280 → 1280x400"
echo "display_rotate=3" | sudo tee -a "$CONFIG_FILE"

echo ""
echo "=== ALSO TRY ALTERNATIVE: REMOVE FRAMEBUFFER DIMENSIONS ==="
# Remove framebuffer_width/height - let system auto-detect
sudo sed -i '/^framebuffer_width=/d' "$CONFIG_FILE"
sudo sed -i '/^framebuffer_height=/d' "$CONFIG_FILE"

echo "✅ config.txt updated:"
sudo grep -E "display_rotate|framebuffer" "$CONFIG_FILE" | tail -5

echo ""
echo "=== UPDATING .xinitrc FOR ROTATED FRAMEBUFFER ==="
cat > /tmp/.xinitrc_rotated << 'XINITEOF'
#!/bin/bash
export DISPLAY=:0

# Wait for X
for i in {1..40}; do
    xrandr --query >/dev/null 2>&1 && break
    sleep 0.25
done

xhost +SI:localuser:andre 2>/dev/null || true
sleep 1.5

# After framebuffer rotation, X11 should see correct orientation
# But we need to verify what X11 actually sees

FB_SIZE=$(cat /sys/class/graphics/fb0/virtual_size 2>/dev/null || echo "")
echo "Framebuffer after rotation: $FB_SIZE" >> /tmp/xinit.log

# Create 1280x400 mode
TIMING=$(cvt 1280 400 60 | grep Modeline | sed 's/Modeline //')
MODE_NAME=$(echo $TIMING | awk '{print $1}' | tr -d '"')

xrandr --delmode HDMI-2 "$MODE_NAME" 2>/dev/null || true
xrandr --rmmode "$MODE_NAME" 2>/dev/null || true
xrandr --newmode $TIMING 2>&1 | grep -v "already exists" || true
xrandr --addmode HDMI-2 "$MODE_NAME" 2>&1 | grep -v "already exists" || true

# Try normal first, then adjust if needed
xrandr --output HDMI-2 --mode "$MODE_NAME" --rotate normal 2>&1

sleep 1
RES=$(xrandr --query 2>/dev/null | grep "HDMI-2" | grep -oP '\d+x\d+' | head -1)
echo "Display resolution: $RES" >> /tmp/xinit.log

# Disable blanking
xset s off 2>/dev/null || true
xset -dpms 2>/dev/null || true
xset s noblank 2>/dev/null || true

# Start Chromium
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

sleep 10

# Fix window
for i in {1..15}; do
    WINDOW=$(xdotool search --class Chromium 2>/dev/null | head -1)
    if [ -n "$WINDOW" ]; then
        xdotool windowsize $WINDOW 1280 400 2>/dev/null
        xdotool windowmove $WINDOW 0 0 2>/dev/null
        sleep 1
    fi
    sleep 1
done

wait
XINITEOF

sudo cp /tmp/.xinitrc_rotated /home/andre/.xinitrc
sudo chown andre:andre /home/andre/.xinitrc
sudo chmod +x /home/andre/.xinitrc

echo "✅ .xinitrc updated"

echo ""
echo "=== READY FOR REBOOT ==="
FRAMEBUFFERFIX

echo ""
echo "=== REBOOTING ==="
ssh pi2 "sudo reboot" || true

echo "Waiting for reboot..."
sleep 10

MAX_WAIT=120
WAITED=0
while [ $WAITED -lt $MAX_WAIT ]; do
    if ping -c 1 -W 2000 192.168.178.134 >/dev/null 2>&1; then
        echo "✅ Pi 5 online"
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

echo "1. Framebuffer (after rotation):"
cat /sys/class/graphics/fb0/virtual_size 2>/dev/null || echo "Cannot read"

echo ""
echo "2. Display:"
xrandr --query | grep "HDMI-2 connected"

echo ""
echo "3. Resolution:"
xrandr --query | grep "HDMI-2" | grep -oP '\d+x\d+' | head -1

echo ""
echo "4. Window:"
WINDOW=$(xdotool search --class Chromium 2>/dev/null | head -1)
if [ -n "$WINDOW" ]; then
    xdotool getwindowgeometry $WINDOW | grep Geometry
fi

echo ""
echo "5. Xinit log:"
cat /tmp/xinit.log 2>/dev/null | tail -5 || echo "No log"
VERIFY

echo ""
echo "=========================================="
echo "FRAMEBUFFER ROTATION FIX COMPLETE"
echo "=========================================="

