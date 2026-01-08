#!/bin/bash
################################################################################
#
# Debug PeppyMeter Screen Detection
# 
# This script instruments PeppyMeter's screen detection to understand
# what it sees when it starts.
#
################################################################################

LOG_FILE="/tmp/video-chain-debug.log"

debug_log() {
    local hypothesis_id="$1"
    local location="$2"
    local message="$3"
    local data="$4"
    echo "{\"id\":\"log_$(date +%s)_$$\",\"timestamp\":$(date +%s)000,\"location\":\"$location\",\"message\":\"$message\",\"data\":$data,\"sessionId\":\"peppy-debug\",\"runId\":\"screen-detection\",\"hypothesisId\":\"$hypothesis_id\"}" >> "$LOG_FILE"
}

echo "=== DEBUG PEPPYMETER SCREEN DETECTION ==="
debug_log "C" "debug-peppymeter-screen-detection.sh:start" "Script started" "{}"

# Wait for X11
export DISPLAY=:0
sleep 2

# Test what PeppyMeter would see
echo "1. Testing folder name parsing (1280x400):"
python3 << 'PYTEST'
import sys
sys.path.insert(0, '/opt/peppymeter')

try:
    from configfileparser import ConfigFileParser
    parser = ConfigFileParser()
    size = parser.get_meter_size('1280x400')
    print(f"   Parsed size: {size[0]}x{size[1]}")
    print(f"   Width: {size[0]}, Height: {size[1]}")
    print(f"   Is landscape: {size[0] > size[1]}")
except Exception as e:
    print(f"   Error: {e}")
PYTEST

debug_log "C" "debug-peppymeter-screen-detection.sh:folder-parse" "Folder name parsed" "{\"folder\":\"1280x400\"}"

echo ""
echo "2. Testing Pygame display (what PeppyMeter will use):"
PYGAME_INFO=$(python3 << 'PYTEST'
import pygame
pygame.display.init()
info = pygame.display.Info()
print(f"{info.current_w}x{info.current_h}")
PYTEST
2>/dev/null 2>/dev/null | grep -oE '[0-9]+x[0-9]+' | head -1)

echo "   Pygame reports: $PYGAME_INFO"
debug_log "C" "debug-peppymeter-screen-detection.sh:pygame-size" "Pygame screen size" "{\"dimensions\":\"$PYGAME_INFO\"}"

echo ""
echo "3. Testing X11 display (what rotation script sees):"
X11_DIM=$(xdpyinfo 2>/dev/null | grep dimensions | grep -oE '[0-9]+x[0-9]+' | head -1)
echo "   X11 reports: $X11_DIM"
debug_log "C" "debug-peppymeter-screen-detection.sh:x11-size" "X11 screen size" "{\"dimensions\":\"$X11_DIM\"}"

echo ""
echo "4. Comparing:"
if [ "$PYGAME_INFO" = "$X11_DIM" ] && [ "$PYGAME_INFO" = "1280x400" ]; then
    echo "   ✅ Pygame and X11 match: $PYGAME_INFO (landscape)"
    debug_log "C" "debug-peppymeter-screen-detection.sh:match" "Pygame and X11 match" "{\"dimensions\":\"$PYGAME_INFO\"}"
else
    echo "   ⚠️  Mismatch: Pygame=$PYGAME_INFO, X11=$X11_DIM"
    debug_log "C" "debug-peppymeter-screen-detection.sh:mismatch" "Pygame and X11 mismatch" "{\"pygame\":\"$PYGAME_INFO\",\"x11\":\"$X11_DIM\"}"
fi

echo ""
echo "5. Checking PeppyMeter config:"
CONFIG_FILE="/opt/peppymeter/1280x400/meters.txt"
if [ -f "$CONFIG_FILE" ]; then
    METER_TYPE=$(grep "meter.type" "$CONFIG_FILE" | head -1 | cut -d'=' -f2 | tr -d ' ')
    LEFT_X=$(grep "left.x" "$CONFIG_FILE" | head -1 | cut -d'=' -f2 | tr -d ' ')
    LEFT_Y=$(grep "left.y" "$CONFIG_FILE" | head -1 | cut -d'=' -f2 | tr -d ' ')
    RIGHT_X=$(grep "right.x" "$CONFIG_FILE" | head -1 | cut -d'=' -f2 | tr -d ' ')
    RIGHT_Y=$(grep "right.y" "$CONFIG_FILE" | head -1 | cut -d'=' -f2 | tr -d ' ')
    
    echo "   Meter type: $METER_TYPE"
    echo "   Left meter: X=$LEFT_X, Y=$LEFT_Y"
    echo "   Right meter: X=$RIGHT_X, Y=$RIGHT_Y"
    echo "   Screen: 1280x400 (landscape)"
    
    # Check if coordinates make sense for landscape
    if [ "$LEFT_X" -lt "$RIGHT_X" ] && [ "$LEFT_Y" -eq "$RIGHT_Y" ]; then
        echo "   ✅ Coordinates look correct for landscape (left < right, same Y)"
        debug_log "C" "debug-peppymeter-screen-detection.sh:coords-ok" "Coordinates look correct" "{\"left\":\"$LEFT_X,$LEFT_Y\",\"right\":\"$RIGHT_X,$RIGHT_Y\"}"
    else
        echo "   ⚠️  Coordinates might be wrong for landscape"
        debug_log "C" "debug-peppymeter-screen-detection.sh:coords-wrong" "Coordinates might be wrong" "{\"left\":\"$LEFT_X,$LEFT_Y\",\"right\":\"$RIGHT_X,$RIGHT_Y\"}"
    fi
fi

echo ""
echo "=== DEBUG COMPLETE ==="

