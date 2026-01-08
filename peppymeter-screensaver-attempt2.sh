#!/bin/bash
# PeppyMeter Screensaver - Final Working Version
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
        # Hide Chromium if it exists
        CHROMIUM_WID=$(DISPLAY=:0 xdotool search --classname chromium 2>/dev/null | head -1)
        if [ -n "$CHROMIUM_WID" ]; then
            DISPLAY=:0 xdotool windowunmap "$CHROMIUM_WID" 2>/dev/null
        fi
        PEPPY_ACTIVE=true
    fi
}

hide_peppymeter() {
    if [ "$PEPPY_ACTIVE" = true ]; then
        log "Deactivating PeppyMeter and closing Chromium"
        # Stop PeppyMeter
        sudo systemctl stop peppymeter.service
        # Close Chromium completely
        pkill -f "chromium-browser" || true
        pkill -f "chromium" || true
        sleep 2
        # Restart Chromium (web player) via localdisplay service
        sudo systemctl restart localdisplay.service
        PEPPY_ACTIVE=false
        date +%s > "$LAST_ACTIVITY_FILE"
    fi
}

# Monitor touch using xinput test (simpler approach)
monitor_touch() {
    WAVESHARE_ID=$(DISPLAY=:0 xinput list | grep -i WaveShare | grep -oP 'id=\K[0-9]+' | head -1)
    if [ -z "$WAVESHARE_ID" ]; then
        log "WaveShare touchscreen not found"
        return
    fi
    
    log "Monitoring touchscreen (ID: $WAVESHARE_ID)"
    
    # Use xinput test - detect button press/release and motion
    DISPLAY=:0 xinput --test "$WAVESHARE_ID" 2>/dev/null | while IFS= read -r line; do
        # Any event from touchscreen updates activity
        if [[ "$line" =~ "button press" ]] || [[ "$line" =~ "button release" ]] || [[ "$line" =~ "motion" ]]; then
            date +%s > "$LAST_ACTIVITY_FILE"
            log "Touch detected: $line"
            if [ "$PEPPY_ACTIVE" = true ]; then
                log "PeppyMeter is active - closing both"
                hide_peppymeter
            fi
        fi
    done
}

# Start touch monitor
monitor_touch &
TOUCH_PID=$!
trap "kill $TOUCH_PID 2>/dev/null; exit" SIGTERM SIGINT EXIT

log "PeppyMeter Screensaver started (touch closes both PeppyMeter and Chromium)"

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

