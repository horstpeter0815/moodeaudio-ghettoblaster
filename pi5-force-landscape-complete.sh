#!/bin/bash
# PI 5 FORCE LANDSCAPE - COMPLETE SOLUTION
# Chief Engineer: Force 1280x400 landscape, fix all issues

set -e

echo "=========================================="
echo "PI 5 FORCE LANDSCAPE - COMPLETE FIX"
echo "Chief Engineer - Final Solution"
echo "=========================================="
echo ""

ssh pi2 << 'FORCEFIX'
BACKUP_DIR="/home/andre/backup_force_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

echo "=== STEP 1: COMPLETE CONFIG.TXT REWRITE FOR LANDSCAPE ==="
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

# Create clean config.txt for Pi 5 Landscape 1280x400
sudo tee "$CONFIG_FILE" > /dev/null << 'CONFIGEOF'
#########################################
# Pi 5 Configuration - 1280x400 Landscape
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

# Display - FORCE LANDSCAPE 1280x400
display_rotate=0
framebuffer_width=1280
framebuffer_height=400

# HDMI - Landscape 1280x400 @ 60Hz
hdmi_ignore_hotplug=0
display_auto_detect=1
hdmi_force_hotplug=1
hdmi_blanking=0
hdmi_group=2
hdmi_mode=87
hdmi_cvt=1280 400 60 6 0 0 0
hdmi_drive=2

# I2C
dtparam=i2c_arm=on
dtparam=i2c_arm_baudrate=100000
dtparam=i2c_vc=on
dtparam=i2s=on
dtparam=audio=off

# Audio
dtoverlay=hifiberry-amp100
CONFIGEOF

echo "✅ config.txt rewritten for Landscape"

echo ""
echo "=== STEP 2: UPDATE CMDLINE FOR LANDSCAPE ==="
# Find cmdline.txt
if [ -f "/boot/firmware/cmdline.txt" ]; then
    CMDLINE_FILE="/boot/firmware/cmdline.txt"
elif [ -f "/boot/cmdline.txt" ]; then
    CMDLINE_FILE="/boot/cmdline.txt"
else
    echo "ERROR: Cannot find cmdline.txt"
    exit 1
fi

sudo cp "$CMDLINE_FILE" "$BACKUP_DIR/cmdline.txt.backup"

# Update cmdline - force 1280x400@60
CURRENT_CMDLINE=$(cat "$CMDLINE_FILE")
NEW_CMDLINE=$(echo "$CURRENT_CMDLINE" | sed 's/video=[^ ]* *//g')
NEW_CMDLINE="$NEW_CMDLINE video=HDMI-A-1:1280x400@60"

echo "$NEW_CMDLINE" | sudo tee "$CMDLINE_FILE" > /dev/null

echo "✅ cmdline.txt updated"

echo ""
echo "=== STEP 3: CREATE PERFECT .xinitrc FOR LANDSCAPE ==="
cat > /tmp/.xinitrc_landscape << 'XINITEOF'
#!/bin/bash
export DISPLAY=:0

# Wait for X
for i in {1..40}; do
    xrandr --query >/dev/null 2>&1 && break
    sleep 0.25
done

xhost +SI:localuser:andre 2>/dev/null || true
sleep 1.5

# Force Landscape 1280x400
echo "Forcing Landscape 1280x400..." >> /tmp/xinit.log

# Remove any portrait modes first
xrandr --output HDMI-2 --mode 1280x720 2>/dev/null || true
sleep 0.5

# Create and set 1280x400 Landscape mode
TIMING=$(cvt 1280 400 60 | grep Modeline | sed 's/Modeline //')
MODE_NAME=$(echo $TIMING | awk '{print $1}' | tr -d '"')

# Clean up old mode
xrandr --delmode HDMI-2 "$MODE_NAME" 2>/dev/null || true
xrandr --rmmode "$MODE_NAME" 2>/dev/null || true

# Add mode
xrandr --newmode $TIMING 2>&1 | grep -v "already exists" || true
xrandr --addmode HDMI-2 "$MODE_NAME" 2>&1 | grep -v "already exists" || true

# Set mode - NORMAL (Landscape)
xrandr --output HDMI-2 --mode "$MODE_NAME" --rotate normal 2>&1

