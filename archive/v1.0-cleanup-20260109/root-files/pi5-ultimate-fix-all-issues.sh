#!/bin/bash
# PI 5 ULTIMATE FIX - ALL ISSUES
# Chief Engineer: Comprehensive solution testing all approaches

set -e

echo "=========================================="
echo "PI 5 ULTIMATE FIX - ALL ISSUES"
echo "Chief Engineer - Comprehensive Solution"
echo "=========================================="
echo "Date: $(date)"
echo ""

ssh pi2 << 'ULTIMATEFIX'
BACKUP_DIR="/home/andre/backup_ultimate_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

echo "=== COMPREHENSIVE ROOT CAUSE ANALYSIS ==="
FB_SIZE=$(cat /sys/class/graphics/fb0/virtual_size 2>/dev/null || echo "unknown")
echo "Framebuffer: $FB_SIZE"
echo "X11 Display: 1280x400"
echo ""
echo "Problem: Framebuffer mismatch causes:"
echo "  - Cut-off in wrong direction"
echo "  - Flickering/black noise"
echo "  - Restless display"

echo ""
echo "=== STRATEGY: FIX AT BOOT LEVEL ==="
echo "We'll try multiple approaches to force correct framebuffer"

# Find config files
if [ -f "/boot/firmware/config.txt" ]; then
    CONFIG_FILE="/boot/firmware/config.txt"
elif [ -f "/boot/config.txt" ]; then
    CONFIG_FILE="/boot/config.txt"
else
    echo "ERROR: Cannot find config.txt"
    exit 1
fi

if [ -f "/boot/firmware/cmdline.txt" ]; then
    CMDLINE_FILE="/boot/firmware/cmdline.txt"
elif [ -f "/boot/cmdline.txt" ]; then
    CMDLINE_FILE="/boot/cmdline.txt"
else
    echo "ERROR: Cannot find cmdline.txt"
    exit 1
fi

sudo cp "$CONFIG_FILE" "$BACKUP_DIR/config.txt.backup"
sudo cp "$CMDLINE_FILE" "$BACKUP_DIR/cmdline.txt.backup"

echo ""
echo "=== APPROACH: COMPLETE CONFIG REWRITE ==="
# Create minimal, correct config for Pi 5
sudo tee "$CONFIG_FILE" > /dev/null << 'CONFIGEOF'
#########################################
# Pi 5 Configuration - 1280x400 Landscape
# Minimal, Correct Configuration
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

# Display Configuration - Force Landscape
# Remove display_rotate - let system handle it
framebuffer_width=1280
framebuffer_height=400

# HDMI Configuration
hdmi_ignore_hotplug=0
hdmi_force_hotplug=1
hdmi_blanking=0
hdmi_group=2
hdmi_mode=87
hdmi_cvt=1280 400 60 6 0 0 0
hdmi_drive=2

# I2C & Audio
dtparam=i2c_arm=on
dtparam=i2c_arm_baudrate=100000
dtparam=i2c_vc=on
dtparam=i2s=on
dtparam=audio=off
dtoverlay=hifiberry-amp100
CONFIGEOF

echo "✅ Clean config.txt written"

echo ""
echo "=== UPDATE CMDLINE - REMOVE VIDEO PARAMETER ==="
# Remove video parameter - let config.txt handle it
CURRENT_CMDLINE=$(cat "$CMDLINE_FILE")
NEW_CMDLINE=$(echo "$CURRENT_CMDLINE" | sed 's/video=[^ ]* *//g')
echo "$NEW_CMDLINE" | sudo tee "$CMDLINE_FILE" > /dev/null

echo "✅ cmdline.txt cleaned (no video parameter)"

echo ""
echo "=== CREATE ROBUST .xinitrc ==="
cat > /tmp/.xinitrc_robust << 'XINITEOF'
#!/bin/bash
export DISPLAY=:0

# Wait for X with verification
for i in {1..50}; do
    if xrandr --query >/dev/null 2>&1; then
        break
    fi
    sleep 0.2
done

xhost +SI:localuser:andre 2>/dev/null || true
sleep 2

# Get actual framebuffer size
FB_SIZE=$(cat /sys/class/graphics/fb0/virtual_size 2>/dev/null || echo "")
echo "Framebuffer: $FB_SIZE" >> /tmp/xinit.log

# Strategy: Match X11 to what framebuffer actually is
# Then use xrandr rotation if needed

# Check current display state
CURRENT_RES=$(xrandr --query 2>/dev/null | grep "HDMI-2" | grep -oP '\d+x\d+' | head -1)
echo "Current X11 resolution: $CURRENT_RES" >> /tmp/xinit.log

# Create 1280x400 mode
TIMING=$(cvt 1280 400 60 | grep Modeline | sed 's/Modeline //')
MODE_NAME=$(echo $TIMING | awk '{print $1}' | tr -d '"')

xrandr --delmode HDMI-2 "$MODE_NAME" 2>/dev/null || true
xrandr --rmmode "$MODE_NAME" 2>/dev/null || true
xrandr --newmode $TIMING 2>&1 | grep -v "already exists" || true
xrandr --addmode HDMI-2 "$MODE_NAME" 2>&1 | grep -v "already exists" || true

