#!/bin/bash
# PI 5 FIX USING PI 4 APPROACH
# Use same configuration method that works on HiFiBerry Pi 4

set -e

echo "=========================================="
echo "PI 5 FIX - USING PI 4 APPROACH"
echo "Apply working HiFiBerry Pi 4 configuration"
echo "=========================================="
echo ""

ssh pi2 << 'PI5FIX'
BACKUP_DIR="/home/andre/backup_pi4_approach_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

echo "=== STRATEGY ==="
echo "HiFiBerry Pi 4 works with:"
echo "  - display_rotate=3 (270° rotation)"
echo "  - Standard HDMI (hdmi_group=0)"
echo "  - No custom resolution"
echo ""
echo "Pi 5 currently uses:"
echo "  - display_rotate=0"
echo "  - Custom hdmi_cvt resolution"
echo "  - This causes mismatch!"
echo ""

echo "=== FIX: APPLY PI 4 APPROACH TO PI 5 ==="

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

echo ""
echo "=== STEP 1: REMOVE CUSTOM RESOLUTION ==="
# Remove custom resolution settings
sudo sed -i '/hdmi_cvt=/d' "$CONFIG_FILE"
sudo sed -i '/hdmi_cvt /d' "$CONFIG_FILE"
sudo sed -i '/hdmi_mode=87/d' "$CONFIG_FILE"
sudo sed -i '/hdmi_group=2/d' "$CONFIG_FILE"
sudo sed -i '/framebuffer_width=/d' "$CONFIG_FILE"
sudo sed -i '/framebuffer_height=/d' "$CONFIG_FILE"

echo "✅ Removed custom resolution settings"

echo ""
echo "=== STEP 2: SET STANDARD HDMI LIKE PI 4 ==="
# Remove display_rotate if exists
sudo sed -i '/^display_rotate=/d' "$CONFIG_FILE"
sudo sed -i '/display_rotate=/d' "$CONFIG_FILE"

# Add Pi 4 approach settings
sudo tee -a "$CONFIG_FILE" > /dev/null << 'PI4APPROACH'

# Display configuration - Pi 4 approach (WORKING!)
# Use standard HDMI with rotation instead of custom resolution
hdmi_group=0
display_rotate=3
hdmi_force_hotplug=1
display_auto_detect=1

PI4APPROACH

echo "✅ Added Pi 4 approach settings"

echo ""
echo "=== STEP 3: UPDATE .xinitrc FOR PORTRAIT MODE ==="
cat > /tmp/.xinitrc_pi4approach << 'XINITEOF'
#!/bin/bash
export DISPLAY=:0

# Wait for X
for i in {1..40}; do
    xrandr --query >/dev/null 2>&1 && break
    sleep 0.25
done

xhost +SI:localuser:andre 2>/dev/null || true
sleep 1.5

# Use Portrait mode (400x1280) like Pi 4, X11 will rotate it
echo "Using Pi 4 approach: Portrait mode + rotation" >> /tmp/xinit.log

# Check what modes are available
AVAILABLE=$(xrandr | grep "HDMI-2" | grep -oP '\d+x\d+' | head -1)
echo "Available mode: $AVAILABLE" >> /tmp/xinit.log

# Use available Portrait mode if it exists
if xrandr | grep -q "400x1280"; then
    echo "Using 400x1280 Portrait mode" >> /tmp/xinit.log
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
echo "Display resolution: $RES" >> /tmp/xinit.log

# Disable blanking
xset s off 2>/dev/null || true
xset -dpms 2>/dev/null || true
xset s noblank 2>/dev/null || true

# Start Chromium - Portrait size, will be rotated by display_rotate=3
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
    http://localhost >/dev/null 2>&1 &

sleep 10

# Fix window for Portrait mode
for i in {1..15}; do
    WINDOW=$(xdotool search --class Chromium 2>/dev/null | head -1)
    if [ -n "$WINDOW" ]; then
        xdotool windowsize $WINDOW 400 1280 2>/dev/null
        xdotool windowmove $WINDOW 0 0 2>/dev/null
        sleep 1
    fi
    sleep 1
done

wait
XINITEOF

sudo cp /tmp/.xinitrc_pi4approach /home/andre/.xinitrc
sudo chown andre:andre /home/andre/.xinitrc
sudo chmod +x /home/andre/.xinitrc

echo "✅ .xinitrc updated for Pi 4 approach"

echo ""
echo "=== STEP 4: VERIFY CONFIG ==="
echo "New config.txt settings:"
sudo grep -E "display_rotate|hdmi_group|hdmi_cvt|hdmi_mode" "$CONFIG_FILE" | grep -v "^#"

echo ""
echo "=== READY FOR REBOOT ==="
PI5FIX

echo ""
echo "=== REBOOTING PI 5 ==="
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

echo "1. Framebuffer:"
cat /sys/class/graphics/fb0/virtual_size 2>/dev/null || echo "Cannot read"

echo ""
echo "2. Display:"
xrandr --query | grep "HDMI-2 connected"

echo ""
echo "3. Resolution:"
xrandr --query | grep "HDMI-2" | grep -oP '\d+x\d+' | head -1

echo ""
echo "4. Config settings:"
sudo grep -E "display_rotate|hdmi_group" /boot/config.txt 2>/dev/null | grep -v "^#"

echo ""
echo "5. Xinit log:"
cat /tmp/xinit.log 2>/dev/null | tail -10 || echo "No log yet"
VERIFY

echo ""
echo "=========================================="
echo "PI 4 APPROACH APPLIED TO PI 5"
echo "=========================================="
echo ""
echo "Display should now work like on HiFiBerry Pi 4:"
echo "  - Portrait framebuffer (400x1280)"
echo "  - Rotated 270° to show Landscape"
echo "  - No custom resolution"
echo ""
echo "Please check display visually!"

