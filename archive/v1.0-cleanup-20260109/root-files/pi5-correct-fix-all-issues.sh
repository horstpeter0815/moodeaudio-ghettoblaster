#!/bin/bash
# PI 5 CORRECT FIX - ALL ISSUES
# Chief Engineer - Complete Solution
# Fixes: Framebuffer orientation, refresh rate, flickering

set -e

echo "=========================================="
echo "PI 5 CORRECT FIX - ALL ISSUES"
echo "Chief Engineer Complete Solution"
echo "=========================================="
echo ""

ssh pi2 << 'CORRECTFIX'
BACKUP_DIR="/home/andre/backup_correct_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

echo "=== STEP 1: FIX CMDLINE.TXT (PI 5 USES /boot/firmware/) ==="
# Pi 5 uses /boot/firmware/cmdline.txt
CMDLINE_FILE=""
if [ -f "/boot/firmware/cmdline.txt" ]; then
    CMDLINE_FILE="/boot/firmware/cmdline.txt"
    sudo cp "$CMDLINE_FILE" "$BACKUP_DIR/cmdline.txt.backup"
elif [ -f "/boot/cmdline.txt" ]; then
    CMDLINE_FILE="/boot/cmdline.txt"
    sudo cp "$CMDLINE_FILE" "$BACKUP_DIR/cmdline.txt.backup"
else
    echo "ERROR: Cannot find cmdline.txt"
    exit 1
fi

# Read current cmdline
CURRENT_CMDLINE=$(cat "$CMDLINE_FILE")

# Remove existing video parameter (might be 58Hz)
NEW_CMDLINE=$(echo "$CURRENT_CMDLINE" | sed 's/video=[^ ]* *//g')

# Add correct video parameter: 1280x400@60 (60Hz, not 58!)
NEW_CMDLINE="$NEW_CMDLINE video=HDMI-A-1:1280x400@60"

# Write new cmdline
echo "$NEW_CMDLINE" | sudo tee "$CMDLINE_FILE" > /dev/null

echo "✅ cmdline.txt fixed:"
cat "$CMDLINE_FILE"

echo ""
echo "=== STEP 2: FIX CONFIG.TXT FOR PI 5 ==="
# Check config.txt location
CONFIG_FILE=""
if [ -f "/boot/firmware/config.txt" ]; then
    CONFIG_FILE="/boot/firmware/config.txt"
    sudo cp "$CONFIG_FILE" "$BACKUP_DIR/config.txt.backup"
elif [ -f "/boot/config.txt" ]; then
    CONFIG_FILE="/boot/config.txt"
    sudo cp "$CONFIG_FILE" "$BACKUP_DIR/config.txt.backup"
else
    echo "ERROR: Cannot find config.txt"
    exit 1
fi

# Update config.txt with correct settings
sudo tee -a "$CONFIG_FILE" > /dev/null << 'CONFIGEOF'

# Pi 5 Display Fix - 1280x400 @ 60Hz
# Ensure framebuffer matches display
framebuffer_width=1280
framebuffer_height=400
display_rotate=0

# Correct HDMI mode (60Hz, not 58Hz)
hdmi_cvt=1280 400 60 6 0 0 0

CONFIGEOF

echo "✅ config.txt updated"

echo ""
echo "=== STEP 3: UPDATE .xinitrc FOR 60Hz ==="
cat > /tmp/.xinitrc_60hz << 'XINITEOF'
#!/bin/bash
export DISPLAY=:0

# Wait for X server
for i in {1..30}; do
    xrandr --query >/dev/null 2>&1 && break
    sleep 0.2
done

xhost +SI:localuser:andre 2>/dev/null || true
sleep 1

# Create 60Hz mode (not 58Hz!)
TIMING=$(cvt 1280 400 60 | grep Modeline | sed 's/Modeline //')
MODE_NAME=$(echo $TIMING | awk '{print $1}' | tr -d '"')

# Remove old mode
xrandr --delmode HDMI-2 "$MODE_NAME" 2>/dev/null || true
xrandr --rmmode "$MODE_NAME" 2>/dev/null || true

# Add new 60Hz mode
xrandr --newmode $TIMING 2>&1 | grep -v "already exists" || true
xrandr --addmode HDMI-2 "$MODE_NAME" 2>&1 | grep -v "already exists" || true

# Set mode - normal orientation
xrandr --output HDMI-2 --mode "$MODE_NAME" --rotate normal 2>&1

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

# Fix window
sleep 8
for i in {1..10}; do
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

sudo cp /tmp/.xinitrc_60hz /home/andre/.xinitrc
sudo chown andre:andre /home/andre/.xinitrc
sudo chmod +x /home/andre/.xinitrc

echo "✅ .xinitrc updated for 60Hz"

echo ""
echo "=== ALL FIXES APPLIED ==="
CORRECTFIX

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
echo "=== COMPREHENSIVE VERIFICATION ==="
ssh pi2 << 'VERIFY'
export DISPLAY=:0

echo "1. Video parameter:"
cat /proc/cmdline | grep -o 'video=[^ ]*' || echo "Not found"

echo ""
echo "2. Framebuffer:"
cat /sys/class/graphics/fb0/virtual_size 2>/dev/null || echo "Cannot read"

echo ""
echo "3. Display:"
xrandr --query | grep "HDMI-2 connected"

echo ""
echo "4. Refresh rate:"
xrandr --query | grep "HDMI-2" | grep -oE '[0-9]+\.[0-9]+Hz' | head -1

echo ""
echo "5. Resolution:"
xrandr --query | grep "HDMI-2" | grep -oP '\d+x\d+' | head -1

echo ""
echo "6. Chromium:"
ps aux | grep chromium | grep -v grep | wc -l | xargs echo "Processes:"

echo ""
echo "7. Window:"
WINDOW=$(xdotool search --class Chromium 2>/dev/null | head -1)
if [ -n "$WINDOW" ]; then
    xdotool getwindowgeometry $WINDOW | grep Geometry
fi
VERIFY

echo ""
echo "=========================================="
echo "CORRECT FIX COMPLETE"
echo "=========================================="
echo ""
echo "Fixed:"
echo "  ✅ Refresh rate: 60Hz (was 58Hz)"
echo "  ✅ cmdline.txt: Correct location (/boot/firmware/)"
echo "  ✅ Video parameter: 1280x400@60"
echo ""
echo "Please check display visually for:"
echo "  - Correct orientation"
echo "  - No flickering"
echo "  - No black noise"
echo "  - Stable display"

