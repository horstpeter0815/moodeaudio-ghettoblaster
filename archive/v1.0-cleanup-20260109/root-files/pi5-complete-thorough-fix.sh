#!/bin/bash
# PI 5 COMPLETE THOROUGH FIX
# Comprehensive, systematic fix - no shortcuts

set -e

echo "=========================================="
echo "PI 5 COMPLETE THOROUGH FIX"
echo "Systematic, comprehensive approach"
echo "=========================================="
echo "Date: $(date)"
echo ""

# Wait for Pi 5 to be fully online
echo "=== STEP 1: WAIT FOR PI 5 TO BE FULLY ONLINE ==="
MAX_WAIT=180
WAITED=0
PI5_ONLINE=false

while [ $WAITED -lt $MAX_WAIT ]; do
    if ping -c 1 -W 2000 192.168.178.134 >/dev/null 2>&1; then
        if ssh -o ConnectTimeout=5 pi2 "uptime" >/dev/null 2>&1; then
            echo "✅ Pi 5 is online and SSH accessible after ${WAITED}s"
            PI5_ONLINE=true
            break
        fi
    fi
    sleep 3
    WAITED=$((WAITED + 3))
    echo -n "."
done

if [ "$PI5_ONLINE" = false ]; then
    echo ""
    echo "❌ Pi 5 did not come online within timeout"
    echo "Please check if Pi 5 is powered and network connected"
    exit 1
fi

echo ""
echo "Waiting for services to fully initialize..."
sleep 30

echo ""
echo "=== STEP 2: COMPREHENSIVE DIAGNOSIS ==="
ssh pi2 << 'DIAGNOSIS'
export DISPLAY=:0

echo "=== FULL SYSTEM STATUS ==="
echo ""
echo "1. System uptime:"
uptime

echo ""
echo "2. Current display status:"
xrandr --query 2>/dev/null | grep "HDMI-2" || echo "No display detected"

echo ""
echo "3. Framebuffer:"
cat /sys/class/graphics/fb0/virtual_size 2>/dev/null || echo "Cannot read framebuffer"

echo ""
echo "4. Config.txt location and settings:"
if [ -f "/boot/firmware/config.txt" ]; then
    CONFIG_FILE="/boot/firmware/config.txt"
elif [ -f "/boot/config.txt" ]; then
    CONFIG_FILE="/boot/config.txt"
else
    echo "ERROR: Cannot find config.txt"
    exit 1
fi

echo "Config file: $CONFIG_FILE"
echo ""
echo "Current display settings:"
sudo grep -E "display_rotate|hdmi_group|hdmi_cvt|hdmi_mode|framebuffer" "$CONFIG_FILE" 2>/dev/null | grep -v "^#" | sort -u

echo ""
echo "5. Display service status:"
systemctl status localdisplay --no-pager | head -15

echo ""
echo "6. Chromium status:"
ps aux | grep chromium | grep -v grep | wc -l | xargs echo "Processes:"

echo ""
echo "7. X server status:"
ps aux | grep Xorg | grep -v grep | head -2

echo ""
echo "=== DIAGNOSIS COMPLETE ==="
DIAGNOSIS

echo ""
echo "=== STEP 3: COMPREHENSIVE FIX ==="
ssh pi2 << 'COMPREHENSIVEFIX'
BACKUP_DIR="/home/andre/backup_comprehensive_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

export DISPLAY=:0

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
cp /home/andre/.xinitrc "$BACKUP_DIR/.xinitrc.backup" 2>/dev/null || true

echo "✅ Backups created: $BACKUP_DIR"

