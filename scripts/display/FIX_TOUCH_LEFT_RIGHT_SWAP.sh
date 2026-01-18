#!/bin/bash
################################################################################
#
# Fix Touch Left/Right Swap
#
# Updates the touch transformation matrix to fix left/right swap issue
# on Waveshare 7.9" display rotated to landscape mode.
#
################################################################################

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() { echo -e "${GREEN}[FIX]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }
info() { echo -e "${BLUE}[INFO]${NC} $1"; }

TOUCH_CONF="/etc/X11/xorg.conf.d/99-touch-calibration.conf"
BACKUP_CONF="${TOUCH_CONF}.backup.$(date +%Y%m%d_%H%M%S)"

log "Fixing touch left/right swap..."

# Backup existing config
if [ -f "$TOUCH_CONF" ]; then
    log "Backing up existing config to $BACKUP_CONF"
    sudo cp "$TOUCH_CONF" "$BACKUP_CONF"
fi

# Create directory if it doesn't exist
sudo mkdir -p /etc/X11/xorg.conf.d/

# Write new touch calibration config
log "Updating touch transformation matrix..."
sudo tee "$TOUCH_CONF" > /dev/null << 'EOF'
Section "InputClass"
    Identifier "Touchscreen Calibration"
    MatchProduct "*"
    MatchDevicePath "/dev/input/event*"
    Option "TransformationMatrix" "-1 0 1 0 -1 1 0 0 1"
EndSection
EOF

log "✅ Touch calibration updated"
info "Matrix changed from '0 -1 1 1 0 0 0 0 1' (90° CCW) to '-1 0 1 0 -1 1 0 0 1' (180° rotation - fixes both left/right AND top/bottom swap)"
echo ""
info "To apply changes, restart X11:"
echo "  sudo systemctl restart localdisplay.service"
echo ""
info "Or reboot:"
echo "  sudo reboot"
echo ""
info "If this doesn't fix it, try these alternatives:"
echo "  Matrix 1 (180° rotation - both axes): '-1 0 1 0 -1 1 0 0 1'"
echo "  Matrix 2 (270° rotation): '0 1 0 -1 0 1 0 0 1'"
echo "  Matrix 3 (90° CCW - original): '0 -1 1 1 0 0 0 0 1'"
