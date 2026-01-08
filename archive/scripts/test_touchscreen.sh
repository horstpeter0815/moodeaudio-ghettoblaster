#!/bin/bash
# Touchscreen Test Script
# Tests touchscreen functionality and coordinates

echo "=========================================="
echo "Touchscreen Test Script"
echo "=========================================="
echo ""

# Set display
export DISPLAY=:0

# Find touchscreen device
TOUCH_DEVICE=$(xinput list | grep -i "WaveShare\|Touchscreen" | head -1)

if [ -z "$TOUCH_DEVICE" ]; then
    echo "ERROR: Touchscreen not found!"
    echo ""
    echo "Available input devices:"
    xinput list
    exit 1
fi

TOUCH_DEVICE_ID=$(echo "$TOUCH_DEVICE" | grep -oP 'id=\K[0-9]+')
TOUCH_DEVICE_NAME=$(echo "$TOUCH_DEVICE" | sed 's/.*↳ //' | sed 's/ *id=.*//')

echo "Touchscreen found:"
echo "  Name: $TOUCH_DEVICE_NAME"
echo "  ID: $TOUCH_DEVICE_ID"
echo ""

# Get current properties
echo "Current properties:"
xinput list-props "$TOUCH_DEVICE_ID" | grep -E "Transformation|Calibration"
echo ""

# Get display resolution
DISPLAY_RES=$(xrandr | grep " connected" | head -1 | awk '{print $3}' | cut -d+ -f1)
echo "Display resolution: $DISPLAY_RES"
echo ""

# Test coordinates
echo "=========================================="
echo "Touch Test"
echo "=========================================="
echo "Touch the screen corners and center:"
echo "  - Top-left corner (should be ~0, 0)"
echo "  - Top-right corner (should be ~1280, 0)"
echo "  - Bottom-left corner (should be ~0, 400)"
echo "  - Bottom-right corner (should be ~1280, 400)"
echo "  - Center (should be ~640, 200)"
echo ""
echo "Press Ctrl+C to stop"
echo ""

xinput test "$TOUCH_DEVICE_ID"

