#!/bin/bash
# Simple X11 startup for DSI display
export DISPLAY=:0
X :0 -config /etc/X11/xorg.conf.d/99-dsi.conf &
sleep 2
matchbox-window-manager &
xterm -fullscreen -bg black -fg white &

