#!/bin/bash
################################################################################
#
# Diagnose Touch and Display Configuration
#
# Checks current state and provides correct fix
#
################################################################################

set -euo pipefail

log() { echo -e "\033[0;32m[DIAG]${NC} $1"; }
info() { echo -e "\033[0;34m[INFO]${NC} $1"; }
warn() { echo -e "\033[0;33m[WARN]${NC} $1"; }

echo "=== Touch and Display Diagnosis ==="
echo ""

# Check X11 rotation
if command -v xrandr >/dev/null 2>&1 && [ -n "${DISPLAY:-}" ]; then
    echo "=== X11 Display Rotation ==="
    xrandr --query | grep -E "HDMI-[12]|connected|^\s+[0-9]+x[0-9]+" | head -10
    echo ""
    
    CURRENT_ROTATION=$(xrandr --query | grep -E "HDMI-[12]" | grep -oE "left|right|inverted|normal" | head -1 || echo "unknown")
    echo "Current rotation: $CURRENT_ROTATION"
else
    warn "Cannot check X11 (not in X11 session)"
fi

echo ""
echo "=== Current Touch Configuration ==="
if [ -f /etc/X11/xorg.conf.d/99-touch-calibration.conf ]; then
    cat /etc/X11/xorg.conf.d/99-touch-calibration.conf
else
    warn "No touch calibration file found"
fi

echo ""
echo "=== Framebuffer Configuration ==="
if [ -f /boot/firmware/cmdline.txt ]; then
    grep -oE "fbcon=rotate:[0-9]|video=.*rotate" /boot/firmware/cmdline.txt 2>/dev/null || echo "No rotation found"
elif [ -f /boot/cmdline.txt ]; then
    grep -oE "fbcon=rotate:[0-9]|video=.*rotate" /boot/cmdline.txt 2>/dev/null || echo "No rotation found"
fi

echo ""
echo "=== Recommendation ==="
echo "1. Check what moOde Audio display looks like (is it correct?)"
echo "2. Test touch - which direction is wrong?"
echo "3. Apply matching matrix"
echo ""
