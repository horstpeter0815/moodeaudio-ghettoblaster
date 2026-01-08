#!/bin/bash
################################################################################
#
# DISPLAY STATE MONITOR
#
# Monitors display state changes:
# - Backlight on/off
# - Signal detection
# - Mode changes
# - Content rendering
#
################################################################################

set -e

LOG_FILE="/var/log/display-chain/display-state.log"
MONITOR_INTERVAL="${1:-1}"  # seconds

mkdir -p "$(dirname "$LOG_FILE")"

log() {
    echo "[$(date +%Y-%m-%d\ %H:%M:%S.%N)] $*" >> "$LOG_FILE"
}

log "Display state monitor started (interval: ${MONITOR_INTERVAL}s)"

# Monitor loop
while true; do
    TIMESTAMP=$(date +%s%N)
    
    # Check backlight (if available)
    if [ -f "/sys/class/backlight/*/brightness" ]; then
        BACKLIGHT=$(cat /sys/class/backlight/*/brightness 2>/dev/null | head -1 || echo "0")
        if [ "$BACKLIGHT" != "0" ]; then
            log "Backlight: ON (brightness: $BACKLIGHT)"
        else
            log "Backlight: OFF"
        fi
    fi
    
    # Check X11 display state
    if command -v xrandr >/dev/null 2>&1 && DISPLAY=:0 xrandr --query >/dev/null 2>&1; then
        X11_STATE=$(DISPLAY=:0 xrandr --query | grep " connected" | head -1 || echo "")
        if [ -n "$X11_STATE" ]; then
            log "X11 state: $X11_STATE"
        fi
    fi
    
    # Check framebuffer state
    if [ -f "/sys/class/graphics/fb0/virtual_size" ]; then
        FB_SIZE=$(cat /sys/class/graphics/fb0/virtual_size)
        log "Framebuffer: $FB_SIZE"
    fi
    
    # Check DRM state
    if command -v kmsprint >/dev/null 2>&1; then
        DRM_STATE=$(kmsprint 2>/dev/null | grep "FB" | head -1 || echo "")
        if [ -n "$DRM_STATE" ]; then
            log "DRM state: $DRM_STATE"
        fi
    fi
    
    # Check Chromium rendering
    if pgrep -f chromium >/dev/null 2>&1; then
        if command -v xwininfo >/dev/null 2>&1 && DISPLAY=:0 xwininfo -root -tree >/dev/null 2>&1; then
            CHROMIUM_WINDOW=$(DISPLAY=:0 xwininfo -root -tree 2>&1 | grep -iE "(chromium|moOde Player)" | head -1 || echo "")
            if [ -n "$CHROMIUM_WINDOW" ]; then
                log "Chromium rendering: Active ($CHROMIUM_WINDOW)"
            else
                log "Chromium rendering: Window not found"
            fi
        fi
    fi
    
    sleep "$MONITOR_INTERVAL"
done

