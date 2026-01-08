#!/bin/bash
# PI 5 ENSURE LANDSCAPE
# Make absolutely sure display shows Landscape (1280x400)

set -e

echo "=========================================="
echo "PI 5 ENSURE LANDSCAPE"
echo "Guarantee Landscape orientation"
echo "=========================================="
echo ""

ssh pi2 << 'ENSURELANDSCAPE'
export DISPLAY=:0

# Find config.txt
if [ -f "/boot/firmware/config.txt" ]; then
    CONFIG_FILE="/boot/firmware/config.txt"
else
    CONFIG_FILE="/boot/config.txt"
fi

echo "=== STEP 1: FIX CONFIG.TXT ==="
# Remove all rotation settings
sudo sed -i '/^display_rotate=/d' "$CONFIG_FILE"
sudo sed -i '/display_rotate=/d' "$CONFIG_FILE"
sudo sed -i '/^hdmi_group=/d' "$CONFIG_FILE"

# Add correct settings for Landscape
echo "display_rotate=3" | sudo tee -a "$CONFIG_FILE" > /dev/null
echo "hdmi_group=0" | sudo tee -a "$CONFIG_FILE" > /dev/null

echo "✅ Config.txt: display_rotate=3 (270° = Portrait→Landscape)"

echo ""
echo "=== STEP 2: SET X11 TO PORTRAIT (ROTATED TO LANDSCAPE) ==="
# Use Portrait mode - display_rotate=3 will rotate to Landscape
if xrandr | grep -q "400x1280"; then
    xrandr --output HDMI-2 --mode 400x1280 --rotate normal 2>&1
    echo "✅ Set to 400x1280 (Portrait) - will show as Landscape (1280x400)"
else
    TIMING=$(cvt 400 1280 60 | grep Modeline | sed 's/Modeline //')
    MODE_NAME=$(echo $TIMING | awk '{print $1}' | tr -d '"')
    xrandr --newmode $TIMING 2>&1 | grep -v "already exists" || true
    xrandr --addmode HDMI-2 "$MODE_NAME" 2>&1 | grep -v "already exists" || true
    xrandr --output HDMI-2 --mode "$MODE_NAME" --rotate normal 2>&1
    echo "✅ Created and set 400x1280 mode"
fi

echo ""
echo "=== STEP 3: FIX CHROMIUM WINDOW ==="
sleep 3
for i in {1..15}; do
    WINDOW=$(xdotool search --class Chromium 2>/dev/null | head -1)
    if [ -n "$WINDOW" ]; then
        xdotool windowsize $WINDOW 400 1280 2>/dev/null
        xdotool windowmove $WINDOW 0 0 2>/dev/null
        SIZE=$(xdotool getwindowgeometry $WINDOW 2>/dev/null | grep Geometry | awk '{print $2}' || echo "")
        if [ "$SIZE" == "400x1280" ]; then
            echo "✅ Window fixed: $SIZE (will show as Landscape)"
            break
        fi
    fi
    sleep 1
done

echo ""
echo "=== STEP 4: RESTART DISPLAY SERVICE ==="
sudo systemctl restart localdisplay
echo "✅ Display service restarted"

echo ""
echo "=== VERIFICATION ==="
sleep 5
export DISPLAY=:0
echo "Config:"
sudo grep -E "display_rotate|hdmi_group" "$CONFIG_FILE" | grep -v "^#"

echo ""
echo "Display:"
xrandr --query | grep "HDMI-2 connected"

echo ""
echo "Resolution:"
xrandr --query | grep "HDMI-2" | grep -oP '\d+x\d+' | head -1

echo ""
echo "✅ Landscape configuration complete!"
echo "Display should show Landscape (1280x400) on screen"
ENSURELANDSCAPE

echo ""
echo "=========================================="
echo "LANDSCAPE ENSURED"
echo "=========================================="
echo ""
echo "Display is now configured for Landscape (1280x400)"
echo "Please check visually!"


