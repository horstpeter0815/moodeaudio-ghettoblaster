#!/bin/bash
# Complete Touchscreen Fix Script
# Fixes everything and verifies it works

set -e

echo "=========================================="
echo "Complete Touchscreen Fix"
echo "=========================================="
echo ""

# Step 1: Detect touchscreen
echo "Step 1: Detecting touchscreen..."
USB_DEVICE=$(lsusb | grep -i "0712:000a\|WaveShare" || true)
if [ -z "$USB_DEVICE" ]; then
    echo "ERROR: Touchscreen USB device not found!"
    echo "Please connect the touchscreen USB cable."
    exit 1
fi
echo "✓ Touchscreen found: $USB_DEVICE"
echo ""

# Step 2: Wait for X11 (if not running, start it)
echo "Step 2: Checking X11..."
export DISPLAY=:0
if ! xset q &>/dev/null; then
    echo "X11 not running. Will configure for when it starts."
    X11_RUNNING=false
else
    echo "✓ X11 is running"
    X11_RUNNING=true
fi
echo ""

# Step 3: Create X11 configuration
echo "Step 3: Creating X11 configuration..."
sudo mkdir -p /etc/X11/xorg.conf.d

sudo tee /etc/X11/xorg.conf.d/99-touchscreen.conf > /dev/null << 'EOF'
# Touchscreen Configuration for Waveshare 7.9" HDMI LCD
# USB ID: 0712:000a

Section "InputClass"
    Identifier "WaveShare Touchscreen"
    MatchUSBID "0712:000a"
    MatchIsTouchscreen "on"
    Driver "libinput"
    Option "TransformationMatrix" "1 0 0 0 1 0 0 0 1"
    Option "CalibrationMatrix" "1 0 0 0 1 0 0 0 1"
EndSection
EOF

echo "✓ X11 configuration created"
echo ""

# Step 4: Configure xinitrc
echo "Step 4: Configuring xinitrc..."
XINITRC="$HOME/.xinitrc"
XINITRC_BACKUP="$HOME/.xinitrc.backup.$(date +%Y%m%d_%H%M%S)"

# Backup existing xinitrc
if [ -f "$XINITRC" ]; then
    cp "$XINITRC" "$XINITRC_BACKUP"
    echo "✓ Backed up existing xinitrc to $XINITRC_BACKUP"
fi

# Add touchscreen configuration to xinitrc
TOUCH_CONFIG='
# Touchscreen Configuration (added by fix_touchscreen_complete.sh)
sleep 2  # Wait for X11 to be ready
TOUCH_DEVICE=$(xinput list | grep -i "WaveShare" | head -1 | grep -oP "id=\K[0-9]+" || echo "")
if [ ! -z "$TOUCH_DEVICE" ]; then
    xinput set-prop "$TOUCH_DEVICE" "Coordinate Transformation Matrix" 1 0 0 0 1 0 0 0 1
    echo "Touchscreen configured: Device $TOUCH_DEVICE"
else
    echo "WARNING: Touchscreen not found in xinput"
fi
'

# Check if touchscreen config already exists
if grep -q "Touchscreen Configuration" "$XINITRC" 2>/dev/null; then
    echo "⚠️  Touchscreen config already exists in xinitrc"
    echo "   Skipping xinitrc modification"
else
    # Add before Chromium launch
    if grep -q "chromium\|Chromium" "$XINITRC" 2>/dev/null; then
        # Insert before chromium line
        sed -i "/chromium\|Chromium/i\\$TOUCH_CONFIG" "$XINITRC"
    else
        # Append to end
        echo "$TOUCH_CONFIG" >> "$XINITRC"
    fi
    echo "✓ Touchscreen config added to xinitrc"
fi
echo ""

# Step 5: Apply configuration now (if X11 running)
if [ "$X11_RUNNING" = true ]; then
    echo "Step 5: Applying configuration now..."
    TOUCH_ID=$(xinput list | grep -i "WaveShare" | head -1 | grep -oP 'id=\K[0-9]+' || echo "")
    
    if [ ! -z "$TOUCH_ID" ]; then
        xinput set-prop "$TOUCH_ID" "Coordinate Transformation Matrix" 1 0 0 0 1 0 0 0 1
        echo "✓ Transformation matrix applied to device $TOUCH_ID"
        
        # Verify
        CURRENT_MATRIX=$(xinput list-props "$TOUCH_ID" 2>/dev/null | grep "Coordinate Transformation Matrix" | awk '{print $5, $6, $7, $8, $9, $10, $11, $12, $13}')
        echo "✓ Current matrix: $CURRENT_MATRIX"
    else
        echo "⚠️  Touchscreen not found in xinput (may appear after restart)"
    fi
    echo ""
fi

# Step 6: Create test script
echo "Step 6: Creating test script..."
cat > "$HOME/test_touchscreen.sh" << 'TESTEOF'
#!/bin/bash
export DISPLAY=:0

TOUCH_ID=$(xinput list | grep -i "WaveShare" | head -1 | grep -oP 'id=\K[0-9]+' || echo "")
if [ -z "$TOUCH_ID" ]; then
    echo "ERROR: Touchscreen not found!"
    xinput list
    exit 1
fi

echo "Touchscreen ID: $TOUCH_ID"
echo "Touch the screen corners to test coordinates:"
echo "  Top-left should be ~(0, 0)"
echo "  Top-right should be ~(1280, 0)"
echo "  Bottom-left should be ~(0, 400)"
echo "  Bottom-right should be ~(1280, 400)"
echo ""
echo "Press Ctrl+C to stop"
xinput test "$TOUCH_ID"
TESTEOF

chmod +x "$HOME/test_touchscreen.sh"
echo "✓ Test script created: $HOME/test_touchscreen.sh"
echo ""

# Step 7: Summary
echo "=========================================="
echo "Setup Complete!"
echo "=========================================="
echo ""
echo "Configuration files created:"
echo "  ✓ /etc/X11/xorg.conf.d/99-touchscreen.conf"
echo "  ✓ $HOME/.xinitrc (updated)"
echo "  ✓ $HOME/test_touchscreen.sh (test script)"
echo ""

if [ "$X11_RUNNING" = true ]; then
    echo "Touchscreen should work NOW."
    echo ""
    echo "To test:"
    echo "  $HOME/test_touchscreen.sh"
else
    echo "Touchscreen will be configured when X11 starts."
    echo ""
    echo "After reboot or X11 start:"
    echo "  $HOME/test_touchscreen.sh"
fi
echo ""

echo "If coordinates are wrong, run:"
echo "  ./fix_touchscreen_coordinates.sh"
echo ""

