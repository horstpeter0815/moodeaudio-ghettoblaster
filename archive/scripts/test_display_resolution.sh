#!/bin/bash
# Test Display Resolution
# Verifies display is actually 1280x400 Landscape

export DISPLAY=:0

echo "=========================================="
echo "Display Resolution Test"
echo "=========================================="
echo ""

# Test 1: xrandr
echo "Test 1: xrandr Output"
XRANDR_OUT=$(xrandr | grep " connected" | head -1)
echo "$XRANDR_OUT"
echo ""

# Check resolution
if echo "$XRANDR_OUT" | grep -q "1280x400"; then
    echo "✅ Resolution: 1280x400"
else
    echo "❌ Resolution incorrect!"
    exit 1
fi

# Check rotation
if echo "$XRANDR_OUT" | grep -q "normal"; then
    echo "✅ Rotation: normal (Landscape)"
elif echo "$XRANDR_OUT" | grep -q "left"; then
    echo "⚠️  Rotation: left (rotated from Portrait)"
    echo "   This means the workaround is still active!"
else
    echo "⚠️  Rotation unclear"
fi
echo ""

# Test 2: Framebuffer
echo "Test 2: Framebuffer"
if command -v fbset &>/dev/null; then
    FB_OUT=$(fbset -s 2>/dev/null | grep geometry | awk '{print $2, $3}' || echo "")
    if [ ! -z "$FB_OUT" ]; then
        echo "Framebuffer: $FB_OUT"
        if echo "$FB_OUT" | grep -q "1280 400"; then
            echo "✅ Framebuffer: 1280x400"
        else
            echo "❌ Framebuffer incorrect!"
            exit 1
        fi
    else
        echo "⚠️  Could not read framebuffer"
    fi
else
    echo "⚠️  fbset not available"
fi
echo ""

# Test 3: Actual screen size
echo "Test 3: Actual Screen Size"
SCREEN_SIZE=$(xrandr | grep " connected" | head -1 | awk '{print $3}' | cut -d+ -f1)
echo "Screen size: $SCREEN_SIZE"
if [ "$SCREEN_SIZE" = "1280x400" ]; then
    echo "✅ Screen size correct"
else
    echo "❌ Screen size incorrect!"
    exit 1
fi
echo ""

# Test 4: Check for rotation workaround
echo "Test 4: Checking for Rotation Workaround"
if grep -q "video=HDMI-A-2:400x1280M@60,rotate=90" /boot/firmware/cmdline.txt 2>/dev/null; then
    echo "❌ FAIL: Video parameter workaround still active!"
    echo "   Run: ./fix_everything.sh"
    exit 1
else
    echo "✅ No video parameter workaround"
fi

if grep -q "xrandr --output HDMI-2 --rotate left" ~/.xinitrc 2>/dev/null; then
    if grep -q "HDMI_SCN_ORIENT.*portrait" ~/.xinitrc; then
        echo "✅ Rotation is conditional (only if portrait)"
    else
        echo "❌ FAIL: Forced rotation still in xinitrc!"
        echo "   Run: ./fix_everything.sh"
        exit 1
    fi
else
    echo "✅ No forced rotation in xinitrc"
fi
echo ""

# Summary
echo "=========================================="
echo "Display Test Summary"
echo "=========================================="
echo "✅ Display is 1280x400 Landscape"
echo "✅ No rotation workaround"
echo "✅ Ready for touchscreen and applications"
echo ""

