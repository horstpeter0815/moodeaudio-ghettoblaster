#!/bin/bash
# PI 5 FIX - ACCEPT FRAMEBUFFER AND ROTATE EVERYTHING
# Chief Engineer: If framebuffer is 400x1280, rotate everything to match

set -e

echo "=========================================="
echo "PI 5 FRAMEBUFFER ROTATION FIX"
echo "Accept framebuffer orientation and match everything"
echo "=========================================="
echo ""

ssh pi2 << 'ROTATEFIX'
BACKUP_DIR="/home/andre/backup_rotate_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

echo "=== STRATEGY: ACCEPT FRAMEBUFFER 400x1280, ROTATE X11 ==="
echo "If framebuffer is 400x1280 (portrait), we'll rotate X11 display 90°"

echo ""
echo "=== STEP 1: CHECK CURRENT FRAMEBUFFER ==="
FB_SIZE=$(cat /sys/class/graphics/fb0/virtual_size 2>/dev/null || echo "unknown")
echo "Framebuffer: $FB_SIZE"

if echo "$FB_SIZE" | grep -q "400,1280"; then
    echo "Framebuffer is Portrait (400x1280)"
    echo "Solution: Rotate X11 display 90° to match"
    ROTATION_NEEDED="left"  # Rotate left to match portrait framebuffer
elif echo "$FB_SIZE" | grep -q "1280,400"; then
    echo "Framebuffer is Landscape (1280x400)"
    echo "Solution: No rotation needed"
    ROTATION_NEEDED="normal"
else
    echo "Unknown framebuffer size, will try left rotation"
    ROTATION_NEEDED="left"
fi

echo ""
echo "=== STEP 2: UPDATE CONFIG.TXT WITH DISPLAY_ROTATE ==="
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

# Remove old display_rotate
sudo sed -i '/^display_rotate=/d' "$CONFIG_FILE"

# Add correct rotation
if [ "$ROTATION_NEEDED" == "left" ]; then
    echo "Adding display_rotate=1 (90° left)" | sudo tee -a "$CONFIG_FILE"
    echo "display_rotate=1" | sudo tee -a "$CONFIG_FILE"
else
    echo "Adding display_rotate=0 (normal)" | sudo tee -a "$CONFIG_FILE"
    echo "display_rotate=0" | sudo tee -a "$CONFIG_FILE"
fi

echo "✅ config.txt updated"

echo ""
echo "=== STEP 3: CREATE .xinitrc TO MATCH FRAMEBUFFER ==="
cat > /tmp/.xinitrc_rotated << 'XINITEOF'
#!/bin/bash
export DISPLAY=:0

# Wait for X
for i in {1..30}; do
    xrandr --query >/dev/null 2>&1 && break
    sleep 0.2
done

xhost +SI:localuser:andre 2>/dev/null || true
sleep 1

# Check framebuffer orientation
FB_SIZE=$(cat /sys/class/graphics/fb0/virtual_size 2>/dev/null || echo "")
echo "Framebuffer: $FB_SIZE" >> /tmp/xinit.log

if echo "$FB_SIZE" | grep -q "400,1280"; then
    # Framebuffer is Portrait - use 400x1280 mode with normal rotation
    echo "Using Portrait mode to match framebuffer" >> /tmp/xinit.log
    
    # Try to use existing 400x1280 mode
    if xrandr | grep -q "400x1280"; then
        xrandr --output HDMI-2 --mode 400x1280 --rotate normal 2>&1
    else
        # Create 400x1280 mode
        TIMING=$(cvt 400 1280 60 | grep Modeline | sed 's/Modeline //')
        MODE_NAME=$(echo $TIMING | awk '{print $1}' | tr -d '"')
        xrandr --newmode $TIMING 2>&1 | grep -v "already exists" || true
        xrandr --addmode HDMI-2 "$MODE_NAME" 2>&1 | grep -v "already exists" || true
        xrandr --output HDMI-2 --mode "$MODE_NAME" --rotate normal 2>&1
    fi
    
    WINDOW_SIZE="400 1280"
else
    # Framebuffer is Landscape - use 1280x400 mode
    echo "Using Landscape mode" >> /tmp/xinit.log
    
    TIMING=$(cvt 1280 400 60 | grep Modeline | sed 's/Modeline //')
    MODE_NAME=$(echo $TIMING | awk '{print $1}' | tr -d '"')
    xrandr --newmode $TIMING 2>&1 | grep -v "already exists" || true
    xrandr --addmode HDMI-2 "$MODE_NAME" 2>&1 | grep -v "already exists" || true
    xrandr --output HDMI-2 --mode "$MODE_NAME" --rotate normal 2>&1
    
    WINDOW_SIZE="1280 400"
fi

# Disable blanking
xset s off 2>/dev/null || true
xset -dpms 2>/dev/null || true
xset s noblank 2>/dev/null || true

# Start Chromium
chromium-browser \
    --kiosk \
    --no-sandbox \
    --user-data-dir=/tmp/chromium-data \
    --window-size=$WINDOW_SIZE \
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

sleep 8

# Fix window to match framebuffer
for i in {1..10}; do
    WINDOW=$(xdotool search --class Chromium 2>/dev/null | head -1)
    if [ -n "$WINDOW" ]; then
        if echo "$FB_SIZE" | grep -q "400,1280"; then
            xdotool windowsize $WINDOW 400 1280 2>/dev/null
        else
            xdotool windowsize $WINDOW 1280 400 2>/dev/null
        fi
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

echo "✅ .xinitrc created to match framebuffer"

echo ""
echo "=== READY FOR REBOOT ==="
ROTATEFIX

echo ""
echo "=== REBOOTING ==="
ssh pi2 "sudo reboot" || true

echo "Waiting for reboot..."
sleep 10

MAX_WAIT=90
WAITED=0
while [ $WAITED -lt $MAX_WAIT ]; do
    if ping -c 1 -W 2000 192.168.178.134 >/dev/null 2>&1; then
        echo "✅ Pi 5 online"
        break
    fi
    sleep 2
    WAITED=$((WAITED + 2))
    echo -n "."
done

echo ""
echo "Waiting for services..."
sleep 40

echo ""
echo "=== FINAL VERIFICATION ==="
ssh pi2 << 'VERIFY'
export DISPLAY=:0

echo "1. Framebuffer:"
cat /sys/class/graphics/fb0/virtual_size 2>/dev/null || echo "Cannot read"

echo ""
echo "2. Display resolution:"
xrandr --query | grep "HDMI-2" | grep -oP '\d+x\d+' | head -1

echo ""
echo "3. Display rotation:"
xrandr --query | grep "HDMI-2" | grep -E "normal|left|right|inverted"

echo ""
echo "4. Chromium window:"
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

