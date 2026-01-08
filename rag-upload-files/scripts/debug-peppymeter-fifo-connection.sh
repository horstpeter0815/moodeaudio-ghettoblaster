#!/bin/bash
################################################################################
#
# Debug PeppyMeter FIFO Connection
# 
# This script instruments PeppyMeter's FIFO pipe connection to understand
# why indicators are not moving.
#
################################################################################

LOG_FILE="/tmp/video-chain-debug.log"
SESSION_ID="peppy-fifo-debug"
RUN_ID="fifo-connection"

debug_log() {
    local hypothesis_id="$1"
    local location="$2"
    local message="$3"
    local data="$4"
    echo "{\"id\":\"log_$(date +%s)_$$\",\"timestamp\":$(date +%s)000,\"location\":\"$location\",\"message\":\"$message\",\"data\":$data,\"sessionId\":\"$SESSION_ID\",\"runId\":\"$RUN_ID\",\"hypothesisId\":\"$hypothesis_id\"}" >> "$LOG_FILE"
}

echo "=== DEBUG PEPPYMETER FIFO CONNECTION ==="
debug_log "D1" "debug-peppymeter-fifo-connection.sh:start" "Script started" "{}"

# Hypothesis D1: PeppyMeter config has wrong pipe path
# Hypothesis D2: PeppyMeter cannot open pipe (permissions/access)
# Hypothesis D3: PeppyMeter opens pipe but doesn't read from it
# Hypothesis D4: PeppyMeter reads but doesn't process data correctly
# Hypothesis D5: Data format mismatch between MPD and PeppyMeter

echo ""
echo "=== HYPOTHESIS D1: Check Pipe Path Configuration ==="
PIPE_NAME_CONFIG=$(grep "pipe.name" /etc/peppymeter/config.txt | cut -d'=' -f2 | tr -d ' ')
FIFO_ACTUAL="/tmp/mpd.fifo"
echo "Config pipe.name: $PIPE_NAME_CONFIG"
echo "Actual FIFO path: $FIFO_ACTUAL"
debug_log "D1" "debug-peppymeter-fifo-connection.sh:pipe-path" "Pipe path check" "{\"config\":\"$PIPE_NAME_CONFIG\",\"actual\":\"$FIFO_ACTUAL\"}"

if [ "$PIPE_NAME_CONFIG" != "$FIFO_ACTUAL" ]; then
    echo "⚠️  MISMATCH: Config path doesn't match actual FIFO!"
    debug_log "D1" "debug-peppymeter-fifo-connection.sh:pipe-path-mismatch" "Pipe path mismatch" "{\"config\":\"$PIPE_NAME_CONFIG\",\"actual\":\"$FIFO_ACTUAL\"}"
else
    echo "✅ Pipe paths match"
    debug_log "D1" "debug-peppymeter-fifo-connection.sh:pipe-path-match" "Pipe paths match" "{}"
fi

echo ""
echo "=== HYPOTHESIS D2: Check Pipe Permissions and Access ==="
if [ -p "$FIFO_ACTUAL" ]; then
    echo "✅ FIFO exists: $FIFO_ACTUAL"
    FIFO_PERMS=$(ls -la "$FIFO_ACTUAL" | awk '{print $1, $3, $4}')
    echo "   Permissions: $FIFO_PERMS"
    debug_log "D2" "debug-peppymeter-fifo-connection.sh:fifo-exists" "FIFO exists" "{\"path\":\"$FIFO_ACTUAL\",\"perms\":\"$FIFO_PERMS\"}"
    
    # Check if andre user can read
    if sudo -u andre test -r "$FIFO_ACTUAL" 2>/dev/null; then
        echo "✅ User 'andre' can read FIFO"
        debug_log "D2" "debug-peppymeter-fifo-connection.sh:fifo-readable" "FIFO is readable by andre" "{}"
    else
        echo "⚠️  User 'andre' CANNOT read FIFO"
        debug_log "D2" "debug-peppymeter-fifo-connection.sh:fifo-not-readable" "FIFO not readable by andre" "{}"
    fi
else
    echo "❌ FIFO does not exist: $FIFO_ACTUAL"
    debug_log "D2" "debug-peppymeter-fifo-connection.sh:fifo-not-exists" "FIFO does not exist" "{\"path\":\"$FIFO_ACTUAL\"}"
fi

echo ""
echo "=== HYPOTHESIS D3: Check if PeppyMeter Process Has Pipe Open ==="
PEPPY_PID=$(pgrep -f "peppymeter.py" | head -1)
if [ -n "$PEPPY_PID" ]; then
    echo "PeppyMeter PID: $PEPPY_PID"
    PEPPY_USER=$(ps -p "$PEPPY_PID" -o user --no-headers)
    echo "Running as user: $PEPPY_USER"
    debug_log "D3" "debug-peppymeter-fifo-connection.sh:peppy-process" "PeppyMeter process found" "{\"pid\":\"$PEPPY_PID\",\"user\":\"$PEPPY_USER\"}"
    
    # Check open file descriptors
    OPEN_FIFO=$(sudo lsof -p "$PEPPY_PID" 2>/dev/null | grep -E "fifo|pipe|mpd" || echo "NONE")
    echo "Open FIFO/pipe files:"
    echo "$OPEN_FIFO"
    debug_log "D3" "debug-peppymeter-fifo-connection.sh:open-files" "Open files check" "{\"pid\":\"$PEPPY_PID\",\"open_files\":\"$OPEN_FIFO\"}"
    
    if echo "$OPEN_FIFO" | grep -q "mpd.fifo"; then
        echo "✅ PeppyMeter HAS FIFO open"
        debug_log "D3" "debug-peppymeter-fifo-connection.sh:fifo-open" "FIFO is open" "{}"
    else
        echo "❌ PeppyMeter does NOT have FIFO open"
        debug_log "D3" "debug-peppymeter-fifo-connection.sh:fifo-not-open" "FIFO is NOT open" "{}"
    fi
