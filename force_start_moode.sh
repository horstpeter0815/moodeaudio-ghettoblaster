#!/bin/bash
# Force Start Moode - Emergency Fix
# Run this if nothing else works

set -e

echo "=========================================="
echo "Force Starting Moode Display"
echo "=========================================="
echo ""

# Kill everything
echo "Killing all X11 and Chromium processes..."
pkill -9 X 2>/dev/null || true
pkill -9 Xorg 2>/dev/null || true
pkill -9 chromium 2>/dev/null || true
pkill -9 startx 2>/dev/null || true
sleep 2
echo "✅ All processes killed"
echo ""

# Disable display manager if running
echo "Disabling display manager..."
sudo systemctl stop lightdm 2>/dev/null || true
sudo systemctl stop gdm 2>/dev/null || true
sudo systemctl disable lightdm 2>/dev/null || true
sudo systemctl disable gdm 2>/dev/null || true
echo "✅ Display manager disabled"
echo ""

# Ensure xinitrc
echo "Ensuring xinitrc..."
XINITRC="$HOME/.xinitrc"
if [ ! -f "$XINITRC" ] || ! grep -q "chromium" "$XINITRC"; then
    ./fix_login_screen.sh
fi
echo ""

# Start X11 directly
echo "Starting X11..."
export DISPLAY=:0
fuser -k /dev/tty7 2>/dev/null || true
sleep 1

# Start X11
startx > /tmp/startx.log 2>&1 &
XPID=$!
sleep 8

# Check if started
if pgrep -x "X" > /dev/null || pgrep -x "Xorg" > /dev/null; then
    echo "✅ X11 started (PID: $XPID)"
else
    echo "❌ X11 failed to start"
    echo "   Check: cat /tmp/startx.log"
    exit 1
fi
echo ""

# Wait for Chromium
echo "Waiting for Chromium to start..."
for i in {1..10}; do
    if pgrep -f "chromium" > /dev/null; then
        echo "✅ Chromium started!"
        break
    fi
    echo "   Waiting... ($i/10)"
    sleep 2
done

if ! pgrep -f "chromium" > /dev/null; then
    echo "⚠️  Chromium not started"
    echo "   Check xinitrc: cat ~/.xinitrc"
    echo "   Check X11 logs: cat ~/.xsession-errors"
fi
echo ""

# Final status
echo "=========================================="
echo "Final Status"
echo "=========================================="
echo "X11: $(pgrep -x X > /dev/null && echo '✅ Running' || echo '❌ Not running')"
echo "Chromium: $(pgrep -f chromium > /dev/null && echo '✅ Running' || echo '❌ Not running')"
echo ""
echo "If Chromium is running, Moode should be visible!"
echo ""

