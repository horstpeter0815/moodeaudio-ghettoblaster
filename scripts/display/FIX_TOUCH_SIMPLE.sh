#!/bin/bash
# Simple Touch Fix - Tests different matrices

log() { echo -e "\033[0;32m[TOUCH]\033[0m $1"; }

# Find touch device
TOUCH_DEVICE=$(xinput list | grep -iE "touch|waveshare|ft6236" | head -1 | sed 's/.*id=\([0-9]*\).*/\1/' || echo "")
if [ -z "$TOUCH_DEVICE" ]; then
    echo "Touch device not found"
    exit 1
fi

TOUCH_NAME=$(xinput list --name-only "$TOUCH_DEVICE" 2>/dev/null || echo "Unknown")
log "Touch device: $TOUCH_NAME (ID: $TOUCH_DEVICE)"
echo ""

# Try different matrices
MATRICES=(
    "1 0 0 0 1 0 0 0 1|No transformation"
    "-1 0 1 0 -1 1 0 0 1|180° rotation (both axes)"
    "0 -1 1 1 0 0 0 0 1|90° CCW rotation"
    "0 1 0 -1 0 1 0 0 1|270° rotation (90° CW)"
    "-1 0 1 0 1 0 0 0 1|Horizontal flip (X axis)"
    "1 0 0 0 -1 1 0 0 1|Vertical flip (Y axis)"
    "0 1 0 1 0 0 0 0 1|Swap X/Y axes"
)

log "Testing matrices. Try touching screen after each..."
echo ""

for i in "${!MATRICES[@]}"; do
    IFS='|' read -r matrix desc <<< "${MATRICES[$i]}"
    num=$((i + 1))
    
    echo "Matrix $num: $desc"
    echo "  Values: $matrix"
    xinput set-prop "$TOUCH_DEVICE" "Coordinate Transformation Matrix" $matrix 2>/dev/null || continue
    
    read -p "  Does touch work correctly? (y/n): " answer
    if [[ "$answer" =~ ^[Yy] ]]; then
        log "✅ Matrix $num works! Saving..."
        sudo mkdir -p /etc/X11/xorg.conf.d/
        sudo tee /etc/X11/xorg.conf.d/99-touch-calibration.conf > /dev/null << EOF
Section "InputClass"
    Identifier "Touchscreen Calibration"
    MatchProduct "*"
    MatchDevicePath "/dev/input/event*"
    Option "TransformationMatrix" "$matrix"
EndSection
EOF
        log "✅ Saved to /etc/X11/xorg.conf.d/99-touch-calibration.conf"
        log "Restart X11: sudo systemctl restart localdisplay.service"
        exit 0
    fi
done

log "No matrix worked. Current matrix saved as fallback."
