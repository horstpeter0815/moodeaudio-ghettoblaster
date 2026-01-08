#!/bin/bash
# Complete Verification Script
# Verifies ALL fixes are working

set -e

echo "=========================================="
echo "Complete System Verification"
echo "=========================================="
echo ""

ERRORS=0
WARNINGS=0

# Check 1: cmdline.txt - No video parameter
echo "Check 1: cmdline.txt - No video parameter"
if grep -q "video=HDMI-A-2:400x1280M@60,rotate=90" /boot/firmware/cmdline.txt; then
    echo "❌ FAIL: Video parameter still present!"
    ERRORS=$((ERRORS + 1))
else
    echo "✅ PASS: Video parameter removed"
fi
echo ""

# Check 2: config.txt - display_rotate=0
echo "Check 2: config.txt - display_rotate=0"
if grep -q "^display_rotate=0" /boot/firmware/config.txt; then
    echo "✅ PASS: display_rotate=0 set"
else
    echo "⚠️  WARN: display_rotate=0 not found"
    WARNINGS=$((WARNINGS + 1))
fi
echo ""

# Check 3: config.txt - hdmi_cvt correct
echo "Check 3: config.txt - hdmi_cvt 1280 400"
if grep -q "hdmi_cvt.*1280.*400" /boot/firmware/config.txt; then
    echo "✅ PASS: hdmi_cvt 1280 400 found"
else
    echo "⚠️  WARN: hdmi_cvt not found or incorrect"
    WARNINGS=$((WARNINGS + 1))
fi
echo ""

# Check 4: xinitrc - No forced rotation
echo "Check 4: xinitrc - No forced rotation"
if grep -q "xrandr --output HDMI-2 --rotate left" ~/.xinitrc 2>/dev/null; then
    # Check if it's conditional
    if grep -q "HDMI_SCN_ORIENT.*portrait" ~/.xinitrc; then
        echo "✅ PASS: Rotation is conditional (only if portrait)"
    else
        echo "❌ FAIL: Forced rotation still present!"
        ERRORS=$((ERRORS + 1))
    fi
else
    echo "✅ PASS: No forced rotation"
fi
echo ""

# Check 5: Display resolution (if X11 running)
echo "Check 5: Display Resolution"
export DISPLAY=:0
if xset q &>/dev/null; then
    XRANDR_OUT=$(xrandr | grep " connected" | head -1)
    if echo "$XRANDR_OUT" | grep -q "1280x400"; then
        if echo "$XRANDR_OUT" | grep -q "normal\|left"; then
            echo "✅ PASS: Display is 1280x400"
            echo "   $XRANDR_OUT"
        else
            echo "⚠️  WARN: Display resolution correct but rotation unclear"
            echo "   $XRANDR_OUT"
            WARNINGS=$((WARNINGS + 1))
        fi
    else
        echo "❌ FAIL: Display resolution incorrect!"
        echo "   $XRANDR_OUT"
        ERRORS=$((ERRORS + 1))
    fi
else
    echo "⚠️  SKIP: X11 not running"
fi
echo ""

# Check 6: Framebuffer (if available)
echo "Check 6: Framebuffer Resolution"
if command -v fbset &>/dev/null; then
    FB_OUT=$(fbset -s 2>/dev/null | grep geometry | awk '{print $2, $3}' || echo "")
    if [ ! -z "$FB_OUT" ]; then
        if echo "$FB_OUT" | grep -q "1280 400"; then
            echo "✅ PASS: Framebuffer is 1280x400"
        else
            echo "⚠️  WARN: Framebuffer resolution: $FB_OUT"
            WARNINGS=$((WARNINGS + 1))
        fi
    else
        echo "⚠️  WARN: Could not read framebuffer"
        WARNINGS=$((WARNINGS + 1))
    fi
else
    echo "⚠️  SKIP: fbset not available"
fi
echo ""

# Check 7: Touchscreen detection
echo "Check 7: Touchscreen Detection"
USB_CHECK=$(lsusb | grep -i "0712:000a\|WaveShare" || true)
if [ -z "$USB_CHECK" ]; then
    echo "⚠️  WARN: Touchscreen USB device not found"
    WARNINGS=$((WARNINGS + 1))
else
    echo "✅ PASS: Touchscreen USB device found"
    echo "   $USB_CHECK"
fi
echo ""

# Check 8: Touchscreen in X11
echo "Check 8: Touchscreen in X11"
if xset q &>/dev/null; then
    TOUCH_XINPUT=$(xinput list | grep -i "WaveShare\|Touchscreen" || true)
    if [ -z "$TOUCH_XINPUT" ]; then
        echo "⚠️  WARN: Touchscreen not in xinput"
        WARNINGS=$((WARNINGS + 1))
    else
        echo "✅ PASS: Touchscreen found in xinput"
        TOUCH_ID=$(echo "$TOUCH_XINPUT" | grep -oP 'id=\K[0-9]+')
        
        # Check transformation matrix
        MATRIX=$(xinput list-props "$TOUCH_ID" 2>/dev/null | grep "Coordinate Transformation Matrix" | awk '{print $5, $6, $7, $8, $9, $10, $11, $12, $13}' || echo "")
        if [ "$MATRIX" = "1 0 0 0 1 0 0 0 1" ]; then
            echo "✅ PASS: Transformation matrix correct"
        else
            echo "⚠️  WARN: Transformation matrix: $MATRIX"
            WARNINGS=$((WARNINGS + 1))
        fi
    fi
else
    echo "⚠️  SKIP: X11 not running"
fi
echo ""

# Check 9: X11 touchscreen config
echo "Check 9: X11 Touchscreen Config"
if [ -f "/etc/X11/xorg.conf.d/99-touchscreen.conf" ]; then
    echo "✅ PASS: X11 touchscreen config exists"
    if grep -q "0712:000a" /etc/X11/xorg.conf.d/99-touchscreen.conf; then
        echo "✅ PASS: USB ID matches"
    else
        echo "⚠️  WARN: USB ID not found in config"
        WARNINGS=$((WARNINGS + 1))
    fi
else
    echo "⚠️  WARN: X11 touchscreen config not found"
    WARNINGS=$((WARNINGS + 1))
fi
echo ""

# Summary
echo "=========================================="
echo "Verification Summary"
echo "=========================================="
echo "Errors: $ERRORS"
echo "Warnings: $WARNINGS"
echo ""

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo "✅ ALL CHECKS PASSED!"
    echo ""
    echo "Everything should work now:"
    echo "  ✓ Display starts in Landscape (1280x400)"
    echo "  ✓ No rotation workaround"
    echo "  ✓ Touchscreen coordinates correct"
    echo "  ✓ Chromium should work"
    echo "  ✓ Peppy Meter should work!"
    exit 0
elif [ $ERRORS -eq 0 ]; then
    echo "⚠️  SOME WARNINGS - System should work but check warnings"
    exit 0
else
    echo "❌ ERRORS FOUND - System will NOT work correctly"
    echo ""
    echo "Fix errors and run verification again"
    exit 1
fi