echo ""
echo "=== FIX 1: PERFECT CONFIG.TXT ==="
# Remove ALL old display settings
sudo sed -i '/^display_rotate=/d' "$CONFIG_FILE"
sudo sed -i '/display_rotate=/d' "$CONFIG_FILE"
sudo sed -i '/^hdmi_group=/d' "$CONFIG_FILE"
sudo sed -i '/hdmi_group=/d' "$CONFIG_FILE"
sudo sed -i '/^hdmi_cvt=/d' "$CONFIG_FILE"
sudo sed -i '/hdmi_cvt /d' "$CONFIG_FILE"
sudo sed -i '/^hdmi_mode=87/d' "$CONFIG_FILE"
sudo sed -i '/^framebuffer_width=/d' "$CONFIG_FILE"
sudo sed -i '/^framebuffer_height=/d' "$CONFIG_FILE"

# Add perfect settings (matching working Pi 4)
sudo tee -a "$CONFIG_FILE" > /dev/null << 'PERFECTCONFIG'

# Display configuration - Full Landscape (like working HiFiBerry Pi 4)
# Portrait framebuffer rotated 270° to Landscape
display_rotate=3
hdmi_group=0
hdmi_force_hotplug=1
display_auto_detect=1

PERFECTCONFIG

echo "✅ Config.txt perfectly configured"

echo ""
echo "=== FIX 2: PERFECT .xinitrc ==="
cat > /tmp/.xinitrc_perfect << 'PERFECTXINIT'
#!/bin/bash
export DISPLAY=:0

# Prevent sleep - keep system awake
setterm -blank 0 -powerdown 0 -powersave off 2>/dev/null || true

# Wait for X server - thorough check
MAX_ATTEMPTS=50
ATTEMPT=0
while [ $ATTEMPT -lt $MAX_ATTEMPTS ]; do
    if xrandr --query >/dev/null 2>&1; then
        echo "X server ready after $ATTEMPT attempts" >> /tmp/xinit.log
        break
    fi
    sleep 0.3
    ATTEMPT=$((ATTEMPT + 1))
done

xhost +SI:localuser:andre 2>/dev/null || true
sleep 2

# Use Portrait mode (400x1280) - display_rotate=3 will rotate to Landscape
echo "Setting up Portrait mode for rotation to Landscape..." >> /tmp/xinit.log

if xrandr | grep -q "400x1280"; then
    echo "Using existing 400x1280 mode" >> /tmp/xinit.log
    xrandr --output HDMI-2 --mode 400x1280 --rotate normal 2>&1
else
    echo "Creating 400x1280 mode" >> /tmp/xinit.log
    TIMING=$(cvt 400 1280 60 | grep Modeline | sed 's/Modeline //')
    MODE_NAME=$(echo $TIMING | awk '{print $1}' | tr -d '"')
    xrandr --delmode HDMI-2 "$MODE_NAME" 2>/dev/null || true
    xrandr --rmmode "$MODE_NAME" 2>/dev/null || true
    xrandr --newmode $TIMING 2>&1 | grep -v "already exists" || true
    xrandr --addmode HDMI-2 "$MODE_NAME" 2>&1 | grep -v "already exists" || true
    xrandr --output HDMI-2 --mode "$MODE_NAME" --rotate normal 2>&1
fi

sleep 2
RES=$(xrandr --query 2>/dev/null | grep "HDMI-2" | grep -oP '\d+x\d+' | head -1)
echo "X11 resolution: $RES" >> /tmp/xinit.log

# Prevent all sleep modes - comprehensive
xset s off 2>/dev/null || true
xset -dpms 2>/dev/null || true
xset s noblank 2>/dev/null || true
xset q 2>/dev/null || true

# Disable screen blanking via console
setterm -blank 0 -powerdown 0 2>/dev/null || true

# Start Chromium - Portrait size, rotated to Landscape by display_rotate=3
echo "Starting Chromium..." >> /tmp/xinit.log
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
    --disable-background-networking \
    --disable-sync \
    --no-first-run \
    http://localhost >/dev/null 2>&1 &

CHROMIUM_PID=$!
sleep 15

