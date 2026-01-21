#!/bin/bash
# Quick script to try a specific touch matrix
# Usage: sudo bash TRY_TOUCH_MATRIX.sh "matrix_string"

MATRIX="${1:-"-1 0 1 0 1 0 0 0 1"}"

echo "=== Trying Touch Matrix ==="
echo "Matrix: $MATRIX"
echo ""

sudo mkdir -p /etc/X11/xorg.conf.d/
sudo tee /etc/X11/xorg.conf.d/99-touch-calibration.conf > /dev/null << EOF
Section "InputClass"
    Identifier "Touchscreen Calibration"
    MatchProduct "*"
    MatchDevicePath "/dev/input/event*"
    Option "TransformationMatrix" "$MATRIX"
EndSection
EOF

echo "✅ Applied matrix"
echo "Restarting X11..."
sudo systemctl restart localdisplay.service 2>/dev/null || echo "⚠️  Restart failed"
echo ""
echo "Please test touch input now"
