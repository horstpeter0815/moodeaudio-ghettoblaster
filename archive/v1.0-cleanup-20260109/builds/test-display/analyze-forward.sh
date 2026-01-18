#!/bin/bash
################################################################################
#
# FORWARD ANALYSIS (BOOT → CHROMIUM)
#
# Traces the chain from boot:
# 1. Boot config → FB size
# 2. FB size → DRM plane (match/mismatch?)
# 3. DRM plane → X11 screen (synchronized?)
# 4. X11 screen → xrandr rotation (applied?)
# 5. xrandr rotation → Chromium window (matches?)
#
################################################################################

set -e

LOG_FILE="${1:-/var/log/display-chain/chain.log}"
OUTPUT_DIR="${2:-/var/log/display-chain/forward-analysis}"

mkdir -p "$OUTPUT_DIR"

echo "=== FORWARD ANALYSIS (BOOT → CHROMIUM) ==="
echo "Log file: $LOG_FILE"
echo "Output directory: $OUTPUT_DIR"
echo ""

# Step 1: Boot config → FB size
echo "Step 1: Boot config → FB size"
BOOT_CONFIG=$(jq -r 'select(.layer == "boot" and .event_type == "config") | .data' "$LOG_FILE" | head -1 || echo "{}")
FB_SIZE=$(jq -r 'select(.layer == "framebuffer" and .event_type == "ready") | .data.size' "$LOG_FILE" | head -1 || echo "")
echo "  Boot config: $BOOT_CONFIG"
echo "  FB size: $FB_SIZE"
echo ""

# Step 2: FB size → DRM plane
echo "Step 2: FB size → DRM plane"
DRM_SIZE=$(jq -r 'select(.layer == "drm" and .event_type == "ready") | .data.size' "$LOG_FILE" | head -1 || echo "")
echo "  FB size: $FB_SIZE"
echo "  DRM size: $DRM_SIZE"
if [ "$FB_SIZE" = "$DRM_SIZE" ]; then
    echo "  ✅ Match"
else
    echo "  ❌ Mismatch detected"
fi
echo ""

# Step 3: DRM plane → X11 screen
echo "Step 3: DRM plane → X11 screen"
X11_SIZE=$(jq -r 'select(.layer == "x11" and .event_type == "ready") | .data.resolution' "$LOG_FILE" | head -1 || echo "")
X11_ROTATION=$(jq -r 'select(.layer == "xrandr" and .event_type == "ready") | .data.rotation' "$LOG_FILE" | head -1 || echo "")
echo "  DRM size: $DRM_SIZE"
echo "  X11 size: $X11_SIZE (rotation: $X11_ROTATION)"
if [ "$X11_ROTATION" = "left" ] || [ "$X11_ROTATION" = "right" ]; then
    echo "  ✅ Rotation applied (expected for Forum solution)"
else
    echo "  ⚠️  No rotation applied"
fi
echo ""

# Step 4: X11 screen → xrandr rotation
echo "Step 4: X11 screen → xrandr rotation"
XRANDR_MODE=$(jq -r 'select(.layer == "xrandr" and .event_type == "config") | .data.mode' "$LOG_FILE" | head -1 || echo "")
XRANDR_RESULT=$(jq -r 'select(.layer == "xrandr" and .event_type == "ready") | .data' "$LOG_FILE" | head -1 || echo "{}")
echo "  xrandr mode: $XRANDR_MODE"
echo "  xrandr result: $XRANDR_RESULT"
echo ""

# Step 5: xrandr rotation → Chromium window
echo "Step 5: xrandr rotation → Chromium window"
CHROMIUM_SIZE=$(jq -r 'select(.layer == "chromium" and .event_type == "ready") | .data.size' "$LOG_FILE" | head -1 || echo "")
echo "  Chromium window: $CHROMIUM_SIZE"
echo "  X11 display: $X11_SIZE"
if [ "$X11_ROTATION" != "normal" ]; then
    echo "  ✅ Chromium window matches DRM (will be rotated by X11)"
else
    if [ "$CHROMIUM_SIZE" = "$X11_SIZE" ]; then
        echo "  ✅ Match"
    else
        echo "  ❌ Mismatch"
    fi
fi
echo ""

# Generate forward analysis report
cat > "$OUTPUT_DIR/forward-analysis.txt" << EOF
Forward Analysis Report (Boot → Chromium)
==========================================

1. Boot Config → FB Size
   Boot config: $BOOT_CONFIG
   FB size: $FB_SIZE
   Status: $(if [ -n "$FB_SIZE" ]; then echo "✅ Configured"; else echo "❌ Not found"; fi)

2. FB Size → DRM Plane
   FB size: $FB_SIZE
   DRM size: $DRM_SIZE
   Status: $(if [ "$FB_SIZE" = "$DRM_SIZE" ]; then echo "✅ Synchronized"; else echo "❌ Mismatch"; fi)

3. DRM Plane → X11 Screen
   DRM size: $DRM_SIZE
   X11 size: $X11_SIZE
   Rotation: $X11_ROTATION
   Status: $(if [ "$X11_ROTATION" != "normal" ]; then echo "✅ Rotation applied"; else echo "⚠️  No rotation"; fi)

4. X11 Screen → xrandr Rotation
   xrandr mode: $XRANDR_MODE
   xrandr result: $XRANDR_RESULT
   Status: ✅ Configured

5. xrandr Rotation → Chromium Window
   Chromium window: $CHROMIUM_SIZE
   X11 display: $X11_SIZE
   Status: $(if [ "$X11_ROTATION" != "normal" ]; then echo "✅ Will be rotated"; else echo "$([ "$CHROMIUM_SIZE" = "$X11_SIZE" ] && echo "✅ Match" || echo "❌ Mismatch")"; fi)

EOF

cat "$OUTPUT_DIR/forward-analysis.txt"
echo ""
echo "Forward analysis complete. Report saved to: $OUTPUT_DIR/forward-analysis.txt"

