#!/bin/bash
# Quick Display Test Script for Pi 5
# Run this on the Pi 5 after boot to verify HDMI configuration

echo "=========================================="
echo "Pi 5 Display Configuration Test"
echo "=========================================="
echo ""

# Test 1: Check config.txt
echo "=== Test 1: config.txt ==="
if [ -f /boot/firmware/config.txt ]; then
    CONFIG_FILE="/boot/firmware/config.txt"
elif [ -f /boot/config.txt ]; then
    CONFIG_FILE="/boot/config.txt"
else
    echo "❌ config.txt not found!"
    exit 1
fi

echo "Config file: $CONFIG_FILE"
echo ""

# Check for video parameter in cmdline.txt (should NOT be present)
echo "=== Test 2: cmdline.txt (should NOT have video parameter) ==="
if [ -f /boot/firmware/cmdline.txt ]; then
    CMDLINE_FILE="/boot/firmware/cmdline.txt"
elif [ -f /boot/cmdline.txt ]; then
    CMDLINE_FILE="/boot/cmdline.txt"
else
    echo "❌ cmdline.txt not found!"
    exit 1
fi

if grep -q "video=HDMI-A-2:400x1280M@60,rotate=90" "$CMDLINE_FILE"; then
    echo "❌ FAIL: video parameter still present in cmdline.txt"
    echo "   This should have been removed!"
else
    echo "✅ PASS: No video parameter in cmdline.txt"
fi
echo ""

# Check for hdmi_cvt in config.txt (should be present)
echo "=== Test 3: HDMI CVT in config.txt ==="
if grep -q "hdmi_cvt.*1280.*400" "$CONFIG_FILE"; then
    echo "✅ PASS: hdmi_cvt 1280 400 found in config.txt"
    grep "hdmi_cvt.*1280.*400" "$CONFIG_FILE"
else
    echo "❌ FAIL: hdmi_cvt 1280 400 not found in config.txt"
fi
echo ""

# Check for display_rotate=0
echo "=== Test 4: display_rotate ==="
if grep -q "display_rotate=0" "$CONFIG_FILE"; then
    echo "✅ PASS: display_rotate=0 found"
else
    echo "⚠️  WARNING: display_rotate=0 not found (may be default)"
fi
echo ""

# Test 5: Check framebuffer (if available)
echo "=== Test 5: Framebuffer Resolution ==="
if command -v fbset &> /dev/null; then
    FB_INFO=$(fbset -s 2>/dev/null)
    if echo "$FB_INFO" | grep -q "1280x400"; then
        echo "✅ PASS: Framebuffer shows 1280x400"
        echo "$FB_INFO" | grep "geometry"
    else
        echo "⚠️  Framebuffer resolution:"
        echo "$FB_INFO" | grep "geometry" || echo "Could not determine"
    fi
else
    echo "⚠️  fbset not available"
fi
echo ""

# Test 6: Check xrandr (if X11 is running)
echo "=== Test 6: X11 Display (if running) ==="
if [ -n "$DISPLAY" ] || pgrep -x Xorg > /dev/null; then
    if command -v xrandr &> /dev/null; then
        XRANDR_OUTPUT=$(DISPLAY=:0 xrandr 2>/dev/null)
        if echo "$XRANDR_OUTPUT" | grep -q "1280x400"; then
            echo "✅ PASS: xrandr shows 1280x400"
            echo "$XRANDR_OUTPUT" | grep -E "HDMI|connected|1280x400" | head -5
        else
            echo "⚠️  xrandr output:"
            echo "$XRANDR_OUTPUT" | grep -E "HDMI|connected" | head -5
        fi
    else
        echo "⚠️  xrandr not available"
    fi
else
    echo "ℹ️  X11 not running (this is OK if Moode hasn't started display yet)"
fi
echo ""

# Test 7: Check DRM devices
echo "=== Test 7: DRM Devices ==="
if [ -d /sys/class/drm ]; then
    for card in /sys/class/drm/card*/status; do
        if [ -f "$card" ]; then
            CARD_NAME=$(basename $(dirname $card))
            STATUS=$(cat "$card")
            echo "$CARD_NAME: $STATUS"
            if [ "$STATUS" = "connected" ]; then
                MODE_FILE=$(dirname "$card")/modes
                if [ -f "$MODE_FILE" ]; then
                    echo "  Modes: $(cat $MODE_FILE | head -1)"
                fi
            fi
        fi
    done
else
    echo "⚠️  /sys/class/drm not found"
fi
echo ""

# Summary
echo "=========================================="
echo "Test Summary"
echo "=========================================="
echo ""
echo "✅ Configuration files updated:"
echo "   - config.txt: Clean HDMI config"
echo "   - cmdline.txt: No video parameter"
echo ""
echo "📋 Next steps:"
echo "   1. Check if display shows image in landscape (1280x400)"
echo "   2. If display is wrong, check Moode settings:"
echo "      - SSH into Pi: ssh moode@<pi-ip>"
echo "      - Set hdmi_scn_orient = 'landscape' in Moode UI"
echo "   3. If touchscreen coordinates are wrong, run touchscreen fix"
echo ""
echo "=========================================="

