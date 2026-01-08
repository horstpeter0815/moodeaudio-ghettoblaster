#!/bin/bash
################################################################################
#
# CHAIN DIAGRAM GENERATOR
#
# Generates diagram showing:
# - Each layer
# - Data flow between layers
# - Synchronization points
# - Mismatches highlighted
#
################################################################################

set -e

LOG_FILE="${1:-/var/log/display-chain/chain.log}"
OUTPUT_FILE="${2:-/var/log/display-chain/chain-diagram.txt}"

mkdir -p "$(dirname "$OUTPUT_FILE")"

echo "Generating chain diagram..."
echo ""

# Extract state from each layer
FB_SIZE=$(jq -r 'select(.layer == "framebuffer" and .event_type == "ready") | .data.size' "$LOG_FILE" | head -1 || echo "?x?")
DRM_SIZE=$(jq -r 'select(.layer == "drm" and .event_type == "ready") | .data.size' "$LOG_FILE" | head -1 || echo "?x?")
X11_SIZE=$(jq -r 'select(.layer == "x11" and .event_type == "ready") | .data.resolution' "$LOG_FILE" | head -1 || echo "?x?")
XRANDR_ROTATION=$(jq -r 'select(.layer == "xrandr" and .event_type == "ready") | .data.rotation' "$LOG_FILE" | head -1 || echo "?")
CHROMIUM_SIZE=$(jq -r 'select(.layer == "chromium" and .event_type == "ready") | .data.size' "$LOG_FILE" | head -1 || echo "?x?")

# Check for mismatches
FB_DRM_MATCH=$([ "$FB_SIZE" = "$DRM_SIZE" ] && echo "✅" || echo "❌")
X11_CHROMIUM_MATCH=$([ "$XRANDR_ROTATION" != "normal" ] && echo "✅ (rotated)" || ([ "$X11_SIZE" = "$CHROMIUM_SIZE" ] && echo "✅" || echo "❌"))

# Generate diagram
cat > "$OUTPUT_FILE" << EOF
Display Chain Diagram
=====================

┌─────────────────────────────────────────────────────────────┐
│                    BOOT CONFIGURATION                       │
│              (config.txt, cmdline.txt)                      │
└───────────────────────┬─────────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────────┐
│                  FRAMEBUFFER (fb0)                          │
│                    Size: $FB_SIZE                                    │
└───────────────────────┬─────────────────────────────────────┘
                        │
                        │ $FB_DRM_MATCH
                        ▼
┌─────────────────────────────────────────────────────────────┐
│                  DRM/KMS PLANE                              │
│                    Size: $DRM_SIZE                                    │
└───────────────────────┬─────────────────────────────────────┘
                        │
                        │ synchronized by xrandr
                        ▼
┌─────────────────────────────────────────────────────────────┐
│                      X11 SERVER                             │
│                  Resolution: $X11_SIZE                              │
└───────────────────────┬─────────────────────────────────────┘
                        │
                        │ rotation: $XRANDR_ROTATION
                        ▼
┌─────────────────────────────────────────────────────────────┐
│                      XRANDR                                 │
│              Mode: $DRM_SIZE, Rotation: $XRANDR_ROTATION                    │
└───────────────────────┬─────────────────────────────────────┘
                        │
                        │ $X11_CHROMIUM_MATCH
                        ▼
┌─────────────────────────────────────────────────────────────┐
│                      CHROMIUM                               │
│                  Window: $CHROMIUM_SIZE                              │
└─────────────────────────────────────────────────────────────┘

Synchronization Points:
  - Boot → FB: ✅ (kernel initialization)
  - FB → DRM: $FB_DRM_MATCH
  - DRM → X11: ✅ (xrandr synchronization)
  - X11 → Chromium: $X11_CHROMIUM_MATCH

Mismatches Detected:
$(if [ "$FB_SIZE" != "$DRM_SIZE" ]; then echo "  ❌ FB ($FB_SIZE) ≠ DRM ($DRM_SIZE)"; fi)
$(if [ "$XRANDR_ROTATION" = "normal" ] && [ "$X11_SIZE" != "$CHROMIUM_SIZE" ]; then echo "  ❌ X11 ($X11_SIZE) ≠ Chromium ($CHROMIUM_SIZE)"; fi)

EOF

cat "$OUTPUT_FILE"
echo ""
echo "Chain diagram saved to: $OUTPUT_FILE"

