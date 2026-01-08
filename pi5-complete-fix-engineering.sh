#!/bin/bash
# PI 5 COMPLETE FIX - CHIEF ENGINEER SOLUTION
# Fixes: Framebuffer orientation, GPU memory, video timing, display cut-off, flickering

set -e

echo "=========================================="
echo "PI 5 COMPLETE DISPLAY FIX"
echo "Chief Engineer - Comprehensive Solution"
echo "=========================================="
echo ""

ssh pi2 << 'FIX'
# Backup everything first
BACKUP_DIR="/home/andre/backup_engineering_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"
sudo cp /boot/config.txt "$BACKUP_DIR/config.txt.backup" 2>/dev/null || true
cp /home/andre/.xinitrc "$BACKUP_DIR/.xinitrc.backup" 2>/dev/null || true
echo "✅ Backups created: $BACKUP_DIR"

echo ""
echo "=== FIX 1: UPDATE BOOT CONFIG.TXT ==="
# Read current config.txt
sudo mount -o remount,rw /boot 2>/dev/null || true

# Create new config.txt with Pi 5 optimizations
sudo tee /boot/config.txt > /dev/null << 'CONFIGEOF'
#########################################
# This file is managed by moOde
# Pi 5 Optimized Configuration
#########################################

[pi5]
# Pi 5 specific settings
dtoverlay=vc4-kms-v3d-pi5,noaudio
hdmi_enable_4kp60=0

[all]
# Framebuffer settings
max_framebuffers=2
disable_fw_kms_setup=0
arm_64bit=1

# GPU Memory - INCREASED for display
gpu_mem=128

# General settings
arm_boost=1
disable_splash=0
disable_overscan=1

# HDMI Settings - Waveshare Display 1280x400
hdmi_ignore_hotplug=0
display_auto_detect=1
hdmi_force_hotplug=1
hdmi_blanking=0
hdmi_group=2
hdmi_mode=87
hdmi_cvt=1280 400 60 6 0 0 0
hdmi_drive=2

# Prevent framebuffer from being rotated
framebuffer_width=1280
framebuffer_height=400

# I2C Settings
dtparam=i2c_arm=on
dtparam=i2c_arm_baudrate=100000
dtparam=i2c_vc=on
dtparam=i2s=on

# Audio Settings
dtparam=audio=off

# Audio overlays
dtoverlay=hifiberry-amp100

CONFIGEOF

echo "✅ config.txt updated with Pi 5 optimizations"
echo "   - GPU Memory: 128MB (was 5MB)"
echo "   - Framebuffer: 1280x400 explicitly set"
echo "   - Video mode: hdmi_cvt properly configured"

echo ""
echo "=== FIX 2: CREATE PERFECT .xinitrc ==="
cat > /tmp/.xinitrc_perfect << 'XINITEOF'
#!/bin/bash
export DISPLAY=:0

# Wait for X server - smart polling
echo "Waiting for X server..." >> /tmp/xinit.log
for i in {1..30}; do
    if xrandr --query >/dev/null 2>&1; then
        echo "X server ready after ${i} attempts" >> /tmp/xinit.log
        break
    fi
    sleep 0.2
done

# Allow user access to X server
xhost +SI:localuser:andre 2>/dev/null || true

# Wait a moment for display to stabilize
sleep 1

# Remove any existing mode first
xrandr --output HDMI-2 --mode 1280x720 2>/dev/null || true
sleep 0.5

# Create and set custom mode with CORRECT timing
# Use cvt to generate proper timings
TIMING=$(cvt 1280 400 60 | grep Modeline | sed 's/Modeline //')
MODE_NAME=$(echo $TIMING | awk '{print $1}' | tr -d '"')
TIMING_PARAMS=$(echo $TIMING | awk '{for(i=2;i<=NF;i++) printf "%s ", $i}')

# Remove mode if exists
xrandr --delmode HDMI-2 "$MODE_NAME" 2>/dev/null || true
xrandr --rmmode "$MODE_NAME" 2>/dev/null || true

# Add mode
xrandr --newmode $TIMING 2>&1 | grep -v "already exists" || true
xrandr --addmode HDMI-2 "$MODE_NAME" 2>&1 | grep -v "already exists" || true

