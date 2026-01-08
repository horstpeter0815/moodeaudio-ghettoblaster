#!/bin/bash
# Fix Touchscreen Coordinates
# Interactive script to calibrate touchscreen

set -e

export DISPLAY=:0

echo "=========================================="
echo "Touchscreen Coordinate Calibration"
echo "=========================================="
echo ""

# Find touchscreen
TOUCH_DEVICE=$(xinput list | grep -i "WaveShare" | head -1)
if [ -z "$TOUCH_DEVICE" ]; then
    echo "ERROR: Touchscreen not found!"
    echo "Available devices:"
    xinput list
    exit 1
fi

TOUCH_ID=$(echo "$TOUCH_DEVICE" | grep -oP 'id=\K[0-9]+')
TOUCH_NAME=$(echo "$TOUCH_DEVICE" | sed 's/.*↳ //' | sed 's/ *id=.*//')

echo "Touchscreen: $TOUCH_NAME (ID: $TOUCH_ID)"
echo ""

# Get current matrix
CURRENT_MATRIX=$(xinput list-props "$TOUCH_ID" 2>/dev/null | grep "Coordinate Transformation Matrix" | awk '{print $5, $6, $7, $8, $9, $10, $11, $12, $13}')
echo "Current matrix: $CURRENT_MATRIX"
echo ""

# Test current coordinates
echo "Testing current coordinates..."
echo "Touch the screen corners and note the coordinates:"
echo "  Top-left corner"
echo "  Top-right corner"
echo "  Bottom-left corner"
echo "  Bottom-right corner"
echo ""
echo "Press Ctrl+C when done testing"
echo ""

timeout 30 xinput test "$TOUCH_ID" 2>/dev/null || true

echo ""
echo "Based on the coordinates you saw, choose the fix:"
echo ""
echo "1. Coordinates are correct (no change needed)"
echo "2. X and Y are swapped"
echo "3. Coordinates are rotated 90° clockwise"
echo "4. Coordinates are rotated 90° counter-clockwise"
echo "5. Coordinates are rotated 180°"
echo "6. Y axis is inverted"
echo "7. X axis is inverted"
echo "8. Custom matrix"
echo ""
read -p "Enter choice (1-8): " choice

case $choice in
    1)
        MATRIX="1 0 0 0 1 0 0 0 1"
        ;;
    2)
        MATRIX="0 1 0 1 0 0 0 0 1"
        ;;
    3)
        MATRIX="0 1 0 -1 0 1 0 0 1"
        ;;
    4)
        MATRIX="0 -1 1 1 0 0 0 0 1"
        ;;
    5)
        MATRIX="-1 0 1 0 -1 1 0 0 1"
        ;;
    6)
        MATRIX="1 0 0 0 -1 1 0 0 1"
        ;;
    7)
        MATRIX="-1 0 1 0 1 0 0 0 1"
        ;;
    8)
        echo "Enter matrix values (9 numbers, space-separated):"
        echo "Format: a b c d e f g h i"
        read -p "Matrix: " MATRIX
        ;;
    *)
        echo "Invalid choice"
        exit 1
        ;;
esac

echo ""
echo "Applying matrix: $MATRIX"
xinput set-prop "$TOUCH_ID" "Coordinate Transformation Matrix" $MATRIX

echo "✓ Matrix applied"
echo ""

# Update X11 config
echo "Updating X11 configuration..."
sudo sed -i "s/Option \"TransformationMatrix\" \".*\"/Option \"TransformationMatrix\" \"$MATRIX\"/" /etc/X11/xorg.conf.d/99-touchscreen.conf
echo "✓ X11 config updated"
echo ""

# Update xinitrc
echo "Updating xinitrc..."
sed -i "s/xinput set-prop.*Coordinate Transformation Matrix.*/xinput set-prop \"\$TOUCH_DEVICE\" \"Coordinate Transformation Matrix\" $MATRIX/" "$HOME/.xinitrc"
echo "✓ xinitrc updated"
echo ""

echo "=========================================="
echo "Calibration Complete!"
echo "=========================================="
echo ""
echo "Test the touchscreen now. If coordinates are still wrong,"
echo "run this script again and try a different option."
echo ""

