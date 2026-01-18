#!/bin/bash
################################################################################
#
# Test and Fix Touch Configuration
#
# Diagnoses current state and applies correct fix
#
################################################################################

set -euo pipefail

log() { echo -e "\033[0;32m[TEST]${NC} $1"; }
info() { echo -e "\033[0;34m[INFO]${NC} $1"; }

echo "=== Touch Configuration Test ==="
echo ""

# Check current config
echo "1. Current touch config:"
if [ -f /etc/X11/xorg.conf.d/99-touch-calibration.conf ]; then
    cat /etc/X11/xorg.conf.d/99-touch-calibration.conf
    echo ""
else
    echo "No touch config found"
    echo ""
fi

# Check X11 rotation
echo "2. X11 display rotation:"
if command -v xrandr >/dev/null 2>&1 && [ -n "${DISPLAY:-}" ]; then
    xrandr --query 2>/dev/null | grep -E "HDMI-[12]|connected" | head -3 || echo "Cannot check"
else
    echo "Not in X11 session (this is OK)"
fi
echo ""

# Apply fix
echo "3. Applying horizontal flip fix (fixes left/right, keeps top/bottom)..."
sudo mkdir -p /etc/X11/xorg.conf.d/
sudo tee /etc/X11/xorg.conf.d/99-touch-calibration.conf > /dev/null << 'EOF'
Section "InputClass"
    Identifier "Touchscreen Calibration"
    MatchProduct "*"
    MatchDevicePath "/dev/input/event*"
    Option "TransformationMatrix" "-1 0 1 0 1 0 0 0 1"
EndSection
EOF

log "✅ Applied horizontal flip matrix: -1 0 1 0 1 0 0 0 1"
echo ""

# Restart X11
echo "4. Restarting X11..."
if sudo systemctl restart localdisplay.service 2>/dev/null; then
    log "✅ X11 restarted"
else
    echo "⚠️  Restart failed - try manually: sudo systemctl restart localdisplay.service"
fi

echo ""
echo "=== Done ==="
log "Please test touch now - it should be correct!"
