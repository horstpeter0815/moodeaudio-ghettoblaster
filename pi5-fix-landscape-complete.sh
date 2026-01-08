#!/bin/bash
# PI 5 FIX LANDSCAPE - COMPLETE SOLUTION
# Fix: Full landscape, no cutoff, no flickering

set -e

echo "=========================================="
echo "PI 5 FIX LANDSCAPE - COMPLETE"
echo "Full landscape, no cutoff, stable"
echo "=========================================="
echo ""

ssh pi2 << 'COMPLETEFIX'
BACKUP_DIR="/home/andre/backup_landscape_complete_$(date +%Y%m%d_%H%M%S)"
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

echo "=== FIX: ENSURE PROPER LANDSCAPE CONFIG ==="
echo ""
echo "Strategy:"
echo "  - Framebuffer: Portrait (400x1280)"
echo "  - display_rotate=3: Rotates 270° to show Landscape"
echo "  - X11: Portrait mode (400x1280)"
echo "  - Result: Full Landscape (1280x400) on display"
echo ""

# Clean up old settings
sudo sed -i '/^display_rotate=/d' "$CONFIG_FILE"
sudo sed -i '/display_rotate=/d' "$CONFIG_FILE"
sudo sed -i '/^hdmi_group=/d' "$CONFIG_FILE"
sudo sed -i '/hdmi_group=/d' "$CONFIG_FILE"

# Add correct settings
sudo tee -a "$CONFIG_FILE" > /dev/null << 'CONFIGEOF'

# Landscape display fix - Full 1280x400, no cutoff
display_rotate=3
hdmi_group=0
hdmi_force_hotplug=1
display_auto_detect=1

CONFIGEOF

echo "✅ Config.txt updated"

echo ""
echo "=== CREATE PERFECT .xinitrc ==="
cat > /tmp/.xinitrc_perfect << 'XINITEOF'
#!/bin/bash
export DISPLAY=:0

# Wait for X
for i in {1..50}; do
    if xrandr --query >/dev/null 2>&1; then
        break
    fi
    sleep 0.2
done

xhost +SI:localuser:andre 2>/dev/null || true
sleep 2

echo "Setting up Landscape display (rotated from Portrait)..." >> /tmp/xinit.log

# Use Portrait mode (400x1280) - display_rotate=3 will rotate to Landscape
if xrandr | grep -q "400x1280"; then
    echo "Using 400x1280 Portrait mode" >> /tmp/xinit.log
    xrandr --output HDMI-2 --mode 400x1280 --rotate normal 2>&1
else
    echo "Creating 400x1280 Portrait mode" >> /tmp/xinit.log
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

# Disable all blanking and power management to prevent flickering
xset s off 2>/dev/null || true
xset -dpms 2>/dev/null || true
xset s noblank 2>/dev/null || true

# Additional anti-flicker settings
export COMPOSITOR_DISABLE=1
export GDK_BACKEND=x11

# Start Chromium - Portrait size, rotated to Landscape by display_rotate=3
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
    --disable-default-apps \
    --disable-extensions \
    --no-first-run \
    http://localhost >/dev/null 2>&1 &

sleep 15

# Ensure window is correct size - Portrait (will be rotated)
for attempt in {1..25}; do
    WINDOW=$(xdotool search --class Chromium 2>/dev/null | head -1)
    if [ -n "$WINDOW" ]; then
        # Force Portrait size
        xdotool windowsize $WINDOW 400 1280 2>/dev/null
        xdotool windowmove $WINDOW 0 0 2>/dev/null
        
        SIZE=$(xdotool getwindowgeometry $WINDOW 2>/dev/null | grep Geometry | awk '{print $2}' || echo "")
        if [ "$SIZE" == "400x1280" ]; then
            echo "Window set correctly: $SIZE" >> /tmp/xinit.log
            # Verify it stays
            sleep 3
            SIZE2=$(xdotool getwindowgeometry $WINDOW 2>/dev/null | grep Geometry | awk '{print $2}' || echo "")
            if [ "$SIZE2" == "400x1280" ]; then
                echo "Window stable: $SIZE2" >> /tmp/xinit.log
                break
            fi
        fi
    fi
    sleep 1
done

wait
XINITEOF

sudo cp /tmp/.xinitrc_perfect /home/andre/.xinitrc
sudo chown andre:andre /home/andre/.xinitrc
sudo chmod +x /home/andre/.xinitrc

echo "✅ Perfect .xinitrc created"

echo ""
echo "=== CONFIG SUMMARY ==="
echo "display_rotate=3 (270° - Portrait → Landscape)"
echo "hdmi_group=0 (standard HDMI)"
echo "X11: Portrait (400x1280)"
echo "Display: Landscape (1280x400) via rotation"
COMPLETEFIX

echo ""
echo "=== REBOOTING PI 5 ==="
ssh pi2 "sudo reboot" 2>/dev/null || echo "Pi 5 may be offline, reboot manually if needed"

echo ""
echo "=========================================="
echo "LANDSCAPE FIX COMPLETE"
echo "=========================================="
echo ""
echo "After reboot, display should:"
echo "  ✅ Show full Landscape (1280x400)"
echo "  ✅ Not be cut off"
echo "  ✅ Minimal flickering"
echo ""
echo "Configuration:"
echo "  - Framebuffer: Portrait (400x1280)"
echo "  - display_rotate=3: Rotates to Landscape"
echo "  - X11: Portrait mode"
echo "  - Result: Full Landscape on display"

