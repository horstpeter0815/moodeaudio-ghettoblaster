#!/bin/bash
################################################################################
#
# Test Touch Calibration Matrices
#
# Tries different transformation matrices to find the correct one
# Tests each matrix and lets user verify if touch works correctly
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

log() { echo -e "${GREEN}[TEST]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
info() { echo -e "${BLUE}[INFO]${NC} $1"; }

# Check if running on Pi
if [ ! -d "/proc" ] || ! command -v xinput >/dev/null 2>&1; then
    error "Must run on Pi with X11"
    exit 1
fi

TOUCH_CONF="/etc/X11/xorg.conf.d/99-touch-calibration.conf"
BACKUP_CONF="${TOUCH_CONF}.backup.$(date +%Y%m%d_%H%M%S)"

# Backup existing config
if [ -f "$TOUCH_CONF" ]; then
    log "Backing up existing config to $BACKUP_CONF"
    sudo cp "$TOUCH_CONF" "$BACKUP_CONF"
fi

# Find touch device
log "Finding touch device..."
TOUCH_DEVICE=$(xinput list | grep -i "touch\|waveshare\|ft6236" | head -1 | sed 's/.*id=\([0-9]*\).*/\1/' || echo "")

if [ -z "$TOUCH_DEVICE" ]; then
    error "Touch device not found!"
    echo ""
    info "Available input devices:"
    xinput list
    exit 1
fi

TOUCH_NAME=$(xinput list --name-only "$TOUCH_DEVICE" 2>/dev/null || echo "Unknown")
log "Found touch device: $TOUCH_NAME (ID: $TOUCH_DEVICE)"

# Matrix definitions
declare -A MATRICES=(
    ["1"]="0 -1 1 1 0 0 0 0 1|90° CCW rotation (original)"
    ["2"]="0 1 0 -1 0 1 0 0 1|270° rotation (90° CW)"
    ["3"]="-1 0 1 0 -1 1 0 0 1|180° rotation (both axes flipped)"
    ["4"]="-1 0 1 0 1 0 0 0 1|Horizontal flip only (X axis)"
    ["5"]="1 0 0 0 -1 1 0 0 1|Vertical flip only (Y axis)"
    ["6"]="1 0 0 0 1 0 0 0 1|No transformation (identity)"
    ["7"]="0 1 0 1 0 0 0 0 1|Swap X/Y axes"
)

echo ""
log "=== Touch Matrix Testing ==="
echo ""
info "We'll test different transformation matrices."
info "After each test, try touching the screen and tell me if it works correctly."
echo ""
info "Current touch device: $TOUCH_NAME"
info "Current matrix:"
xinput list-props "$TOUCH_DEVICE" 2>/dev/null | grep TransformationMatrix || echo "  Not set"
echo ""

# Test each matrix
for key in "${!MATRICES[@]}"; do
    IFS='|' read -r matrix description <<< "${MATRICES[$key]}"
    
    echo ""
    log "Testing Matrix $key: $description"
    info "Matrix: $matrix"
    
    # Apply matrix via xinput (temporary, for testing)
    xinput set-prop "$TOUCH_DEVICE" "Coordinate Transformation Matrix" $matrix 2>/dev/null || {
        error "Failed to set matrix"
        continue
    }
    
    info "✅ Matrix applied (temporary)"
    echo ""
    warn "TEST NOW: Try touching different areas of the screen"
    warn "  - Top-left corner"
    warn "  - Top-right corner"
    warn "  - Bottom-left corner"
    warn "  - Bottom-right corner"
    warn "  - Center"
    echo ""
    read -p "Does touch work correctly? (y/n/skip): " answer
    
    case "$answer" in
        y|Y|yes|YES)
            log "✅ Matrix $key works! Saving configuration..."
            
            # Update config file
            sudo tee "$TOUCH_CONF" > /dev/null << EOF
Section "InputClass"
    Identifier "WaveShare Touchscreen"
    MatchProduct "*"
    Option "TransformationMatrix" "$matrix"
EndSection
EOF
            
            # Also set via xinput for immediate effect
            xinput set-prop "$TOUCH_DEVICE" "Coordinate Transformation Matrix" $matrix
            
            log "✅ Configuration saved!"
            echo ""
            info "Matrix saved to: $TOUCH_CONF"
            info "To make permanent, restart X11: sudo systemctl restart localdisplay.service"
            echo ""
            exit 0
            ;;
        n|N|no|NO)
            info "Matrix $key doesn't work, trying next..."
            ;;
        s|S|skip|SKIP)
            info "Skipping remaining tests..."
            break
            ;;
        *)
            warn "Invalid answer, trying next matrix..."
            ;;
    esac
done

# If we get here, no matrix worked
echo ""
warn "No matrix worked correctly."
info "Restoring original configuration..."
if [ -f "$BACKUP_CONF" ]; then
    sudo cp "$BACKUP_CONF" "$TOUCH_CONF"
    log "Original config restored"
fi

echo ""
info "Troubleshooting:"
echo "  1. Check touch device name: xinput list"
echo "  2. Check current matrix: xinput list-props <device-id> | grep TransformationMatrix"
echo "  3. Try manual matrix: xinput set-prop <device-id> 'Coordinate Transformation Matrix' <matrix>"
echo "  4. Check X11 logs: journalctl -u localdisplay.service -n 50"

exit 1
