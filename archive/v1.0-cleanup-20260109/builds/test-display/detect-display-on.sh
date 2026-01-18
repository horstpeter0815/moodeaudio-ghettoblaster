#!/bin/bash
################################################################################
#
# DISPLAY TURN-ON EVENT DETECTION
#
# Detects when display actually turns on:
# - Backlight activation
# - First pixel data
# - Stable rendering
# - Correlates with layer events
#
################################################################################

set -e

LOG_FILE="/var/log/display-chain/display-on.log"
CHAIN_LOG="${1:-/var/log/display-chain/chain.log}"

mkdir -p "$(dirname "$LOG_FILE")"

log() {
    echo "[$(date +%Y-%m-%d\ %H:%M:%S.%N)] $*" | tee -a "$LOG_FILE"
}

log "Display turn-on detection started"

# Track backlight state
LAST_BACKLIGHT="0"
BACKLIGHT_ON_TIME=""

# Track X11 state
LAST_X11_STATE=""
X11_READY_TIME=""

# Track Chromium rendering
LAST_CHROMIUM_STATE=""
CHROMIUM_RENDERING_TIME=""

# Monitor loop
while true; do
    # Check backlight
    if [ -f "/sys/class/backlight/*/brightness" ]; then
        CURRENT_BACKLIGHT=$(cat /sys/class/backlight/*/brightness 2>/dev/null | head -1 || echo "0")
        if [ "$CURRENT_BACKLIGHT" != "$LAST_BACKLIGHT" ]; then
            if [ "$CURRENT_BACKLIGHT" != "0" ] && [ "$LAST_BACKLIGHT" = "0" ]; then
                BACKLIGHT_ON_TIME=$(date +%s%N)
                log "EVENT: Backlight turned ON at $(date +%Y-%m-%d\ %H:%M:%S.%N)"
                
                # Correlate with chain log
                if [ -f "$CHAIN_LOG" ]; then
                    NEAREST_EVENT=$(jq -r --arg ts "$BACKLIGHT_ON_TIME" 'select(.timestamp <= ($ts | tonumber) + 1000000000 and .timestamp >= ($ts | tonumber) - 1000000000) | [.timestamp, .layer, .event_type, .message] | @tsv' "$CHAIN_LOG" | head -1 || echo "")
                    if [ -n "$NEAREST_EVENT" ]; then
                        log "  Correlated with chain event: $NEAREST_EVENT"
                    fi
                fi
            fi
            LAST_BACKLIGHT="$CURRENT_BACKLIGHT"
        fi
    fi
    
    # Check X11 readiness
    if command -v xrandr >/dev/null 2>&1 && DISPLAY=:0 xrandr --query >/dev/null 2>&1; then
        CURRENT_X11_STATE=$(DISPLAY=:0 xrandr --query | grep " connected" | head -1 || echo "")
        if [ "$CURRENT_X11_STATE" != "$LAST_X11_STATE" ] && [ -n "$CURRENT_X11_STATE" ]; then
            X11_READY_TIME=$(date +%s%N)
            log "EVENT: X11 display ready at $(date +%Y-%m-%d\ %H:%M:%S.%N)"
            log "  X11 state: $CURRENT_X11_STATE"
            LAST_X11_STATE="$CURRENT_X11_STATE"
        fi
    fi
    
    # Check Chromium rendering
    if pgrep -f chromium >/dev/null 2>&1; then
        if command -v xwininfo >/dev/null 2>&1 && DISPLAY=:0 xwininfo -root -tree >/dev/null 2>&1; then
            CURRENT_CHROMIUM=$(DISPLAY=:0 xwininfo -root -tree 2>&1 | grep -iE "(chromium|moOde Player)" | head -1 || echo "")
            if [ "$CURRENT_CHROMIUM" != "$LAST_CHROMIUM_STATE" ] && [ -n "$CURRENT_CHROMIUM" ]; then
                CHROMIUM_RENDERING_TIME=$(date +%s%N)
                log "EVENT: Chromium started rendering at $(date +%Y-%m-%d\ %H:%M:%S.%N)"
                log "  Chromium window: $CURRENT_CHROMIUM"
                LAST_CHROMIUM_STATE="$CURRENT_CHROMIUM"
            fi
        fi
    fi
    
    # Detect stable rendering (all components ready)
    if [ -n "$BACKLIGHT_ON_TIME" ] && [ -n "$X11_READY_TIME" ] && [ -n "$CHROMIUM_RENDERING_TIME" ]; then
        log "EVENT: Display fully ON and stable"
        log "  Timeline:"
        log "    Backlight ON: $BACKLIGHT_ON_TIME"
        log "    X11 ready: $X11_READY_TIME"
        log "    Chromium rendering: $CHROMIUM_RENDERING_TIME"
        break
    fi
    
    sleep 0.5
done

log "Display turn-on detection complete"

