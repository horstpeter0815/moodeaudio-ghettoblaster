#!/bin/bash
# Ghettoblaster - X Server Ready Check
export DISPLAY=:0
export XAUTHORITY=/home/andre/.Xauthority

# Display chain logging
LOG_FILE="/var/log/display-chain/x11-state.log"
mkdir -p "$(dirname "$LOG_FILE")"
log_x11() {
    echo "[$(date +%Y-%m-%d\ %H:%M:%S.%N)] [X11] $*" >> "$LOG_FILE"
}

MAX_WAIT=30
WAIT_INTERVAL=0.5
for i in $(seq 1 $((MAX_WAIT * 2))); do
    if timeout 1 xrandr --query >/dev/null 2>&1; then
        if timeout 1 xdpyinfo -display :0 >/dev/null 2>&1; then
            # Log X11 state when ready
            X11_STATE=$(xrandr --query 2>/dev/null | grep " connected" | head -1 || echo "")
            log_x11 "X11 server ready: $X11_STATE"
            X11_RES=$(echo "$X11_STATE" | awk '{print $3}' || echo "")
            log_x11 "X11 resolution: $X11_RES"
            exit 0
        fi
    fi
    sleep $WAIT_INTERVAL
done
log_x11 "X11 server not ready after ${MAX_WAIT}s timeout"
exit 1
