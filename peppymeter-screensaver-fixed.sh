#!/bin/bash
# PeppyMeter Screensaver - Simple and Working Version
export DISPLAY=:0
export XAUTHORITY=/home/andre/.Xauthority

INACTIVITY_TIMEOUT=600
LAST_ACTIVITY_FILE=/tmp/peppymeter_last_activity
TOUCH_LOG=/tmp/peppymeter_screensaver.log
PEPPY_ACTIVE=false

log() {
    echo "[$(date +%H:%M:%S)] $1" | tee -a "$TOUCH_LOG"
}

# Initialize
date +%s > "$LAST_ACTIVITY_FILE"

show_peppymeter() {
    if [ "$PEPPY_ACTIVE" = false ]; then
        log "Activating PeppyMeter"
        if ! systemctl is-active --quiet peppymeter.service; then
            sudo systemctl start peppymeter.service
            sleep 3
        fi
        CHROMIUM_WID=$(DISPLAY=:0 xdotool search --classname chromium 2>/dev/null | head -1)
        if [ -n "$CHROMIUM_WID" ]; then
            DISPLAY=:0 xdotool windowunmap "$CHROMIUM_WID" 2>/dev/null
        fi
        PEPPY_ACTIVE=true
    fi
}

hide_peppymeter() {
    if [ "$PEPPY_ACTIVE" = true ]; then
        log "Deactivating PeppyMeter"
        sudo systemctl stop peppymeter.service
        CHROMIUM_WID=$(DISPLAY=:0 xdotool search --classname chromium 2>/dev/null | head -1)
        if [ -n "$CHROMIUM_WID" ]; then
            DISPLAY=:0 xdotool windowmap "$CHROMIUM_WID" 2>/dev/null
            DISPLAY=:0 xdotool windowraise "$CHROMIUM_WID" 2>/dev/null
        fi
        PEPPY_ACTIVE=false
        date +%s > "$LAST_ACTIVITY_FILE"
    fi
}

# Monitor touch using xinput
monitor_touch() {
    while true; do
        WAVESHARE_ID=$(DISPLAY=:0 xinput list | grep -i WaveShare | grep -oP 'id=\K[0-9]+' | head -1)
        if [ -n "$WAVESHARE_ID" ]; then
            DISPLAY=:0 xinput --test-xi2 "$WAVESHARE_ID" 2>/dev/null | while IFS= read -r line; do
                if [[ "$line" =~ "EVENT type 15" ]] || [[ "$line" =~ "EVENT type 14" ]]; then
                    date +%s > "$LAST_ACTIVITY_FILE"
                    if [ "$PEPPY_ACTIVE" = true ]; then
                        hide_peppymeter
                    fi
                fi
            done
        fi
        sleep 1
    done
}

# Start touch monitor
monitor_touch &
TOUCH_PID=$!
trap "kill $TOUCH_PID 2>/dev/null; exit" SIGTERM SIGINT EXIT

log "PeppyMeter Screensaver started"

# Main loop
while true; do
    CURRENT_TIME=$(date +%s)
    LAST_ACTIVITY=$(cat "$LAST_ACTIVITY_FILE" 2>/dev/null || echo "$CURRENT_TIME")
    INACTIVE_TIME=$((CURRENT_TIME - LAST_ACTIVITY))
    
    if [ $INACTIVE_TIME -ge $INACTIVITY_TIMEOUT ]; then
        if [ "$PEPPY_ACTIVE" = false ]; then
            show_peppymeter
        fi
    fi
    sleep 1
done

