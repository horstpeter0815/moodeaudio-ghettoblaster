#!/bin/bash
# TEST TOUCHSCREEN MATRICES
# Run this on Pi 5 to test different calibration matrices

set -e

echo "=========================================="
echo "TOUCHSCREEN MATRIX TESTER"
echo "=========================================="
echo ""
echo "This script will test different calibration matrices."
echo "Touch the screen after each matrix and tell me which one works!"
echo ""

ssh pi2 << 'TESTMATRICES'
export DISPLAY=:0

WAVESHARE_ID=$(xinput list | grep -i "WaveShare" | grep -oP 'id=\K[0-9]+' | head -1)

if [ -z "$WAVESHARE_ID" ]; then
    echo "❌ WaveShare device not found"
    exit 1
fi

echo "WaveShare device ID: $WAVESHARE_ID"
echo ""

# Matrix options
declare -A MATRICES=(
    ["1"]="1 0 0 0 1 0 0 0 1:0° (no rotation)"
    ["2"]="0 1 0 -1 0 1 0 0 1:90° counter-clockwise"
    ["3"]="-1 0 1 0 -1 1 0 0 1:180° (both axes inverted)"
    ["4"]="0 -1 1 1 0 0 0 0 1:270° counter-clockwise (moOde default)"
    ["5"]="0 -1 1 -1 0 1 0 0 1:270° with Y inversion"
    ["6"]="1 0 0 0 -1 1 0 0 1:Y axis inverted only"
    ["7"]="-1 0 1 0 1 0 0 0 1:X axis inverted only"
)

for KEY in "${!MATRICES[@]}"; do
    MATRIX_INFO="${MATRICES[$KEY]}"
    MATRIX=$(echo "$MATRIX_INFO" | cut -d: -f1)
    DESC=$(echo "$MATRIX_INFO" | cut -d: -f2)
    
    echo "=========================================="
    echo "Option $KEY: $DESC"
    echo "Matrix: $MATRIX"
    echo "=========================================="
    
    xinput set-prop "$WAVESHARE_ID" "Coordinate Transformation Matrix" $MATRIX
    
    echo ""
    echo "Matrix set. Touch the screen now..."
    echo "Does the cursor move correctly? (Y/N)"
    echo ""
    read -t 10 -p "Press Y if it works, N if not: " ANSWER || ANSWER="N"
    
    if [ "$ANSWER" = "Y" ] || [ "$ANSWER" = "y" ]; then
        echo ""
        echo "✅ FOUND WORKING MATRIX!"
        echo "Matrix: $MATRIX"
        echo "Description: $DESC"
        echo ""
        echo "Saving to .xinitrc..."
        
        # Update .xinitrc
        if ! grep -q "xinput set-prop.*WaveShare.*Coordinate Transformation Matrix" /home/andre/.xinitrc 2>/dev/null; then
            sed -i '/chromium-browser/i\
# Touchscreen calibration (after Touch Rotation button)\
WAVESHARE_ID=$(xinput list | grep -i "WaveShare" | grep -oP '\''id=\\K[0-9]+'\'' | head -1)\
if [ -n "$WAVESHARE_ID" ]; then\
    xinput set-prop "$WAVESHARE_ID" "Coordinate Transformation Matrix" '"$MATRIX"' 2>/dev/null || true\
fi' /home/andre/.xinitrc
        else
            # Replace existing matrix
            sed -i "s/xinput set-prop \"\$WAVESHARE_ID\" \"Coordinate Transformation Matrix\" .*/xinput set-prop \"\$WAVESHARE_ID\" \"Coordinate Transformation Matrix\" $MATRIX 2\/dev\/null || true/" /home/andre/.xinitrc
        fi
        
        echo "✅ Saved to .xinitrc"
        echo ""
        echo "This matrix will be applied automatically on boot!"
        exit 0
    fi
    
    echo ""
done

echo ""
echo "❌ No working matrix found"
echo "Please check:"
echo "  1. Is Send Events Mode enabled?"
echo "  2. Is the device enabled?"
echo "  3. Try pressing the Touch Rotation button again"

TESTMATRICES

echo ""
echo "✅ Test complete!"

