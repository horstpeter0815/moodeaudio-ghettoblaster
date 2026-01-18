#!/bin/bash
################################################################################
#
# Fix Touch to Match X11 Display
#
# X11 rotates display: 400x1280 portrait → 1280x400 landscape (rotate left)
# Touch needs to match this rotation
# Framebuffer (boot screen) rotation is separate and doesn't affect touch
#
################################################################################

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() { echo -e "${GREEN}[FIX]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }
info() { echo -e "${BLUE}[INFO]${NC} $1"; }

TOUCH_CONF="/etc/X11/xorg.conf.d/99-touch-calibration.conf"

log "=== Fix Touch to Match X11 Display ==="
echo ""
info "X11 Display: 400x1280 portrait → 1280x400 landscape (rotate left)"
info "Touch must match the X11 display orientation"
info "Framebuffer (boot screen) rotation is separate"
echo ""

# Check current X11 rotation
if command -v xrandr >/dev/null 2>&1 && [ -n "${DISPLAY:-}" ]; then
    CURRENT_ROTATION=$(xrandr --query | grep -E "HDMI-[12]" | grep -oE "left|right|inverted|normal" | head -1 || echo "unknown")
    log "Current X11 rotation: $CURRENT_ROTATION"
else
    log "Cannot check X11 rotation (not in X11 session)"
    info "Assuming: rotate left (400x1280 → 1280x400)"
fi

echo ""
log "Applying touch calibration for X11 'rotate left' orientation..."

sudo mkdir -p /etc/X11/xorg.conf.d/

# For "rotate left" (90° CCW), we need to rotate touch 90° CW to match
# Matrix for 90° CW rotation: 0 1 0 -1 0 1 0 0 1
sudo tee "$TOUCH_CONF" > /dev/null << 'EOF'
Section "InputClass"
    Identifier "Touchscreen Calibration"
    MatchProduct "*"
    MatchDevicePath "/dev/input/event*"
    Option "TransformationMatrix" "0 1 0 -1 0 1 0 0 1"
EndSection
EOF

log "✅ Applied: 90° CW rotation matrix (matches X11 'rotate left')"
info "Matrix: 0 1 0 -1 0 1 0 0 1"
echo ""

log "Restarting X11..."
sudo systemctl restart localdisplay.service 2>/dev/null || {
    error "Failed to restart X11"
    info "Try manually: sudo systemctl restart localdisplay.service"
    exit 1
}

echo ""
log "✅ Touch calibration updated"
info "Touch should now match the moOde Audio display orientation"
echo ""
info "If touch is still wrong, verify X11 rotation:"
echo "  xrandr --query | grep HDMI"
echo ""
info "Alternative matrices to try:"
echo "  If X11 is 'rotate right': Matrix: 0 -1 1 1 0 0 0 0 1"
echo "  If X11 is 'inverted': Matrix: -1 0 1 0 -1 1 0 0 1"
echo "  If X11 is 'normal': Matrix: 1 0 0 0 1 0 0 0 1"
