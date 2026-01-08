#!/bin/bash
# Complete Touchscreen Verification Script
# Verifies EVERYTHING is working correctly

set -e

echo "=========================================="
echo "Touchscreen Complete Verification"
echo "=========================================="
echo ""

ERRORS=0
WARNINGS=0

# Check 1: USB Device
echo "Check 1: USB Device Detection"
USB_CHECK=$(lsusb | grep -i "0712:000a\|WaveShare" || true)
if [ -z "$USB_CHECK" ]; then
    echo "❌ FAIL: USB device not found"
    echo "   Run: lsusb"
    ERRORS=$((ERRORS + 1))
else
    echo "✅ PASS: USB device found"
    echo "   $USB_CHECK"
fi
echo ""

# Check 2: Input Device
echo "Check 2: Input Device Exists"
INPUT_DEVICES=$(ls -la /dev/input/ | grep event | wc -l)
if [ "$INPUT_DEVICES" -lt 3 ]; then
    echo "⚠️  WARN: Few input devices found ($INPUT_DEVICES)"
    WARNINGS=$((WARNINGS + 1))
else
    echo "✅ PASS: Input devices found ($INPUT_DEVICES)"
fi
echo ""

# Check 3: X11 Running
echo "Check 3: X11 Running"
export DISPLAY=:0
if ! xset q &>/dev/null; then
    echo "❌ FAIL: X11 not running"
    echo "   Cannot test X11 integration"
    ERRORS=$((ERRORS + 1))
else
    echo "✅ PASS: X11 is running"
fi
echo ""

# Check 4: Touchscreen in xinput
echo "Check 4: Touchscreen in xinput"
if xset q &>/dev/null; then
    TOUCH_XINPUT=$(xinput list | grep -i "WaveShare\|Touchscreen" || true)
    if [ -z "$TOUCH_XINPUT" ]; then
        echo "❌ FAIL: Touchscreen not in xinput list"
        echo "   Available devices:"
        xinput list | head -10
        ERRORS=$((ERRORS + 1))
    else
        echo "✅ PASS: Touchscreen found in xinput"
        echo "   $TOUCH_XINPUT"
        TOUCH_ID=$(echo "$TOUCH_XINPUT" | grep -oP 'id=\K[0-9]+')
    fi
else
    echo "⚠️  SKIP: X11 not running"
    TOUCH_ID=""
fi
echo ""

# Check 5: Transformation Matrix
echo "Check 5: Transformation Matrix"
if [ ! -z "$TOUCH_ID" ]; then
    MATRIX=$(xinput list-props "$TOUCH_ID" 2>/dev/null | grep "Coordinate Transformation Matrix" | awk '{print $5, $6, $7, $8, $9, $10, $11, $12, $13}' || echo "")
    if [ -z "$MATRIX" ]; then
        echo "⚠️  WARN: No transformation matrix found"
        WARNINGS=$((WARNINGS + 1))
    else
        EXPECTED="1 0 0 0 1 0 0 0 1"
        if [ "$MATRIX" = "$EXPECTED" ]; then
            echo "✅ PASS: Transformation matrix correct"
            echo "   Matrix: $MATRIX"
        else
            echo "⚠️  WARN: Transformation matrix different"
            echo "   Current: $MATRIX"
            echo "   Expected: $EXPECTED"
            WARNINGS=$((WARNINGS + 1))
        fi
    fi
else
    echo "⚠️  SKIP: Cannot check matrix (no touchscreen ID)"
fi
echo ""

# Check 6: X11 Configuration File
echo "Check 6: X11 Configuration File"
XORG_CONF="/etc/X11/xorg.conf.d/99-touchscreen.conf"
if [ -f "$XORG_CONF" ]; then
    echo "✅ PASS: X11 config file exists"
    if grep -q "0712:000a" "$XORG_CONF"; then
        echo "✅ PASS: USB ID matches in config"
    else
        echo "⚠️  WARN: USB ID not found in config"
        WARNINGS=$((WARNINGS + 1))
    fi
else
    echo "⚠️  WARN: X11 config file not found"
    echo "   Expected: $XORG_CONF"
    WARNINGS=$((WARNINGS + 1))
fi
echo ""

# Check 7: xinitrc Integration
echo "Check 7: xinitrc Integration"
XINITRC="$HOME/.xinitrc"
if [ -f "$XINITRC" ]; then
    if grep -q "touchscreen\|WaveShare\|xinput.*set-prop" "$XINITRC"; then
        echo "✅ PASS: Touchscreen config in xinitrc"
    else
        echo "⚠️  WARN: Touchscreen config not in xinitrc"
        WARNINGS=$((WARNINGS + 1))
    fi
else
    echo "⚠️  WARN: xinitrc not found"
    WARNINGS=$((WARNINGS + 1))
fi
echo ""

# Check 8: Test Touch Input (if possible)
echo "Check 8: Touch Input Test"
if [ ! -z "$TOUCH_ID" ]; then
    echo "   Touch the screen now (5 second test)..."
    timeout 5 xinput test "$TOUCH_ID" 2>/dev/null && echo "✅ PASS: Touch input detected" || echo "⚠️  WARN: No touch input detected"
else
    echo "⚠️  SKIP: Cannot test (no touchscreen ID)"
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
    echo "✅ ALL CHECKS PASSED - Touchscreen should work!"
    exit 0
elif [ $ERRORS -eq 0 ]; then
    echo "⚠️  SOME WARNINGS - Touchscreen may work but needs attention"
    exit 0
else
    echo "❌ ERRORS FOUND - Touchscreen will NOT work correctly"
    exit 1
fi

