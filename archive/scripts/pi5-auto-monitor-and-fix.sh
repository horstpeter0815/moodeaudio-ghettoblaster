#!/bin/bash
# AUTOMATIC PI 5 MONITORING AND FIXING
# Runs continuously, automatically fixes when Pi 5 comes online
# No more manual waiting!

set -e

PI5_IP="192.168.178.134"
PI5_ALIAS="pi2"
LOG_FILE="pi5-auto-work-$(date +%Y%m%d_%H%M%S).log"

echo "=========================================="
echo "PI 5 AUTOMATIC MONITORING & FIXING"
echo "=========================================="
echo "This script runs continuously"
echo "It will automatically work when Pi 5 is online"
echo "Log: $LOG_FILE"
echo ""
echo "Press Ctrl+C to stop"
echo "=========================================="
echo ""

# Function to check if Pi 5 is online
check_pi5_online() {
    ping -c 1 -W 1000 "$PI5_IP" >/dev/null 2>&1 && \
    ssh -o ConnectTimeout=3 "$PI5_ALIAS" "echo 'online'" >/dev/null 2>&1
}

# Function to apply fixes
apply_fixes() {
    echo "[$(date +%H:%M:%S)] Pi 5 is online - applying fixes..." | tee -a "$LOG_FILE"
    
    ssh "$PI5_ALIAS" << 'APPLYFIXES' 2>&1 | tee -a "$LOG_FILE"
export DISPLAY=:0

echo "=== COMPLETE SYSTEM CHECK AND FIX ==="
echo ""

# 1. Ensure Landscape
echo "1. Checking Landscape configuration..."
for CONFIG_FILE in "/boot/config.txt" "/boot/firmware/config.txt"; do
    if [ -f "$CONFIG_FILE" ]; then
        if ! grep -q "^display_rotate=1" "$CONFIG_FILE" 2>/dev/null; then
            sudo sed -i '/^display_rotate=/d' "$CONFIG_FILE"
            echo "display_rotate=1" | sudo tee -a "$CONFIG_FILE" > /dev/null
            echo "✅ Fixed: $CONFIG_FILE (set display_rotate=1)"
        fi
        if ! grep -q "^hdmi_group=0" "$CONFIG_FILE" 2>/dev/null; then
            sudo sed -i '/^hdmi_group=/d' "$CONFIG_FILE"
            echo "hdmi_group=0" | sudo tee -a "$CONFIG_FILE" > /dev/null
            echo "✅ Fixed: $CONFIG_FILE (set hdmi_group=0)"
        fi
    fi
done

# 2. Ensure Boot Prompts are visible
echo ""
echo "2. Checking Boot Prompts..."
for CMDLINE in "/boot/cmdline.txt" "/boot/firmware/cmdline.txt"; do
    if [ -f "$CMDLINE" ]; then
        if grep -q " quiet" "$CMDLINE" 2>/dev/null || grep -q "quiet " "$CMDLINE" 2>/dev/null; then
            sudo sed -i 's/ quiet//g' "$CMDLINE"
            sudo sed -i 's/quiet //g' "$CMDLINE"
            echo "✅ Removed 'quiet' from $CMDLINE"
        fi
        if ! grep -q "systemd.show_status" "$CMDLINE" 2>/dev/null; then
            sudo sed -i 's/$/ systemd.show_status=yes/' "$CMDLINE"
            echo "✅ Added systemd.show_status=yes to $CMDLINE"
        fi
    fi
done

# 3. Ensure .xinitrc is correct for Landscape
echo ""
echo "3. Checking .xinitrc..."
if [ ! -f "/home/andre/.xinitrc" ] || ! grep -q "1280x400\|400x1280.*rotate" /home/andre/.xinitrc 2>/dev/null; then
    cat > /tmp/.xinitrc_landscape << 'XINITEOF'
#!/bin/bash
export DISPLAY=:0

# Wait for X
for i in {1..40}; do
    xrandr --query >/dev/null 2>&1 && break
    sleep 0.25
done

xhost +SI:localuser:andre 2>/dev/null || true
sleep 2

# Set Landscape
if xrandr | grep -q "400x1280"; then
    xrandr --output HDMI-2 --mode 400x1280 --rotate left 2>&1
elif xrandr | grep -q "1280x400"; then
    xrandr --output HDMI-2 --mode 1280x400 --rotate normal 2>&1
fi

xset s off 2>/dev/null || true
xset -dpms 2>/dev/null || true
xset s noblank 2>/dev/null || true

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
    --disable-gpu \
    http://localhost >/dev/null 2>&1 &

sleep 12
for i in {1..20}; do
    WINDOW=$(xdotool search --class Chromium 2>/dev/null | head -1)
    if [ -n "$WINDOW" ]; then
        xdotool windowsize $WINDOW 1280 400 2>/dev/null
        xdotool windowmove $WINDOW 0 0 2>/dev/null
        break
    fi
    sleep 1
done

wait
XINITEOF
    sudo cp /tmp/.xinitrc_landscape /home/andre/.xinitrc
    sudo chown andre:andre /home/andre/.xinitrc
    sudo chmod +x /home/andre/.xinitrc
    echo "✅ .xinitrc updated for Landscape"
fi

# 4. Ensure services are running
echo ""
echo "4. Checking Services..."
if ! systemctl is-active --quiet localdisplay.service; then
    echo "⚠️  localdisplay not active - restarting..."
    sudo systemctl restart localdisplay.service
    sleep 5
fi

if ! pgrep -f chromium >/dev/null; then
    echo "⚠️  Chromium not running - restarting display service..."
    sudo systemctl restart localdisplay.service
    sleep 5
fi

# 5. Final Status
echo ""
echo "=== FINAL STATUS ==="
echo "Display rotate: $(sudo grep 'display_rotate=1' /boot/config.txt /boot/firmware/config.txt 2>/dev/null | grep -v '^#' | head -1 | cut -d: -f2 || echo 'not set')"
echo "Boot prompts: $(grep -q 'quiet' /boot/cmdline.txt /boot/firmware/cmdline.txt 2>/dev/null && echo 'hidden' || echo 'visible')"
echo "localdisplay: $(systemctl is-active localdisplay.service 2>/dev/null || echo 'inactive')"
echo "Chromium: $(pgrep -f chromium >/dev/null && echo 'running' || echo 'not running')"
echo ""
echo "✅ System check complete!"

APPLYFIXES

    echo "[$(date +%H:%M:%S)] Fixes applied!" | tee -a "$LOG_FILE"
    echo "" | tee -a "$LOG_FILE"
}

# Main loop
echo "[$(date +%H:%M:%S)] Starting monitoring..." | tee -a "$LOG_FILE"
echo "Waiting for Pi 5 to come online..." | tee -a "$LOG_FILE"
echo ""

LAST_STATUS="offline"
while true; do
    if check_pi5_online; then
        if [ "$LAST_STATUS" != "online" ]; then
            echo "[$(date +%H:%M:%S)] ✅ Pi 5 is ONLINE!" | tee -a "$LOG_FILE"
            LAST_STATUS="online"
            apply_fixes
        fi
    else
        if [ "$LAST_STATUS" != "offline" ]; then
            echo "[$(date +%H:%M:%S)] ⏳ Pi 5 is offline, waiting..." | tee -a "$LOG_FILE"
            LAST_STATUS="offline"
        fi
    fi
    sleep 5
done

