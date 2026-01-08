#!/bin/bash
# PI 5 DIRECT FIX - Network cable connected
# Apply fix immediately

set -e

echo "=========================================="
echo "PI 5 DIRECT FIX - NETWORK CABLE CONNECTED"
echo "Applying fix immediately"
echo "=========================================="
echo "Date: $(date)"
echo ""

# Try multiple connection methods
PI5_ACCESSIBLE=false

echo "=== TRYING TO CONNECT ==="
for method in "pi2" "pi2@192.168.178.134" "andre@192.168.178.134"; do
    echo "Trying: $method"
    if ssh -o ConnectTimeout=5 $method "uptime" >/dev/null 2>&1; then
        echo "✅ Connected via: $method"
        PI5_HOST=$method
        PI5_ACCESSIBLE=true
        break
    fi
done

if [ "$PI5_ACCESSIBLE" = false ]; then
    echo ""
    echo "⚠️ Cannot connect via SSH"
    echo "Network check:"
    ping -c 3 192.168.178.134
    echo ""
    echo "Please check:"
    echo "  - SSH service running on Pi 5?"
    echo "  - Firewall blocking?"
    echo "  - Network configuration?"
    exit 1
fi

echo ""
echo "=== APPLYING COMPREHENSIVE FIX ==="
ssh $PI5_HOST << 'APPLYFIX'
BACKUP_DIR="/home/andre/backup_direct_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

export DISPLAY=:0 2>/dev/null || true

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

echo "=== FIXING CONFIG.TXT ==="
# Remove old settings
sudo sed -i '/^display_rotate=/d' "$CONFIG_FILE"
sudo sed -i '/display_rotate=/d' "$CONFIG_FILE"
sudo sed -i '/^hdmi_group=/d' "$CONFIG_FILE"
sudo sed -i '/hdmi_group=/d' "$CONFIG_FILE"
sudo sed -i '/^hdmi_cvt=/d' "$CONFIG_FILE"
sudo sed -i '/hdmi_cvt /d' "$CONFIG_FILE"

# Add correct settings
echo "display_rotate=3" | sudo tee -a "$CONFIG_FILE" > /dev/null
echo "hdmi_group=0" | sudo tee -a "$CONFIG_FILE" > /dev/null
echo "✅ Config.txt fixed"

echo ""
echo "=== FIXING .xinitrc ==="
cat > /tmp/.xinitrc_fix << 'XINITEOF'
#!/bin/bash
export DISPLAY=:0

for i in {1..40}; do
    xrandr --query >/dev/null 2>&1 && break
    sleep 0.25
done

xhost +SI:localuser:andre 2>/dev/null || true
sleep 2

# Portrait mode - rotated to Landscape by display_rotate=3
if xrandr | grep -q "400x1280"; then
    xrandr --output HDMI-2 --mode 400x1280 --rotate normal 2>&1
else
    TIMING=$(cvt 400 1280 60 | grep Modeline | sed 's/Modeline //')
    MODE_NAME=$(echo $TIMING | awk '{print $1}' | tr -d '"')
    xrandr --newmode $TIMING 2>&1 | grep -v "already exists" || true
    xrandr --addmode HDMI-2 "$MODE_NAME" 2>&1 | grep -v "already exists" || true
    xrandr --output HDMI-2 --mode "$MODE_NAME" --rotate normal 2>&1
fi

xset s off 2>/dev/null || true
xset -dpms 2>/dev/null || true
xset s noblank 2>/dev/null || true
setterm -blank 0 -powerdown 0 2>/dev/null || true

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
    http://localhost >/dev/null 2>&1 &

sleep 12

for i in {1..20}; do
    WINDOW=$(xdotool search --class Chromium 2>/dev/null | head -1)
    if [ -n "$WINDOW" ]; then
        xdotool windowsize $WINDOW 400 1280 2>/dev/null
        xdotool windowmove $WINDOW 0 0 2>/dev/null
        break
    fi
    sleep 1
done

wait
XINITEOF

sudo cp /tmp/.xinitrc_fix /home/andre/.xinitrc
sudo chown andre:andre /home/andre/.xinitrc
sudo chmod +x /home/andre/.xinitrc
echo "✅ .xinitrc fixed"

echo ""
echo "=== PREVENTING SLEEP ==="
sudo systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target 2>/dev/null || true
echo "✅ Sleep prevented"

echo ""
echo "=== RESTARTING DISPLAY SERVICE ==="
sudo systemctl restart localdisplay
echo "✅ Display service restarted"
APPLYFIX

echo ""
echo "Waiting for display to initialize..."
sleep 20

echo ""
echo "=== VERIFICATION ==="
ssh $PI5_HOST << 'VERIFY'
export DISPLAY=:0

echo "1. Config:"
if [ -f "/boot/firmware/config.txt" ]; then
    CONFIG_FILE="/boot/firmware/config.txt"
else
    CONFIG_FILE="/boot/config.txt"
fi
sudo grep -E "display_rotate|hdmi_group" "$CONFIG_FILE" | grep -v "^#"

echo ""
echo "2. Display:"
xrandr --query | grep "HDMI-2 connected"

echo ""
echo "3. Resolution:"
xrandr --query | grep "HDMI-2" | grep -oP '\d+x\d+' | head -1

echo ""
echo "4. Chromium:"
ps aux | grep chromium | grep -v grep | wc -l | xargs echo "Processes:"
VERIFY

echo ""
echo "=========================================="
echo "FIX APPLIED - CHECK DISPLAY!"
echo "=========================================="

