#!/bin/bash
# ANALYZE DISPLAY ISSUE PROPERLY
# Compare working HiFiBerry Pi 4 vs Pi 5 - no premature changes

set -e

echo "=========================================="
echo "PROPER DISPLAY ISSUE ANALYSIS"
echo "Compare working HiFiBerry Pi 4 vs Pi 5"
echo "=========================================="
echo ""

echo "=== STEP 1: CHECK HIFIBERRY PI 4 DISPLAY ==="
echo ""
echo "We need to check:"
echo "  1. What display is connected to HiFiBerry Pi 4"
echo "  2. How it's configured"
echo "  3. If it works correctly"
echo ""
echo "What is the HiFiBerry Pi 4 hostname or IP address?"
echo "Common options:"
echo "  - pi3, pi4, hifiberry"
echo "  - 192.168.178.xxx"
echo ""
echo "Please provide the connection info, or I'll try to find it..."
echo ""

# Try common hostnames
for host in pi3 pi4 hifiberry; do
    if ping -c 1 -W 1000 $host >/dev/null 2>&1; then
        echo "Found: $host"
        HIFIBERRY_HOST=$host
        break
    fi
done

if [ -z "$HIFIBERRY_HOST" ]; then
    echo "⚠️ Cannot auto-detect HiFiBerry Pi 4"
    echo "Please manually check the display there and provide:"
    echo "  - Display model"
    echo "  - If it works correctly"
    echo "  - Configuration used"
else
    echo ""
    echo "=== CHECKING HIFIBERRY PI 4 ==="
    ssh $HIFIBERRY_HOST << 'HIFICHECK'
export DISPLAY=:0

echo "1. Display detection:"
xrandr --query 2>/dev/null | grep connected || echo "No X server running"

echo ""
echo "2. Config.txt display settings:"
sudo grep -E "hdmi|display|vc4" /boot/config.txt 2>/dev/null | head -10 || echo "Cannot read config.txt"

echo ""
echo "3. System info:"
uname -a
echo ""
cat /proc/device-tree/model 2>/dev/null || echo "Cannot read model"
HIFICHECK
fi

echo ""
echo "=== STEP 2: COMPARE WITH PI 5 ==="
echo "Current Pi 5 (pi2) configuration:"
ssh pi2 << 'PI5CHECK'
export DISPLAY=:0

echo "1. Display:"
xrandr --query | grep connected

echo ""
echo "2. Config.txt:"
sudo grep -E "hdmi|display|vc4|framebuffer" /boot/config.txt | head -15

echo ""
echo "3. Cmdline:"
cat /proc/cmdline | grep -o 'video=[^ ]*' || echo "No video parameter"
PI5CHECK

echo ""
echo "=== STEP 3: COMPARISON ANALYSIS ==="
echo ""
echo "We need to compare:"
echo "  - Display configuration differences"
echo "  - Video driver settings"
echo "  - HDMI parameters"
echo "  - Resolution settings"
echo ""
echo "This will help identify the REAL cause!"

