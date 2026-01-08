#!/bin/bash
# Create SSH flag file on mounted SD card
# Run this manually with appropriate permissions

SD_MOUNT="/Volumes/bootfs"
[ ! -d "$SD_MOUNT" ] && SD_MOUNT="/Volumes/boot"

if [ ! -d "$SD_MOUNT" ]; then
    echo "❌ SD card not found at $SD_MOUNT"
    exit 1
fi

echo "Creating SSH flag on $SD_MOUNT..."

# Try without sudo first
if touch "$SD_MOUNT/ssh" 2>/dev/null; then
    chmod 644 "$SD_MOUNT/ssh" 2>/dev/null
    sync
    echo "✅ SSH flag created: $SD_MOUNT/ssh"
    exit 0
fi

# If that fails, need sudo
echo "Need sudo permissions..."
echo "Run: sudo touch $SD_MOUNT/ssh && sudo chmod 644 $SD_MOUNT/ssh && sync"


