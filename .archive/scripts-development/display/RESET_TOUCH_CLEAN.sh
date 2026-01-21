#!/bin/bash
################################################################################
#
# Reset Touch to Clean State
#
# Removes all transformations and starts fresh
#
################################################################################

set -euo pipefail

log() { echo -e "\033[0;32m[RESET]${NC} $1"; }

log "=== Resetting Touch to Clean State ==="

sudo mkdir -p /etc/X11/xorg.conf.d/

# Remove touch calibration (no transformation)
sudo tee /etc/X11/xorg.conf.d/99-touch-calibration.conf > /dev/null << 'EOF'
Section "InputClass"
    Identifier "Touchscreen Calibration"
    MatchProduct "*"
    MatchDevicePath "/dev/input/event*"
    Option "TransformationMatrix" "1 0 0 0 1 0 0 0 1"
EndSection
EOF

log "✅ Reset to no transformation (identity matrix)"
log "Matrix: 1 0 0 0 1 0 0 0 1"
echo ""
log "Restarting X11..."
sudo systemctl restart localdisplay.service 2>/dev/null || echo "⚠️  Restart failed"
echo ""
log "✅ Touch reset - test now and tell me what's wrong"
log "Then we can apply the correct fix"
