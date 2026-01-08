#!/bin/bash
export DISPLAY=:0

# Wait for X
for i in {1..40}; do
    xrandr --query >/dev/null 2>&1 && break
    sleep 0.25
done

xhost +SI:localuser:andre 2>/dev/null || true
sleep 2

# Set Landscape
if xrandr | grep -q "400x1280"; then
    xrandr --output HDMI-2 --mode 400x1280 --rotate left 2>&1
elif xrandr | grep -q "1280x400"; then
    xrandr --output HDMI-2 --mode 1280x400 --rotate normal 2>&1
fi

xset s 600
xset -dpms 2>/dev/null || true
xset s 600

# Start Chromium in kiosk mode
chromium-browser \
    --kiosk \
    --no-sandbox \
    --user-data-dir=/tmp/chromium-data \
    --window-size=1280,400 \
    --window-position=0,0 \
    --start-fullscreen \
    http://localhost &

# Wait for Chromium to start
sleep 5

# Ensure Chromium window is properly sized and positioned
CHROMIUM_WID=$(DISPLAY=:0 xdotool search --classname chromium 2>/dev/null | head -1)
if [ -n "$CHROMIUM_WID" ]; then
    DISPLAY=:0 xdotool windowmove "$CHROMIUM_WID" 0 0 2>/dev/null
    DISPLAY=:0 xdotool windowsize "$CHROMIUM_WID" 1280 400 2>/dev/null
fi

# Keep script running
wait

