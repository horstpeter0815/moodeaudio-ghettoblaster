#!/bin/bash
################################################################################
#
# ANALYZE DISPLAY CHAIN LOGS
#
# Aggregates logs from all layers
# Creates timeline visualization
# Identifies synchronization points
# Detects mismatches between layers
#
################################################################################

set -e

LOG_FILE="${1:-/var/log/display-chain/chain.log}"
OUTPUT_DIR="${2:-/var/log/display-chain/analysis}"

mkdir -p "$OUTPUT_DIR"

echo "=== DISPLAY CHAIN LOG ANALYSIS ==="
echo "Log file: $LOG_FILE"
echo "Output directory: $OUTPUT_DIR"
echo ""

# Check if log file exists
if [ ! -f "$LOG_FILE" ]; then
    echo "Error: Log file not found: $LOG_FILE"
    exit 1
fi

# Extract timeline
echo "Extracting timeline..."
jq -r '[.timestamp, .layer, .event_type, .message] | @tsv' "$LOG_FILE" | \
    sort -n > "$OUTPUT_DIR/timeline.tsv"

# Extract state snapshots
echo "Extracting state snapshots..."
jq -r 'select(.event_type == "snapshot" or .event_type == "ready") | [.timestamp, .layer, .data] | @json' "$LOG_FILE" > "$OUTPUT_DIR/snapshots.json"

# Detect mismatches
echo "Detecting mismatches..."
jq -r 'select(.event_type == "error" and (.message | contains("mismatch") or contains("Mismatch"))) | [.timestamp, .layer, .message, .data] | @json' "$LOG_FILE" > "$OUTPUT_DIR/mismatches.json"

# Layer-by-layer analysis
echo "Analyzing layers..."
for layer in boot framebuffer drm x11 xrandr chromium; do
    echo "  - $layer"
    jq -r "select(.layer == \"$layer\") | [.timestamp, .event_type, .message] | @tsv" "$LOG_FILE" > "$OUTPUT_DIR/${layer}_events.tsv"
done

# Synchronization points
echo "Identifying synchronization points..."
jq -r 'select(.event_type == "ready" or .event_type == "complete") | [.timestamp, .layer, .data] | @json' "$LOG_FILE" > "$OUTPUT_DIR/sync_points.json"

# Generate summary
echo "Generating summary..."
cat > "$OUTPUT_DIR/summary.txt" << EOF
Display Chain Log Analysis Summary
===================================

Total log entries: $(jq -r '. | length' <(jq -s '.' "$LOG_FILE" 2>/dev/null || echo "[]"))
Mismatches detected: $(jq -r '. | length' "$OUTPUT_DIR/mismatches.json" 2>/dev/null || echo "0")
Synchronization points: $(jq -r '. | length' "$OUTPUT_DIR/sync_points.json" 2>/dev/null || echo "0")

Layer event counts:
$(for layer in boot framebuffer drm x11 xrandr chromium; do
    count=$(wc -l < "$OUTPUT_DIR/${layer}_events.tsv" 2>/dev/null || echo "0")
    echo "  $layer: $count events"
done)

Files generated:
  - timeline.tsv: Complete timeline of all events
  - snapshots.json: State snapshots at each layer
  - mismatches.json: Detected mismatches
  - sync_points.json: Synchronization points
  - *_events.tsv: Layer-specific event timelines
EOF

cat "$OUTPUT_DIR/summary.txt"
echo ""
echo "Analysis complete. Results saved to: $OUTPUT_DIR"

