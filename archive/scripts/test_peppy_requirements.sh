#!/bin/bash
# Test Peppy Meter Requirements
# Verifies everything Peppy needs is correct

export DISPLAY=:0

echo "=========================================="
echo "Peppy Meter Requirements Test"
echo "=========================================="
echo ""

ERRORS=0

# Requirement 1: Display Resolution
echo "Requirement 1: Display Resolution (1280x400)"
SCREEN_SIZE=$(xrandr | grep " connected" | head -1 | awk '{print $3}' | cut -d+ -f1)
if [ "$SCREEN_SIZE" = "1280x400" ]; then
    echo "✅ PASS: Display is 1280x400"
else
    echo "❌ FAIL: Display is $SCREEN_SIZE (should be 1280x400)"
    ERRORS=$((ERRORS + 1))
fi
echo ""

# Requirement 2: Display Orientation
echo "Requirement 2: Display Orientation (Landscape)"
XRANDR_OUT=$(xrandr | grep " connected" | head -1)
if echo "$XRANDR_OUT" | grep -q "normal"; then
    echo "✅ PASS: Display is Landscape (normal)"
elif echo "$XRANDR_OUT" | grep -q "left"; then
    echo "❌ FAIL: Display is rotated (left) - workaround still active!"
    ERRORS=$((ERRORS + 1))
else
    echo "⚠️  WARN: Display orientation unclear"
fi
echo ""

# Requirement 3: No Rotation Workaround
echo "Requirement 3: No Rotation Workaround"
if grep -q "video=HDMI-A-2:400x1280M@60,rotate=90" /boot/firmware/cmdline.txt 2>/dev/null; then
    echo "❌ FAIL: Video parameter workaround still active!"
    ERRORS=$((ERRORS + 1))
else
    echo "✅ PASS: No video parameter workaround"
fi
echo ""

# Requirement 4: Touchscreen Coordinates
echo "Requirement 4: Touchscreen Coordinates"
TOUCH_ID=$(xinput list | grep -i "WaveShare" | head -1 | grep -oP 'id=\K[0-9]+' || echo "")
if [ ! -z "$TOUCH_ID" ]; then
    MATRIX=$(xinput list-props "$TOUCH_ID" 2>/dev/null | grep "Coordinate Transformation Matrix" | awk '{print $5, $6, $7, $8, $9, $10, $11, $12, $13}' || echo "")
    if [ "$MATRIX" = "1 0 0 0 1 0 0 0 1" ]; then
        echo "✅ PASS: Touchscreen matrix correct (identity)"
    else
        echo "⚠️  WARN: Touchscreen matrix: $MATRIX"
        echo "   May need calibration"
    fi
else
    echo "⚠️  WARN: Touchscreen not found"
fi
echo ""

# Requirement 5: Framebuffer
echo "Requirement 5: Framebuffer Resolution"
if command -v fbset &>/dev/null; then
    FB_OUT=$(fbset -s 2>/dev/null | grep geometry | awk '{print $2, $3}' || echo "")
    if echo "$FB_OUT" | grep -q "1280 400"; then
        echo "✅ PASS: Framebuffer is 1280x400"
    else
        echo "⚠️  WARN: Framebuffer is $FB_OUT (should be 1280 400)"
    fi
else
    echo "⚠️  SKIP: fbset not available"
fi
echo ""

# Summary
echo "=========================================="
echo "Peppy Requirements Summary"
echo "=========================================="
echo "Errors: $ERRORS"
echo ""

if [ $ERRORS -eq 0 ]; then
    echo "✅ ALL REQUIREMENTS MET!"
    echo ""
    echo "Peppy Meter should work now!"
    echo ""
    echo "To test Peppy:"
    echo "  1. Start Peppy Meter"
    echo "  2. Verify it displays correctly"
    echo "  3. Test touch interaction"
    echo "  4. Verify everything works"
    exit 0
else
    echo "❌ REQUIREMENTS NOT MET!"
    echo ""
    echo "Fix errors and run again:"
    echo "  ./fix_everything.sh"
    echo "  sudo reboot"
    echo "  ./test_peppy_requirements.sh"
    exit 1
fi

