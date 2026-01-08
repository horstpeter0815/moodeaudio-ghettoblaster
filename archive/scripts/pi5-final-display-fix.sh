#!/bin/bash
# PI 5 FINAL DISPLAY FIX - CHIEF ENGINEER
# Complete solution for framebuffer orientation and display issues

set -e

echo "=========================================="
echo "PI 5 FINAL DISPLAY FIX"
echo "Chief Engineer - Complete Solution"
echo "=========================================="
echo ""

ssh pi2 << 'COMPLETE_FIX'
# Backup
BACKUP_DIR="/home/andre/backup_final_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"
sudo cp /boot/config.txt "$BACKUP_DIR/config.txt.backup" 2>/dev/null || true
cp /home/andre/.xinitrc "$BACKUP_DIR/.xinitrc.backup" 2>/dev/null || true

echo "=== FIX 1: COMPLETE CONFIG.TXT REWRITE ==="
sudo mount -o remount,rw /boot

# Create proper config.txt for Pi 5
sudo tee /boot/config.txt > /dev/null << 'CONFIGEOF'
#########################################
# Pi 5 Display Configuration - 1280x400
# This file is managed by moOde
#########################################

[pi5]
dtoverlay=vc4-kms-v3d-pi5,noaudio
hdmi_enable_4kp60=0

[all]
max_framebuffers=2
disable_fw_kms_setup=0
arm_64bit=1
arm_boost=1
disable_splash=0
disable_overscan=1

# Display Configuration
display_rotate=0
framebuffer_width=1280
framebuffer_height=400

# GPU Memory - Pi 5 uses different syntax
# Try without gpu_mem first, Pi 5 manages it differently

# HDMI Settings
hdmi_ignore_hotplug=0
display_auto_detect=1
hdmi_force_hotplug=1
hdmi_blanking=0
hdmi_group=2
hdmi_mode=87
hdmi_cvt=1280 400 60 6 0 0 0
hdmi_drive=2

# I2C Settings
dtparam=i2c_arm=on
dtparam=i2c_arm_baudrate=100000
dtparam=i2c_vc=on
dtparam=i2s=on
dtparam=audio=off

# Audio overlay
dtoverlay=hifiberry-amp100
CONFIGEOF

echo "✅ config.txt rewritten"

echo ""
echo "=== FIX 2: CREATE SIMPLE PERFECT .xinitrc ==="
cat > /tmp/.xinitrc_simple << 'XINITEOF'
#!/bin/bash
export DISPLAY=:0

# Wait for X
for i in {1..30}; do
    xrandr --query >/dev/null 2>&1 && break
    sleep 0.2
done

xhost +SI:localuser:andre 2>/dev/null || true
sleep 1

# Use existing mode if available, or create new one
if xrandr | grep -q "1280x400_60.00"; then
    MODE_NAME="1280x400_60.00"
else
    # Create mode with proper timing
    TIMING=$(cvt 1280 400 60 | grep Modeline | sed 's/Modeline //')
    MODE_NAME=$(echo $TIMING | awk '{print $1}' | tr -d '"')
    xrandr --newmode $TIMING 2>&1 | grep -v "already exists" || true
    xrandr --addmode HDMI-2 "$MODE_NAME" 2>&1 | grep -v "already exists" || true
fi

# Set mode - NO rotation, normal landscape
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

# Fix window after start
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

sudo cp /tmp/.xinitrc_simple /home/andre/.xinitrc
sudo chown andre:andre /home/andre/.xinitrc
sudo chmod +x /home/andre/.xinitrc

echo "✅ Simple .xinitrc created"

echo ""
echo "=== ALL FIXES READY ==="
COMPLETE_FIX

echo ""
echo "=== REBOOTING NOW ==="
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
sleep 35

echo ""
echo "=== FINAL VERIFICATION ==="
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
echo "4. Chromium:"
ps aux | grep chromium | grep -v grep | wc -l | xargs echo "Processes:"

echo ""
echo "5. Window:"
WINDOW=$(xdotool search --class Chromium 2>/dev/null | head -1)
if [ -n "$WINDOW" ]; then
    xdotool getwindowgeometry $WINDOW | grep Geometry
fi

echo ""
echo "6. Config.txt display settings:"
sudo grep -E "display_rotate|framebuffer|hdmi_cvt" /boot/config.txt | head -5
VERIFY

echo ""
echo "=========================================="
echo "FIX COMPLETE - CHECK DISPLAY VISUALLY"
echo "=========================================="

