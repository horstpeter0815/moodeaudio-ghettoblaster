#!/bin/bash
################################################################################
#
# TIMELINE VISUALIZATION
#
# Creates timeline showing:
# - Boot events
# - Service starts
# - Display state changes
# - Synchronization points
# - Mismatches
#
################################################################################

set -e

LOG_FILE="${1:-/var/log/display-chain/chain.log}"
OUTPUT_FILE="${2:-/var/log/display-chain/timeline.txt}"

mkdir -p "$(dirname "$OUTPUT_FILE")"

echo "Generating timeline visualization..."
echo ""

# Generate timeline
cat > "$OUTPUT_FILE" << 'EOF'
Display Chain Timeline
======================

EOF

# Extract events sorted by timestamp
jq -r '[.timestamp, .layer, .event_type, .message] | @tsv' "$LOG_FILE" | \
    sort -n | \
    while IFS=$'\t' read -r timestamp layer event_type message; do
        # Convert timestamp to readable format (approximate)
        readable_time=$(date -d "@$((timestamp / 1000000000))" +"%H:%M:%S.%N" 2>/dev/null || echo "${timestamp:0:19}")
        printf "%-20s [%-12s] [%-10s] %s\n" "$readable_time" "$layer" "$event_type" "$message"
    done >> "$OUTPUT_FILE"

# Add summary
cat >> "$OUTPUT_FILE" << EOF

Summary
=======
Total events: $(jq -r '. | length' <(jq -s '.' "$LOG_FILE" 2>/dev/null || echo "[]"))
Layers: boot, framebuffer, drm, x11, xrandr, chromium
Event types: init, config, start, ready, error, snapshot, complete

EOF

cat "$OUTPUT_FILE"
echo ""
echo "Timeline saved to: $OUTPUT_FILE"

