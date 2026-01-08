#!/bin/bash
################################################################################
#
# Apply Display Inversion (Horizontal/Vertical)
# 
# This script applies horizontal or vertical inversion to the display
# BEFORE PeppyMeter starts, or can be run while PeppyMeter is running.
#
################################################################################

echo "=== APPLY DISPLAY INVERSION ==="

# Wait for X11 to be ready
MAX_WAIT=30
WAITED=0
while [ $WAITED -lt $MAX_WAIT ]; do
    if [ -S /tmp/.X11-unix/X0 ] && DISPLAY=:0 xdpyinfo >/dev/null 2>&1; then
        echo "✅ X11 is ready"
        break
    fi
    sleep 1
    WAITED=$((WAITED + 1))
done

if [ $WAITED -ge $MAX_WAIT ]; then
    echo "⚠️  X11 not ready after $MAX_WAIT seconds"
    exit 1
fi

# Get current display state
CURRENT_DIM=$(DISPLAY=:0 xdpyinfo 2>/dev/null | grep dimensions | grep -oE '[0-9]+x[0-9]+' | head -1)
HDMI_OUTPUT=$(DISPLAY=:0 xrandr 2>/dev/null | grep " connected" | head -1 | awk '{print $1}' || echo "HDMI-1")

echo "Current display: $CURRENT_DIM"
echo "HDMI output: $HDMI_OUTPUT"
echo ""

# Check if inversion is requested
# Options: horizontal (x), vertical (y), both (xy)
INVERSION_TYPE="${1:-horizontal}"

case "$INVERSION_TYPE" in
    horizontal|x)
        echo "Applying horizontal inversion (reflect x)..."
        DISPLAY=:0 xrandr --output "$HDMI_OUTPUT" --reflect x 2>&1
        echo "✅ Horizontal inversion applied"
        ;;
    vertical|y)
        echo "Applying vertical inversion (reflect y)..."
        DISPLAY=:0 xrandr --output "$HDMI_OUTPUT" --reflect y 2>&1
        echo "✅ Vertical inversion applied"
        ;;
    both|xy)
        echo "Applying both horizontal and vertical inversion (reflect xy)..."
        DISPLAY=:0 xrandr --output "$HDMI_OUTPUT" --reflect xy 2>&1
        echo "✅ Both inversions applied"
        ;;
    normal|none|reset)
        echo "Resetting inversion (normal)..."
        DISPLAY=:0 xrandr --output "$HDMI_OUTPUT" --reflect normal 2>&1
        echo "✅ Inversion reset"
        ;;
    *)
        echo "Usage: $0 [horizontal|x|vertical|y|both|xy|normal|none|reset]"
        echo ""
        echo "Options:"
        echo "  horizontal or x  - Flip horizontally (left ↔ right)"
        echo "  vertical or y    - Flip vertically (top ↔ bottom)"
        echo "  both or xy       - Flip both ways"
        echo "  normal or reset  - Remove inversion"
        exit 1
        ;;
esac

sleep 1

# Verify
FINAL_DIM=$(DISPLAY=:0 xdpyinfo 2>/dev/null | grep dimensions | grep -oE '[0-9]+x[0-9]+' | head -1)
echo ""
echo "=== FINAL STATE ==="
echo "Display dimensions: $FINAL_DIM"
DISPLAY=:0 xrandr 2>/dev/null | grep "$HDMI_OUTPUT" | head -1

echo ""
echo "✅ Display inversion applied"










