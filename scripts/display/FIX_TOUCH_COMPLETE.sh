#!/bin/bash
################################################################################
#
# Complete Touch Fix
#
# Fixes touch calibration by:
# 1. Finding the correct touch device
# 2. Testing different matrices
# 3. Applying the correct one
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
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
info() { echo -e "${BLUE}[INFO]${NC} $1"; }

# Check if running on Pi
if [ ! -d "/proc" ] || ! command -v xinput >/dev/null 2>&1; then
    error "Must run on Pi with X11"
    exit 1
fi

TOUCH_CONF="/etc/X11/xorg.conf.d/99-touch-calibration.conf"

log "=== Complete Touch Fix ==="

# Step 1: Find touch device
log "Step 1: Finding touch device..."
xinput list
echo ""

TOUCH_DEVICE=$(xinput list | grep -iE "touch|waveshare|ft6236|focaltech" | head -1 | sed 's/.*id=\([0-9]*\).*/\1/' || echo "")

if [ -z "$TOUCH_DEVICE" ]; then
    error "Touch device not found!"
    echo ""
    info "Available input devices:"
    xinput list
    echo ""
    warn "Try:"
    echo "  1. Check if touchscreen is connected"
    echo "  2. Check dmesg: dmesg | grep -i touch"
    echo "  3. Check if device tree overlay is loaded"
    exit 1
fi

TOUCH_NAME=$(xinput list --name-only "$TOUCH_DEVICE" 2>/dev/null || echo "Unknown")
log "✅ Found touch device: $TOUCH_NAME (ID: $TOUCH_DEVICE)"

# Step 2: Check current matrix
log "Step 2: Checking current matrix..."
CURRENT_MATRIX=$(xinput list-props "$TOUCH_DEVICE" 2>/dev/null | grep "Coordinate Transformation Matrix" | sed 's/.*matrix\[\(.*\)\].*/\1/' || echo "")
if [ -n "$CURRENT_MATRIX" ]; then
    info "Current matrix: $CURRENT_MATRIX"
else
    info "No matrix set (using identity)"
fi

# Step 3: Try common matrices
log "Step 3: Testing common matrices..."

MATRICES=(
    "-1 0 1 0 -1 1 0 0 1|180° rotation (both axes)"
    "0 -1 1 1 0 0 0 0 1|90° CCW rotation"
    "0 1 0 -1 0 1 0 0 1|270° rotation (90° CW)"
    "-1 0 1 0 1 0 0 0 1|Horizontal flip (X axis)"
    "1 0 0 0 -1 1 0 0 1|Vertical flip (Y axis)"
    "1 0 0 0 1 0 0 0 1|No transformation"
)

echo ""
warn "We'll test matrices. After each, try touching the screen."
warn "Tell me which one works (or 'none' if none work)."
echo ""

for i in "${!MATRICES[@]}"; do
    IFS='|' read -r matrix description <<< "${MATRICES[$i]}"
    num=$((i + 1))
    
    echo ""
    info "Matrix $num: $description"
    info "Values: $matrix"
    
    xinput set-prop "$TOUCH_DEVICE" "Coordinate Transformation Matrix" $matrix 2>/dev/null || {
        error "Failed to set matrix"
        continue
    }
    
    read -p "Does touch work correctly? (y/n): " answer
    
    if [[ "$answer" =~ ^[Yy] ]]; then
        log "✅ Matrix $num works! Saving..."
        
        # Update config with broader match
        sudo mkdir -p /etc/X11/xorg.conf.d/
        sudo tee "$TOUCH_CONF" > /dev/null << EOF
Section "InputClass"
    Identifier "Touchscreen Calibration"
    MatchProduct "*"
    MatchDevicePath "/dev/input/event*"
    Option "TransformationMatrix" "$matrix"
EndSection
EOF
        
        log "✅ Configuration saved!"
        info "File: $TOUCH_CONF"
        info "Matrix: $matrix"
        echo ""
        info "To apply permanently, restart X11:"
        echo "  sudo systemctl restart localdisplay.service"
        exit 0
    fi
done

# If we get here, try the most common fix
warn "No matrix worked in interactive test."
info "Applying most common fix (180° rotation)..."

MATRIX="-1 0 1 0 -1 1 0 0 1"
xinput set-prop "$TOUCH_DEVICE" "Coordinate Transformation Matrix" $MATRIX

sudo mkdir -p /etc/X11/xorg.conf.d/
sudo tee "$TOUCH_CONF" > /dev/null << EOF
Section "InputClass"
    Identifier "Touchscreen Calibration"
    MatchProduct "*"
    MatchDevicePath "/dev/input/event*"
    Option "TransformationMatrix" "$MATRIX"
EndSection
EOF

log "✅ Applied default matrix: $MATRIX"
info "Test touch now. If it doesn't work, run the interactive test:"
echo "  cd ~/moodeaudio-cursor && sudo bash scripts/display/TEST_TOUCH_MATRICES.sh"
