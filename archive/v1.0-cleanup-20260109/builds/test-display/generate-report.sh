#!/bin/bash
################################################################################
#
# REPORT GENERATOR
#
# Creates comprehensive report:
# - Forward analysis results
# - Backward analysis results
# - Display turn-on timeline
# - Identified issues
# - Recommendations
#
################################################################################

set -e

LOG_FILE="${1:-/var/log/display-chain/chain.log}"
OUTPUT_FILE="${2:-/var/log/display-chain/comprehensive-report.txt}"
ANALYSIS_DIR="${3:-/var/log/display-chain}"

mkdir -p "$(dirname "$OUTPUT_FILE")"

echo "Generating comprehensive report..."
echo ""

# Run all analyses if not already done
if [ ! -f "$ANALYSIS_DIR/forward-analysis/forward-analysis.txt" ]; then
    echo "Running forward analysis..."
    /test-display/analyze-forward.sh "$LOG_FILE" "$ANALYSIS_DIR/forward-analysis" >/dev/null 2>&1 || true
fi

if [ ! -f "$ANALYSIS_DIR/backward-analysis/backward-analysis.txt" ]; then
    echo "Running backward analysis..."
    /test-display/analyze-backward.sh "$LOG_FILE" "$ANALYSIS_DIR/backward-analysis" >/dev/null 2>&1 || true
fi

if [ ! -f "$ANALYSIS_DIR/timeline.txt" ]; then
    echo "Generating timeline..."
    /test-display/generate-timeline.sh "$LOG_FILE" "$ANALYSIS_DIR/timeline.txt" >/dev/null 2>&1 || true
fi

if [ ! -f "$ANALYSIS_DIR/chain-diagram.txt" ]; then
    echo "Generating chain diagram..."
    /test-display/generate-chain-diagram.sh "$LOG_FILE" "$ANALYSIS_DIR/chain-diagram.txt" >/dev/null 2>&1 || true
fi

# Generate comprehensive report
cat > "$OUTPUT_FILE" << EOF
Display Chain Analysis - Comprehensive Report
==============================================

Generated: $(date)
Log file: $LOG_FILE

EXECUTIVE SUMMARY
-----------------
This report analyzes the complete display chain from boot to Chromium,
identifying synchronization points, mismatches, and root causes of
display issues.

FORWARD ANALYSIS (Boot → Chromium)
----------------------------------
EOF

if [ -f "$ANALYSIS_DIR/forward-analysis/forward-analysis.txt" ]; then
    cat "$ANALYSIS_DIR/forward-analysis/forward-analysis.txt" >> "$OUTPUT_FILE"
else
    echo "Forward analysis not available" >> "$OUTPUT_FILE"
fi

cat >> "$OUTPUT_FILE" << EOF

BACKWARD ANALYSIS (Chromium → Boot)
------------------------------------
EOF

if [ -f "$ANALYSIS_DIR/backward-analysis/backward-analysis.txt" ]; then
    cat "$ANALYSIS_DIR/backward-analysis/backward-analysis.txt" >> "$OUTPUT_FILE"
else
    echo "Backward analysis not available" >> "$OUTPUT_FILE"
fi

cat >> "$OUTPUT_FILE" << EOF

CHAIN DIAGRAM
-------------
EOF

if [ -f "$ANALYSIS_DIR/chain-diagram.txt" ]; then
    cat "$ANALYSIS_DIR/chain-diagram.txt" >> "$OUTPUT_FILE"
else
    echo "Chain diagram not available" >> "$OUTPUT_FILE"
fi

cat >> "$OUTPUT_FILE" << EOF

IDENTIFIED ISSUES
-----------------
EOF

# Extract mismatches
MISMATCHES=$(jq -r 'select(.event_type == "error" and (.message | contains("mismatch") or contains("Mismatch"))) | "  - [\(.layer)] \(.message): \(.data)"' "$LOG_FILE" 2>/dev/null || echo "")
if [ -n "$MISMATCHES" ]; then
    echo "$MISMATCHES" >> "$OUTPUT_FILE"
else
    echo "  No mismatches detected in logs" >> "$OUTPUT_FILE"
fi

cat >> "$OUTPUT_FILE" << EOF

RECOMMENDATIONS
--------------
EOF

# Generate recommendations based on analysis
FB_SIZE=$(jq -r 'select(.layer == "framebuffer" and .event_type == "ready") | .data.size' "$LOG_FILE" | head -1 || echo "")
DRM_SIZE=$(jq -r 'select(.layer == "drm" and .event_type == "ready") | .data.size' "$LOG_FILE" | head -1 || echo "")
XRANDR_ROTATION=$(jq -r 'select(.layer == "xrandr" and .event_type == "ready") | .data.rotation' "$LOG_FILE" | head -1 || echo "")

if [ "$FB_SIZE" != "$DRM_SIZE" ]; then
    cat >> "$OUTPUT_FILE" << EOF
1. FRAMEBUFFER-DRM MISMATCH DETECTED
   - FB size: $FB_SIZE
   - DRM size: $DRM_SIZE
   - Recommendation: Ensure xrandr synchronizes DRM plane with framebuffer
     before Chromium starts. Add to .xinitrc:
     xrandr --output HDMI-1 --mode $FB_SIZE --rotate normal
EOF
fi

if [ "$XRANDR_ROTATION" != "left" ] && [ "$XRANDR_ROTATION" != "right" ]; then
    if echo "$FB_SIZE" | grep -q "400x1280"; then
        cat >> "$OUTPUT_FILE" << EOF
2. ROTATION NOT APPLIED
   - FB is portrait (400x1280) but rotation not applied
   - Recommendation: Apply xrandr --rotate left in .xinitrc for Forum solution
EOF
    fi
fi

cat >> "$OUTPUT_FILE" << EOF

3. SYNCHRONIZATION TIMING
   - Ensure xrandr runs AFTER X11 is ready but BEFORE Chromium starts
   - Add sleep 2 after X11 start, then apply xrandr, then launch Chromium

4. VERIFICATION
   - After applying fixes, verify all layers are synchronized:
     - FB size matches DRM plane
     - X11 resolution matches expected (rotated if needed)
     - Chromium window size matches DRM plane (before rotation)

NEXT STEPS
----------
1. Review forward and backward analysis results
2. Apply recommended fixes
3. Re-run analysis to verify synchronization
4. Test on actual hardware

EOF

cat "$OUTPUT_FILE"
echo ""
echo "Comprehensive report saved to: $OUTPUT_FILE"

