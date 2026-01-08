#!/bin/bash
# ENABLE TOUCHSCREEN ON PI 5
# Enables Send Events Mode for WaveShare touchscreen

set -e

echo "=========================================="
echo "ENABLE PI 5 TOUCHSCREEN"
echo "=========================================="
echo ""

ssh pi2 << 'ENABLETOUCH'
export DISPLAY=:0

# Find WaveShare device
WAVESHARE_ID=$(xinput list | grep -i "WaveShare" | grep -oP 'id=\K[0-9]+' | head -1)

if [ -z "$WAVESHARE_ID" ]; then
    echo "❌ WaveShare device not found"
    exit 1
fi

echo "Found WaveShare device: id=$WAVESHARE_ID"
echo ""

# Enable Send Events Mode
echo "Enabling Send Events Mode..."
xinput set-prop "$WAVESHARE_ID" "libinput Send Events Mode Enabled" 1 0

echo ""
echo "Verifying..."
xinput list-props "$WAVESHARE_ID" | grep "Send Events Mode Enabled"

echo ""
echo "✅ Touchscreen enabled!"

# Create persistent configuration
echo ""
echo "Creating persistent configuration..."
cat > /tmp/touchscreen-enable.sh << 'TOUCHSCRIPT'
#!/bin/bash
export DISPLAY=:0
WAVESHARE_ID=$(xinput list | grep -i "WaveShare" | grep -oP 'id=\K[0-9]+' | head -1)
if [ -n "$WAVESHARE_ID" ]; then
    xinput set-prop "$WAVESHARE_ID" "libinput Send Events Mode Enabled" 1 0
fi
TOUCHSCRIPT

sudo cp /tmp/touchscreen-enable.sh /usr/local/bin/enable-touchscreen.sh
sudo chmod +x /usr/local/bin/enable-touchscreen.sh

# Add to .xinitrc if not already there
if ! grep -q "enable-touchscreen" /home/andre/.xinitrc 2>/dev/null; then
    echo "" >> /home/andre/.xinitrc
    echo "# Enable touchscreen" >> /home/andre/.xinitrc
    echo "/usr/local/bin/enable-touchscreen.sh" >> /home/andre/.xinitrc
    echo "✅ Added to .xinitrc"
fi

echo ""
echo "✅ Touchscreen configuration complete!"
echo "Touchscreen will be enabled automatically on boot"

ENABLETOUCH

echo ""
echo "✅ Touchscreen enabled on Pi 5!"