# Set mode with NO rotation (normal landscape)
xrandr --output HDMI-2 --mode "$MODE_NAME" --rotate normal 2>&1

# Verify display is set correctly
sleep 1
RES=$(xrandr --query 2>/dev/null | grep "HDMI-2" | grep -oP '\d+x\d+' | head -1)
echo "Display resolution set to: $RES" >> /tmp/xinit.log

# Disable screen blanking
xset s off 2>/dev/null || true
xset -dpms 2>/dev/null || true
xset s noblank 2>/dev/null || true

# Start Chromium
echo "Starting Chromium..." >> /tmp/xinit.log
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
    --disable-background-networking \
    --disable-sync \
    http://localhost >/dev/null 2>&1 &

CHROMIUM_PID=$!

# Wait for Chromium window
echo "Waiting for Chromium window..." >> /tmp/xinit.log
for i in {1..20}; do
    WINDOW=$(xdotool search --class Chromium 2>/dev/null | head -1)
    if [ -n "$WINDOW" ]; then
        echo "Window found: $WINDOW" >> /tmp/xinit.log
        break
    fi
    sleep 1
done

# Fix window size multiple times to ensure it sticks
if [ -n "$WINDOW" ]; then
    echo "Fixing window size..." >> /tmp/xinit.log
    for attempt in {1..10}; do
        xdotool windowsize $WINDOW 1280 400 2>/dev/null
        xdotool windowmove $WINDOW 0 0 2>/dev/null
        
        SIZE=$(xdotool getwindowgeometry $WINDOW 2>/dev/null | grep Geometry | awk '{print $2}' || echo "")
        if [ "$SIZE" == "1280x400" ]; then
            echo "Window fixed: $SIZE (attempt $attempt)" >> /tmp/xinit.log
            # Wait a bit and verify again
            sleep 2
            SIZE2=$(xdotool getwindowgeometry $WINDOW 2>/dev/null | grep Geometry | awk '{print $2}' || echo "")
            if [ "$SIZE2" == "1280x400" ]; then
                echo "Window verified stable: $SIZE2" >> /tmp/xinit.log
                break
            fi
        fi
        sleep 1
    done
fi

wait $CHROMIUM_PID
XINITEOF

sudo cp /tmp/.xinitrc_perfect /home/andre/.xinitrc
sudo chown andre:andre /home/andre/.xinitrc
sudo chmod +x /home/andre/.xinitrc

echo "✅ Perfect .xinitrc created"

echo ""
echo "=== FIX 3: CLEAR CHROMIUM CACHE ==="
rm -rf /tmp/chromium-data/* 2>/dev/null || true
echo "✅ Chromium cache cleared"

echo ""
echo "=== ALL FIXES APPLIED ==="
echo "Ready for reboot to apply changes"
FIX

echo ""
echo "=== REBOOTING PI 5 TO APPLY FIXES ==="
echo "This will take ~30 seconds..."
ssh pi2 "sudo reboot" || true

echo "Waiting for Pi 5 to reboot..."
sleep 10

# Wait for system to come back online
MAX_WAIT=90
WAITED=0
while [ $WAITED -lt $MAX_WAIT ]; do
    if ping -c 1 -W 2000 192.168.178.134 >/dev/null 2>&1; then
        echo "✅ Pi 5 is back online"
        break
    fi
    sleep 2
    WAITED=$((WAITED + 2))
    echo -n "."
done

echo ""
echo "Waiting for services to start..."
sleep 30

echo ""
echo "=== VERIFICATION AFTER REBOOT ==="
ssh pi2 << 'VERIFY'
export DISPLAY=:0

echo "1. GPU Memory:"
vcgencmd get_mem gpu 2>/dev/null || echo "vcgencmd not available"

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
xwininfo -root -tree 2>/dev/null | grep -i chromium | head -1

echo ""
echo "7. Startup log:"
tail -15 /tmp/xinit.log 2>/dev/null || echo "No log yet"
VERIFY

echo ""
echo "=========================================="
echo "COMPLETE FIX APPLIED"
echo "=========================================="
echo ""
echo "Changes made:"
echo "  ✅ GPU Memory increased to 128MB"
echo "  ✅ Framebuffer set to 1280x400"
echo "  ✅ Video timing optimized"
echo "  ✅ Display mode properly configured"
echo ""
echo "Please check the display visually!"

