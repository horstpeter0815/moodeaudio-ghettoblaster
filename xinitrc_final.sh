#!/bin/bash
# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright 2014 The moOde audio player project / Tim Curtis

# Export display variables
export DISPLAY=:0
export XAUTHORITY=/home/andre/.Xauthority

# Wait for X server to be ready
for i in {1..30}; do
    if xset q &>/dev/null 2>&1; then
        break
    fi
    sleep 1
done

# CRITICAL FIX: Set display to native 1280x400 landscape mode BEFORE starting Chromium
xrandr --newmode "1280x400_60.00" 33.83 1280 1312 1440 1600 400 403 413 416 -hsync +vsync 2>/dev/null || true
xrandr --addmode HDMI-2 1280x400_60.00 2>/dev/null || true
xrandr --output HDMI-2 --mode 1280x400_60.00 --rotate normal

# Screen blanking
xset s 600 0
xset +dpms
xset dpms 600 0 0

# Get configuration
HDMI_SCN_ORIENT=$(moodeutl -q "SELECT value FROM cfg_system WHERE param='hdmi_scn_orient'")
DSI_SCN_TYPE=$(moodeutl -q "SELECT value FROM cfg_system WHERE param='dsi_scn_type'")

# Screen res
SCREEN_RES="1280,400"

# Get display type config
WEBUI_SHOW=$(moodeutl -q "SELECT value FROM cfg_system WHERE param='local_display'")
PEPPY_SHOW=$(moodeutl -q "SELECT value FROM cfg_system WHERE param='peppy_display'")
PEPPY_TYPE=$(moodeutl -q "SELECT value FROM cfg_system WHERE param='peppy_display_type'")

# Launch WebUI or Peppy
if [ "$WEBUI_SHOW" = "1" ]; then
    /var/www/util/sysutil.sh clearbrcache
    chromium \
    --app="http://localhost/" \
    --window-size="$SCREEN_RES" \
    --window-position="0,0" \
    --enable-features="OverlayScrollbar" \
    --no-first-run \
    --disable-infobars \
    --disable-session-crashed-bubble \
    --disable-gpu \
    --use-gl=swiftshader \
    --kiosk > /tmp/chromium-console.log 2>&1 &
    
    # Forum solution: Fix Chromium window size
    sleep 3
    WINDOW_ID=$(DISPLAY=:0 xdotool search --class chromium | head -1)
    if [ -n "$WINDOW_ID" ]; then
        DISPLAY=:0 xdotool windowsize $WINDOW_ID 1280 400
        DISPLAY=:0 xdotool windowmove $WINDOW_ID 0 0
    fi &
    
    wait
elif [ "$PEPPY_SHOW" = "1" ]; then
    if [ "$PEPPY_TYPE" = "meter" ]; then
        cd /opt/peppymeter && python3 peppymeter.py
    else
        cd /opt/peppyspectrum && python3 spectrum.py
    fi
fi