# Verify
sleep 1
RES=$(xrandr --query 2>/dev/null | grep "HDMI-2" | grep -oP '\d+x\d+' | head -1)
echo "Display set to: $RES" >> /tmp/xinit.log

# Disable blanking
xset s off 2>/dev/null || true
xset -dpms 2>/dev/null || true
xset s noblank 2>/dev/null || true

# Start Chromium - Landscape window
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

# Fix window - MUST be 1280x400
sleep 10
for i in {1..15}; do
    WINDOW=$(xdotool search --class Chromium --name "Player" 2>/dev/null | head -1)
    if [ -z "$WINDOW" ]; then
        WINDOW=$(xdotool search --class Chromium 2>/dev/null | head -1)
    fi
    
    if [ -n "$WINDOW" ]; then
        # Force 1280x400
        xdotool windowsize $WINDOW 1280 400 2>/dev/null
        xdotool windowmove $WINDOW 0 0 2>/dev/null
        
        SIZE=$(xdotool getwindowgeometry $WINDOW 2>/dev/null | grep Geometry | awk '{print $2}' || echo "")
        if [ "$SIZE" == "1280x400" ]; then
            echo "Window fixed: $SIZE" >> /tmp/xinit.log
            # Verify multiple times
            sleep 2
            SIZE2=$(xdotool getwindowgeometry $WINDOW 2>/dev/null | grep Geometry | awk '{print $2}' || echo "")
            if [ "$SIZE2" == "1280x400" ]; then
                echo "Window stable: $SIZE2" >> /tmp/xinit.log
                break
            fi
        fi
    fi
    sleep 1
done

wait
XINITEOF

sudo cp /tmp/.xinitrc_landscape /home/andre/.xinitrc
sudo chown andre:andre /home/andre/.xinitrc
sudo chmod +x /home/andre/.xinitrc

echo "✅ Landscape .xinitrc created"

echo ""
echo "=== READY FOR REBOOT ==="
FORCEFIX

echo ""
echo "=== REBOOTING ==="
ssh pi2 "sudo reboot" || true

echo "Waiting for reboot..."
sleep 10

MAX_WAIT=100
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
echo "Waiting for full service initialization..."
sleep 45

echo ""
echo "=== COMPREHENSIVE VERIFICATION ==="
ssh pi2 << 'VERIFY'
export DISPLAY=:0

echo "=== FULL STATUS CHECK ==="
echo ""
echo "1. Framebuffer (hardware level):"
cat /sys/class/graphics/fb0/virtual_size 2>/dev/null || echo "Cannot read"

echo ""
echo "2. Display (X11 level):"
xrandr --query | grep "HDMI-2 connected"

echo ""
echo "3. Resolution:"
xrandr --query | grep "HDMI-2" | grep -oP '\d+x\d+' | head -1

echo ""
echo "4. Rotation:"
xrandr --query | grep "HDMI-2" | grep -E "normal|left|right|inverted"

echo ""
echo "5. Chromium processes:"
ps aux | grep chromium | grep -v grep | wc -l

echo ""
echo "6. Chromium window:"
xwininfo -root -tree 2>/dev/null | grep -i chromium | head -3

echo ""
echo "7. Window geometry:"
WINDOW=$(xdotool search --class Chromium 2>/dev/null | head -1)
if [ -n "$WINDOW" ]; then
    xdotool getwindowgeometry $WINDOW
fi

echo ""
echo "8. Startup log:"
cat /tmp/xinit.log 2>/dev/null | tail -10 || echo "No log"

echo ""
echo "9. Config.txt settings:"
sudo grep -E "display_rotate|framebuffer|hdmi_cvt" /boot/config.txt | head -5

echo ""
echo "10. Video parameter:"
cat /proc/cmdline | grep -o 'video=[^ ]*' || echo "Not found"
VERIFY

echo ""
echo "=========================================="
echo "COMPLETE FIX APPLIED - CHECK VISUALLY"
echo "=========================================="
echo ""
echo "Expected:"
echo "  - Display: 1280x400 Landscape"
echo "  - No flickering"
echo "  - No black noise"
echo "  - Stable, clear picture"
echo ""
echo "If still wrong, check framebuffer vs X11 mismatch"

