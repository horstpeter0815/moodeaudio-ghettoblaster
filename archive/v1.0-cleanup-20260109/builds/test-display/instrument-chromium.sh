#!/bin/bash
################################################################################
#
# CHROMIUM INSTRUMENTATION
#
# Hooks into Chromium:
# - Window creation → log window size
# - Display connection → log display ID
# - Rendering → log render target size
# - X11 queries → log X11 state
#
################################################################################

set -e

# Source the logger
source /scripts/display-chain-logger.sh 2>/dev/null || {
    LOG_FILE="/var/log/display-chain/chromium.log"
    mkdir -p "$(dirname "$LOG_FILE")"
    log() {
        echo "[$(date +%Y-%m-%d\ %H:%M:%S)] $*" >> "$LOG_FILE"
    }
}

log_chromium() {
    log "[CHROMIUM] $*"
}

# Find Chromium processes
CHROMIUM_PIDS=$(pgrep -f chromium 2>/dev/null || echo "")

if [ -z "$CHROMIUM_PIDS" ]; then
    log_chromium "No Chromium processes found"
    exit 0
fi

log_chromium "Chromium processes detected: $CHROMIUM_PIDS"

# Get Chromium window information
if command -v xwininfo >/dev/null 2>&1 && DISPLAY=:0 xwininfo -root -tree >/dev/null 2>&1; then
    # Find Chromium window
    CHROMIUM_WINDOW=$(DISPLAY=:0 xwininfo -root -tree 2>&1 | grep -iE "(chromium|moOde Player)" | head -1 || echo "")
    
    if [ -n "$CHROMIUM_WINDOW" ]; then
        WINDOW_ID=$(echo "$CHROMIUM_WINDOW" | awk '{print $1}' | tr -d 'x' || echo "")
        WINDOW_GEOM=$(echo "$CHROMIUM_WINDOW" | awk '{print $3}' || echo "")
        
        log_chromium "Chromium window found: ID=$WINDOW_ID, Geometry=$WINDOW_GEOM"
        
        # Get detailed window info
        if [ -n "$WINDOW_ID" ]; then
            WINDOW_INFO=$(DISPLAY=:0 xwininfo -id "$WINDOW_ID" 2>&1 | grep -E "(Width|Height|Absolute)" || echo "")
            log_chromium "Window details: $WINDOW_INFO"
        fi
    else
        log_chromium "Chromium window not found in X11 tree"
    fi
fi

# Get X11 screen information
if command -v xrandr >/dev/null 2>&1 && DISPLAY=:0 xrandr --query >/dev/null 2>&1; then
    X11_SCREEN=$(DISPLAY=:0 xrandr --query | grep " connected" | head -1 || echo "")
    log_chromium "X11 screen state: $X11_SCREEN"
    
    # Extract resolution and rotation
    X11_RES=$(echo "$X11_SCREEN" | awk '{print $3}' || echo "")
    X11_ROT=$(echo "$X11_SCREEN" | grep -oE "(left|right|normal|inverted)" | head -1 || echo "normal")
    log_chromium "X11 resolution: $X11_RES, rotation: $X11_ROT"
fi

# Check Chromium command line arguments
if [ -n "$CHROMIUM_PIDS" ]; then
    MAIN_PID=$(echo "$CHROMIUM_PIDS" | head -1)
    CHROMIUM_CMD=$(ps -p "$MAIN_PID" -o args= 2>/dev/null || echo "")
    
    if echo "$CHROMIUM_CMD" | grep -q "window-size"; then
        WINDOW_SIZE=$(echo "$CHROMIUM_CMD" | grep -o "window-size=[^ ]*" | cut -d'=' -f2 || echo "")
        log_chromium "Chromium window-size parameter: $WINDOW_SIZE"
    fi
    
    if echo "$CHROMIUM_CMD" | grep -q "--app"; then
        APP_URL=$(echo "$CHROMIUM_CMD" | grep -o "--app=[^ ]*" | cut -d'=' -f2 || echo "")
        log_chromium "Chromium app URL: $APP_URL"
    fi
fi

log_chromium "Chromium instrumentation complete"

