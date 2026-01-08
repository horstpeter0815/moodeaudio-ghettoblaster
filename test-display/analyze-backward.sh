#!/bin/bash
################################################################################
#
# BACKWARD ANALYSIS (CHROMIUM → BOOT)
#
# Traces backwards from Chromium:
# 1. Chromium window size → X11 screen size
# 2. X11 screen size → xrandr configuration
# 3. xrandr configuration → DRM plane state
# 4. DRM plane state → Framebuffer size
# 5. Framebuffer size → Boot configuration
#
################################################################################

set -e

LOG_FILE="${1:-/var/log/display-chain/chain.log}"
OUTPUT_DIR="${2:-/var/log/display-chain/backward-analysis}"

mkdir -p "$OUTPUT_DIR"

echo "=== BACKWARD ANALYSIS (CHROMIUM → BOOT) ==="
echo "Log file: $LOG_FILE"
echo "Output directory: $OUTPUT_DIR"
echo ""

# Step 1: Chromium window size → X11 screen size
echo "Step 1: Chromium window size → X11 screen size"
CHROMIUM_SIZE=$(jq -r 'select(.layer == "chromium" and .event_type == "ready") | .data.size' "$LOG_FILE" | head -1 || echo "")
X11_SIZE=$(jq -r 'select(.layer == "x11" and .event_type == "ready") | .data.resolution' "$LOG_FILE" | head -1 || echo "")
X11_ROTATION=$(jq -r 'select(.layer == "xrandr" and .event_type == "ready") | .data.rotation' "$LOG_FILE" | head -1 || echo "")
echo "  Chromium window: $CHROMIUM_SIZE"
echo "  X11 screen: $X11_SIZE (rotation: $X11_ROTATION)"
if [ "$X11_ROTATION" != "normal" ]; then
    echo "  ✅ Chromium window will be rotated by X11"
else
    if [ "$CHROMIUM_SIZE" = "$X11_SIZE" ]; then
        echo "  ✅ Match"
    else
        echo "  ❌ Mismatch"
    fi
fi
echo ""

# Step 2: X11 screen size → xrandr configuration
echo "Step 2: X11 screen size → xrandr configuration"
XRANDR_MODE=$(jq -r 'select(.layer == "xrandr" and .event_type == "config") | .data.mode' "$LOG_FILE" | head -1 || echo "")
XRANDR_ROTATION=$(jq -r 'select(.layer == "xrandr" and .event_type == "ready") | .data.rotation' "$LOG_FILE" | head -1 || echo "")
echo "  X11 screen: $X11_SIZE"
echo "  xrandr mode: $XRANDR_MODE"
echo "  xrandr rotation: $XRANDR_ROTATION"
if [ "$XRANDR_ROTATION" = "left" ] || [ "$XRANDR_ROTATION" = "right" ]; then
    echo "  ✅ Rotation configured (Forum solution)"
else
    echo "  ⚠️  No rotation configured"
fi
echo ""

# Step 3: xrandr configuration → DRM plane state
echo "Step 3: xrandr configuration → DRM plane state"
DRM_SIZE=$(jq -r 'select(.layer == "drm" and .event_type == "ready") | .data.size' "$LOG_FILE" | head -1 || echo "")
echo "  xrandr mode: $XRANDR_MODE"
echo "  DRM plane: $DRM_SIZE"
if [ "$XRANDR_MODE" = "$DRM_SIZE" ]; then
    echo "  ✅ xrandr matches DRM plane"
else
    echo "  ❌ Mismatch"
fi
echo ""

# Step 4: DRM plane state → Framebuffer size
echo "Step 4: DRM plane state → Framebuffer size"
FB_SIZE=$(jq -r 'select(.layer == "framebuffer" and .event_type == "ready") | .data.size' "$LOG_FILE" | head -1 || echo "")
echo "  DRM plane: $DRM_SIZE"
echo "  Framebuffer: $FB_SIZE"
if [ "$DRM_SIZE" = "$FB_SIZE" ]; then
    echo "  ✅ Synchronized"
else
    echo "  ❌ Mismatch detected"
fi
echo ""

# Step 5: Framebuffer size → Boot configuration
echo "Step 5: Framebuffer size → Boot configuration"
BOOT_CONFIG=$(jq -r 'select(.layer == "boot" and .event_type == "config") | .data' "$LOG_FILE" | head -1 || echo "{}")
BOOT_HDMI_CVT=$(echo "$BOOT_CONFIG" | jq -r '.hdmi_cvt // empty' || echo "")
BOOT_VIDEO=$(echo "$BOOT_CONFIG" | jq -r '.video // empty' || echo "")
echo "  Framebuffer: $FB_SIZE"
echo "  Boot hdmi_cvt: $BOOT_HDMI_CVT"
echo "  Boot video: $BOOT_VIDEO"
if echo "$BOOT_HDMI_CVT" | grep -q "$FB_SIZE" || echo "$BOOT_VIDEO" | grep -q "$FB_SIZE"; then
    echo "  ✅ Boot config matches framebuffer"
else
    echo "  ⚠️  Boot config may not match framebuffer"
fi
echo ""

# Generate backward analysis report
cat > "$OUTPUT_DIR/backward-analysis.txt" << EOF
Backward Analysis Report (Chromium → Boot)
==========================================

1. Chromium Window → X11 Screen
   Chromium window: $CHROMIUM_SIZE
   X11 screen: $X11_SIZE
   Rotation: $X11_ROTATION
   Status: $(if [ "$X11_ROTATION" != "normal" ]; then echo "✅ Will be rotated"; else echo "$([ "$CHROMIUM_SIZE" = "$X11_SIZE" ] && echo "✅ Match" || echo "❌ Mismatch")"; fi)

2. X11 Screen → xrandr Configuration
   X11 screen: $X11_SIZE
   xrandr mode: $XRANDR_MODE
   xrandr rotation: $XRANDR_ROTATION
   Status: $(if [ "$XRANDR_ROTATION" != "normal" ]; then echo "✅ Rotation configured"; else echo "⚠️  No rotation"; fi)

3. xrandr Configuration → DRM Plane
   xrandr mode: $XRANDR_MODE
   DRM plane: $DRM_SIZE
   Status: $(if [ "$XRANDR_MODE" = "$DRM_SIZE" ]; then echo "✅ Match"; else echo "❌ Mismatch"; fi)

4. DRM Plane → Framebuffer
   DRM plane: $DRM_SIZE
   Framebuffer: $FB_SIZE
   Status: $(if [ "$DRM_SIZE" = "$FB_SIZE" ]; then echo "✅ Synchronized"; else echo "❌ Mismatch"; fi)

5. Framebuffer → Boot Configuration
   Framebuffer: $FB_SIZE
   Boot hdmi_cvt: $BOOT_HDMI_CVT
   Boot video: $BOOT_VIDEO
   Status: $(if echo "$BOOT_HDMI_CVT" | grep -q "$FB_SIZE" || echo "$BOOT_VIDEO" | grep -q "$FB_SIZE"; then echo "✅ Match"; else echo "⚠️  May not match"; fi)

EOF

cat "$OUTPUT_DIR/backward-analysis.txt"
echo ""
echo "Backward analysis complete. Report saved to: $OUTPUT_DIR/backward-analysis.txt"

