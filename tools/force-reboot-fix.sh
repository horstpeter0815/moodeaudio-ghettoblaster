#!/bin/bash
# Force reboot when Pi is stuck
# Run: sudo bash force-reboot-fix.sh

echo "=== FORCING REBOOT ==="

# Kill any stuck services
echo "Stopping services forcefully..."
systemctl stop mpd.service --force 2>/dev/null || true
systemctl stop camilladsp.service --force 2>/dev/null || true
systemctl stop localdisplay.service --force 2>/dev/null || true
sleep 1

# Kill any remaining audio processes
killall -9 mpd 2>/dev/null || true
killall -9 camilladsp 2>/dev/null || true
killall -9 chromium 2>/dev/null || true
sleep 1

# Sync filesystems
sync
sleep 1

# Force immediate reboot
echo "Forcing reboot NOW..."
reboot -f

# If that doesn't work, use sysrq
sleep 2
echo b > /proc/sysrq-trigger