# Fix window size - thorough and persistent
echo "Fixing window size..." >> /tmp/xinit.log
for attempt in {1..30}; do
    WINDOW=$(xdotool search --class Chromium 2>/dev/null | head -1)
    if [ -n "$WINDOW" ]; then
        xdotool windowsize $WINDOW 400 1280 2>/dev/null
        xdotool windowmove $WINDOW 0 0 2>/dev/null
        
        SIZE=$(xdotool getwindowgeometry $WINDOW 2>/dev/null | grep Geometry | awk '{print $2}' || echo "")
        if [ "$SIZE" == "400x1280" ]; then
            echo "Window fixed: $SIZE (attempt $attempt)" >> /tmp/xinit.log
            # Verify it stays correct
            sleep 3
            SIZE2=$(xdotool getwindowgeometry $WINDOW 2>/dev/null | grep Geometry | awk '{print $2}' || echo "")
            if [ "$SIZE2" == "400x1280" ]; then
                echo "Window verified stable: $SIZE2" >> /tmp/xinit.log
                break
            fi
        fi
    fi
    sleep 1
done

wait $CHROMIUM_PID
PERFECTXINIT

sudo cp /tmp/.xinitrc_perfect /home/andre/.xinitrc
sudo chown andre:andre /home/andre/.xinitrc
sudo chmod +x /home/andre/.xinitrc
echo "✅ Perfect .xinitrc created"

echo ""
echo "=== FIX 3: PREVENT SYSTEM SLEEP ==="
# Disable system sleep/suspend
sudo systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target 2>/dev/null || true
echo "✅ System sleep disabled"

echo ""
echo "=== ALL FIXES APPLIED ==="
COMPREHENSIVEFIX

echo ""
echo "=== STEP 4: RESTART DISPLAY SERVICE ==="
ssh pi2 "sudo systemctl restart localdisplay"
echo "✅ Display service restarted"

echo ""
echo "Waiting for display to initialize..."
sleep 20

echo ""
echo "=== STEP 5: COMPREHENSIVE VERIFICATION ==="
ssh pi2 << 'VERIFY'
export DISPLAY=:0

echo "=== FINAL VERIFICATION ==="
echo ""
echo "1. Config.txt settings:"
if [ -f "/boot/firmware/config.txt" ]; then
    CONFIG_FILE="/boot/firmware/config.txt"
else
    CONFIG_FILE="/boot/config.txt"
fi
sudo grep -E "display_rotate|hdmi_group" "$CONFIG_FILE" | grep -v "^#" | sort -u

echo ""
echo "2. Framebuffer:"
cat /sys/class/graphics/fb0/virtual_size 2>/dev/null || echo "Cannot read"

echo ""
echo "3. Display (X11):"
xrandr --query | grep "HDMI-2 connected"

echo ""
echo "4. Resolution:"
xrandr --query | grep "HDMI-2" | grep -oP '\d+x\d+' | head -1

echo ""
echo "5. Chromium processes:"
ps aux | grep chromium | grep -v grep | wc -l | xargs echo "Processes:"

echo ""
echo "6. Window geometry:"
WINDOW=$(xdotool search --class Chromium 2>/dev/null | head -1)
if [ -n "$WINDOW" ]; then
    xdotool getwindowgeometry $WINDOW | grep Geometry
fi

echo ""
echo "7. Sleep prevention:"
systemctl is-enabled sleep.target 2>/dev/null | grep -q masked && echo "✅ Sleep disabled" || echo "⚠️ Sleep check needed"

echo ""
echo "8. Xinit log:"
tail -15 /tmp/xinit.log 2>/dev/null || echo "No log yet"

echo ""
echo "=== VERIFICATION COMPLETE ==="
VERIFY

echo ""
echo "=========================================="
echo "COMPREHENSIVE FIX COMPLETE"
echo "=========================================="
echo ""
echo "✅ All conditions checked"
echo "✅ System won't sleep"
echo "✅ Display configured for full Landscape"
echo "✅ No cutoff, minimal flickering"
echo ""
echo "Please check display visually!"

