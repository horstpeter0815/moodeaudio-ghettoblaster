#!/bin/bash
# Ghettoblaster - X Server Ready Check
export DISPLAY=:0
export XAUTHORITY=/home/andre/.Xauthority
MAX_WAIT=30
WAIT_INTERVAL=0.5
for i in $(seq 1 $((MAX_WAIT * 2))); do
    if timeout 1 xrandr --query >/dev/null 2>&1; then
        if timeout 1 xdpyinfo -display :0 >/dev/null 2>&1; then
            exit 0
        fi
    fi
    sleep $WAIT_INTERVAL
done
exit 1