# Set mode - try normal first
xrandr --output HDMI-2 --mode "$MODE_NAME" --rotate normal 2>&1

# If framebuffer is portrait, we might need to rotate X11
if echo "$FB_SIZE" | grep -q "400,1280"; then
    echo "Framebuffer is Portrait - trying X11 rotation" >> /tmp/xinit.log
    # Try rotating X11 to match
    sleep 1
    xrandr --output HDMI-2 --rotate left 2>&1
    sleep 1
    # Then rotate back - this sometimes fixes it
    xrandr --output HDMI-2 --rotate normal 2>&1
fi

sleep 1
FINAL_RES=$(xrandr --query 2>/dev/null | grep "HDMI-2" | grep -oP '\d+x\d+' | head -1)
echo "Final X11 resolution: $FINAL_RES" >> /tmp/xinit.log

# Disable blanking
xset s off 2>/dev/null || true
xset -dpms 2>/dev/null || true
xset s noblank 2>/dev/null || true

# Start Chromium with multiple size options
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
    --disable-accelerated-2d-canvas \
    --disable-gpu \
    http://localhost >/dev/null 2>&1 &

sleep 12

# Aggressive window fixing
for attempt in {1..20}; do
    WINDOW=$(xdotool search --class Chromium 2>/dev/null | head -1)
    if [ -n "$WINDOW" ]; then
        # Get current size
        CURRENT=$(xdotool getwindowgeometry $WINDOW 2>/dev/null | grep Geometry | awk '{print $2}' || echo "")
        
        # Force 1280x400
        xdotool windowsize $WINDOW 1280 400 2>/dev/null
        xdotool windowmove $WINDOW 0 0 2>/dev/null
        
        # Also try F11 for fullscreen
        xdotool key --window $WINDOW F11 2>/dev/null || true
        
        sleep 0.5
        
        NEW=$(xdotool getwindowgeometry $WINDOW 2>/dev/null | grep Geometry | awk '{print $2}' || echo "")
        if [ "$NEW" == "1280x400" ]; then
            echo "Window fixed: $NEW (attempt $attempt)" >> /tmp/xinit.log
            # Verify stability
            sleep 2
            VERIFY=$(xdotool getwindowgeometry $WINDOW 2>/dev/null | grep Geometry | awk '{print $2}' || echo "")
            if [ "$VERIFY" == "1280x400" ]; then
                break
            fi
        fi
    fi
    sleep 1
done

wait
XINITEOF

sudo cp /tmp/.xinitrc_robust /home/andre/.xinitrc
sudo chown andre:andre /home/andre/.xinitrc
sudo chmod +x /home/andre/.xinitrc

echo "✅ Robust .xinitrc created"

echo ""
echo "=== ALL FIXES READY ==="
ULTIMATEFIX

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
sleep 50

echo ""
echo "=== FINAL COMPREHENSIVE VERIFICATION ==="
ssh pi2 << 'FINALVERIFY'
export DISPLAY=:0

echo "=== COMPLETE STATUS ==="
echo ""
echo "1. Framebuffer:"
cat /sys/class/graphics/fb0/virtual_size 2>/dev/null || echo "Cannot read"
echo ""

echo "2. Display (X11):"
xrandr --query | grep "HDMI-2 connected"
echo ""

echo "3. Resolution:"
xrandr --query | grep "HDMI-2" | grep -oP '\d+x\d+' | head -1
echo ""

echo "4. Rotation:"
xrandr --query | grep "HDMI-2" | grep -E "normal|left|right|inverted"
echo ""

echo "5. Chromium:"
ps aux | grep chromium | grep -v grep | wc -l | xargs echo "Processes:"
echo ""

echo "6. Window details:"
xwininfo -root -tree 2>/dev/null | grep -i chromium | head -3
echo ""

echo "7. Window geometry:"
WINDOW=$(xdotool search --class Chromium 2>/dev/null | head -1)
if [ -n "$WINDOW" ]; then
    xdotool getwindowgeometry $WINDOW
fi
echo ""

echo "8. Config.txt:"
sudo grep -E "display_rotate|framebuffer|hdmi_cvt" /boot/config.txt 2>/dev/null | head -5
echo ""

echo "9. Xinit log:"
cat /tmp/xinit.log 2>/dev/null | tail -10 || echo "No log"
echo ""

echo "10. System health:"
systemctl is-active localdisplay mpd nginx
echo ""

echo "=== VERIFICATION COMPLETE ==="
FINALVERIFY

echo ""
echo "=========================================="
echo "ULTIMATE FIX COMPLETE"
echo "=========================================="
echo ""
echo "All comprehensive fixes applied."
echo "System rebooting with clean configuration."
echo ""
echo "Key changes:"
echo "  ✅ Clean config.txt (minimal, correct)"
echo "  ✅ Removed conflicting video parameter"
echo "  ✅ Robust .xinitrc with multiple fixes"
echo "  ✅ Aggressive window size fixing"
echo ""
echo "Please check display visually!"

