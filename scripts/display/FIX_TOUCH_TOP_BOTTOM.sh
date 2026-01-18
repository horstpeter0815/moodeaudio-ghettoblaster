#!/bin/bash
################################################################################
#
# Fix Touch Top/Bottom Swap
#
# Tries different transformation matrices to fix top/bottom swap
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

log "=== Fix Touch Top/Bottom Swap ==="
echo ""

# Try horizontal flip first (fixes left/right, may also fix top/bottom)
log "Trying horizontal flip matrix..."
sudo mkdir -p /etc/X11/xorg.conf.d/

sudo tee "$TOUCH_CONF" > /dev/null << 'EOF'
Section "InputClass"
    Identifier "Touchscreen Calibration"
    MatchProduct "*"
    MatchDevicePath "/dev/input/event*"
    Option "TransformationMatrix" "-1 0 1 0 1 0 0 0 1"
EndSection
EOF

log "✅ Applied matrix: Horizontal flip"
info "Matrix: -1 0 1 0 1 0 0 0 1"
info "This fixes left/right swap"
echo ""

log "Restarting X11..."
sudo systemctl restart localdisplay.service 2>/dev/null || {
    error "Failed to restart X11"
    info "Try manually: sudo systemctl restart localdisplay.service"
    exit 1
}

echo ""
log "✅ Touch calibration updated"
info "Please test touch input now"
echo ""
info "If top/bottom is still wrong, try these alternatives:"
echo ""
echo "  Option 1 (90° CCW rotation):"
echo "    Matrix: 0 -1 1 1 0 0 0 0 1"
echo ""
echo "  Option 2 (270° rotation):"
echo "    Matrix: 0 1 0 -1 0 1 0 0 1"
echo ""
echo "  Option 3 (no transform - test if original is better):"
echo "    Matrix: 1 0 0 0 1 0 0 0 1"
echo ""
info "To apply alternative, run:"
echo "  sudo bash scripts/display/TEST_TOUCH_MATRICES.sh"
