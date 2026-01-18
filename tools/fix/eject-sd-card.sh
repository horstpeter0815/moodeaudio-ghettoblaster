#!/bin/bash
# Safely eject SD card by closing all file handles

SD_MOUNT="/Volumes/rootfs"

if [ ! -d "$SD_MOUNT" ]; then
    echo "SD card not mounted at $SD_MOUNT"
    exit 0
fi

echo "=== Checking what's using the SD card ==="
lsof +D "$SD_MOUNT" 2>/dev/null | head -20

echo ""
echo "=== Attempting to close file handles ==="

# Find processes using the SD card
PIDS=$(lsof +D "$SD_MOUNT" 2>/dev/null | awk 'NR>1 {print $2}' | sort -u)

if [ -z "$PIDS" ]; then
    echo "✅ No processes found using SD card"
    echo "You can safely eject it now"
    exit 0
fi

echo "Found processes: $PIDS"
echo ""
echo "To close these processes, run:"
for PID in $PIDS; do
    CMD=$(ps -p $PID -o comm= 2>/dev/null)
    if [ -n "$CMD" ]; then
        echo "  kill $PID  # $CMD"
    fi
done

echo ""
echo "Or close all terminal windows/tabs that accessed the SD card"
echo ""
echo "After closing processes, eject with:"
echo "  diskutil eject /Volumes/rootfs"
echo ""
echo "Or use Finder: Right-click SD card → Eject"
