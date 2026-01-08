#!/bin/bash
# PI 5 TOUCHSCREEN FIX
# Comprehensive fix for touchscreen issues

set -e

echo "=========================================="
echo "PI 5 TOUCHSCREEN FIX"
echo "=========================================="
echo ""

ssh pi2 << 'FIXTOUCH'
export DISPLAY=:0

echo "=== FIXING TOUCHSCREEN ==="
echo ""

# Find WaveShare device
WAVESHARE_ID=$(xinput list | grep -i "WaveShare" | grep -oP 'id=\K[0-9]+' | head -1)

if [ -z "$WAVESHARE_ID" ]; then
    echo "❌ WaveShare device not found"
    echo "Checking USB devices..."
    lsusb | grep -i "0712\|waveshare" || echo "WaveShare USB device not found"
    exit 1
fi

echo "Found WaveShare device: ID=$WAVESHARE_ID"
echo ""

# 1. Enable device
echo "1. Enabling device..."
xinput enable "$WAVESHARE_ID"
echo "✅ Device enabled"

# 2. Enable Send Events Mode
echo ""
echo "2. Enabling Send Events Mode..."
xinput set-prop "$WAVESHARE_ID" "libinput Send Events Mode Enabled" 1 0
echo "✅ Send Events Mode enabled"

# 3. Set calibration matrix
echo ""
echo "3. Setting calibration matrix..."
xinput set-prop "$WAVESHARE_ID" "Coordinate Transformation Matrix" 0 -1 1 1 0 0 0 0 1
echo "✅ Calibration matrix set (moOde 270° rotation)"

# 4. Verify
echo ""
echo "4. Verifying configuration..."
ENABLED=$(xinput list-props "$WAVESHARE_ID" | grep "Device Enabled" | awk '{print $4}')
SEND_EVENTS=$(xinput list-props "$WAVESHARE_ID" | grep "Send Events Mode Enabled" | awk '{print $5, $6}')
MATRIX=$(xinput list-props "$WAVESHARE_ID" | grep "Coordinate Transformation Matrix" | awk '{print $5, $6, $7, $8, $9, $10, $11, $12, $13}')

echo "Device Enabled: $ENABLED"
echo "Send Events: $SEND_EVENTS"
echo "Matrix: $MATRIX"

if [ "$ENABLED" = "1" ] && echo "$SEND_EVENTS" | grep -q "1, 0"; then
    echo ""
    echo "✅ Configuration looks correct!"
    echo ""
    echo "Testing touch events (5 seconds)..."
    echo "Touch the screen now:"
    timeout 5 xinput test "$WAVESHARE_ID" 2>&1 | head -20 || echo "(No events - try touching the screen)"
else
    echo ""
    echo "⚠️  Configuration might need adjustment"
fi

# 5. Update .xinitrc for persistence
echo ""
echo "5. Updating .xinitrc for persistence..."
if ! grep -q "xinput set-prop.*WaveShare.*Coordinate Transformation Matrix" /home/andre/.xinitrc 2>/dev/null; then
    # Add after xhost, before chromium
    sed -i '/chromium-browser/i\
# Touchscreen configuration\
WAVESHARE_ID=$(xinput list | grep -i "WaveShare" | grep -oP '\''id=\\K[0-9]+'\'' | head -1)\
if [ -n "$WAVESHARE_ID" ]; then\
    xinput enable "$WAVESHARE_ID"\
    xinput set-prop "$WAVESHARE_ID" "libinput Send Events Mode Enabled" 1 0\
    xinput set-prop "$WAVESHARE_ID" "Coordinate Transformation Matrix" 0 -1 1 1 0 0 0 0 1\
fi' /home/andre/.xinitrc
    echo "✅ Added to .xinitrc"
else
    echo "✅ Already in .xinitrc"
fi

echo ""
echo "=========================================="
echo "TOUCHSCREEN FIX COMPLETE"
echo "=========================================="
echo ""
echo "If touchscreen still doesn't work:"
echo "  1. Check USB connection"
echo "  2. Try unplugging and replugging USB cable"
echo "  3. Check if device appears in: lsusb | grep 0712"
echo "  4. Restart X server: sudo systemctl restart localdisplay"

FIXTOUCH

echo ""
echo "✅ Touchscreen fix applied!"