else
    echo "❌ PeppyMeter process not found"
    debug_log "D3" "debug-peppymeter-fifo-connection.sh:peppy-not-running" "PeppyMeter not running" "{}"
fi

echo ""
echo "=== HYPOTHESIS D4: Check Data Source Type ==="
DATA_SOURCE_TYPE=$(grep "type = " /etc/peppymeter/config.txt | grep -v "^#" | head -1 | cut -d'=' -f2 | tr -d ' ')
echo "Data source type: $DATA_SOURCE_TYPE"
debug_log "D4" "debug-peppymeter-fifo-connection.sh:data-source-type" "Data source type" "{\"type\":\"$DATA_SOURCE_TYPE\"}"

if [ "$DATA_SOURCE_TYPE" = "pipe" ]; then
    echo "✅ Data source is 'pipe' (correct)"
    debug_log "D4" "debug-peppymeter-fifo-connection.sh:data-source-pipe" "Data source is pipe" "{}"
else
    echo "⚠️  Data source is '$DATA_SOURCE_TYPE' (should be 'pipe')"
    debug_log "D4" "debug-peppymeter-fifo-connection.sh:data-source-wrong" "Data source is not pipe" "{\"type\":\"$DATA_SOURCE_TYPE\"}"
fi

echo ""
echo "=== HYPOTHESIS D5: Check MPD FIFO Output and Data Format ==="
MPD_FIFO_ENABLED=$(mpc outputs 2>/dev/null | grep -A 2 "PeppyMeter FIFO" | grep -q "enabled" && echo "yes" || echo "no")
echo "MPD FIFO output enabled: $MPD_FIFO_ENABLED"
debug_log "D5" "debug-peppymeter-fifo-connection.sh:mpd-fifo-enabled" "MPD FIFO enabled" "{\"enabled\":\"$MPD_FIFO_ENABLED\"}"

# Check MPD config for FIFO format
MPD_FIFO_FORMAT=$(grep -A 5 'type "fifo"' /etc/mpd.conf 2>/dev/null | grep "format" | cut -d'"' -f2 || echo "NOT_FOUND")
echo "MPD FIFO format: $MPD_FIFO_FORMAT"
debug_log "D5" "debug-peppymeter-fifo-connection.sh:mpd-fifo-format" "MPD FIFO format" "{\"format\":\"$MPD_FIFO_FORMAT\"}"

# Test data flow
echo ""
echo "Testing FIFO data flow (2 seconds):"
FIFO_BYTES=$(timeout 2 cat "$FIFO_ACTUAL" 2>/dev/null | wc -c)
echo "Bytes read: $FIFO_BYTES"
debug_log "D5" "debug-peppymeter-fifo-connection.sh:fifo-data-flow" "FIFO data flow test" "{\"bytes\":\"$FIFO_BYTES\"}"

if [ "$FIFO_BYTES" -gt 0 ]; then
    echo "✅ Data is flowing through FIFO"
    debug_log "D5" "debug-peppymeter-fifo-connection.sh:data-flowing" "Data is flowing" "{\"bytes\":\"$FIFO_BYTES\"}"
else
    echo "⚠️  No data flowing through FIFO"
    debug_log "D5" "debug-peppymeter-fifo-connection.sh:no-data-flow" "No data flowing" "{}"
fi

echo ""
echo "=== SUMMARY ==="
echo "Based on evidence:"
if [ "$PIPE_NAME_CONFIG" = "$FIFO_ACTUAL" ] && [ -p "$FIFO_ACTUAL" ] && [ "$DATA_SOURCE_TYPE" = "pipe" ] && [ "$MPD_FIFO_ENABLED" = "yes" ] && [ "$FIFO_BYTES" -gt 0 ]; then
    if [ -n "$PEPPY_PID" ] && sudo lsof -p "$PEPPY_PID" 2>/dev/null | grep -q "mpd.fifo"; then
        echo "✅ All checks passed - PeppyMeter should be working"
        debug_log "SUMMARY" "debug-peppymeter-fifo-connection.sh:all-ok" "All checks passed" "{}"
    else
        echo "❌ PROBLEM: PeppyMeter is NOT reading from FIFO (even though everything else is correct)"
        echo "   → Need to check why PeppyMeter isn't opening the pipe"
        debug_log "SUMMARY" "debug-peppymeter-fifo-connection.sh:peppy-not-reading" "PeppyMeter not reading FIFO" "{}"
    fi
else
    echo "⚠️  Some configuration issues found - see details above"
    debug_log "SUMMARY" "debug-peppymeter-fifo-connection.sh:config-issues" "Configuration issues found" "{}"
fi

echo ""
echo "=== DEBUG COMPLETE ==="










