#!/bin/bash
# Start X11 on DSI Display
# Usage: sudo ./start_x11.sh

export DISPLAY=:0
export XAUTHORITY=/home/andre/.Xauthority

# Kill existing X server
pkill -9 Xorg 2>/dev/null

# Start X server on card1 (DSI)
sudo -u andre startx -- :0 -config /etc/X11/xorg.conf.d/99-dsi.conf vt7 2>&1 &

sleep 3

# Check if X is running
if pgrep -x Xorg > /dev/null; then
    echo "X11 started successfully on display :0"
    echo "You can now run: export DISPLAY=:0 && xterm"
else
    echo "X11 failed to start. Check logs: /var/log/Xorg.0.log"
fi

