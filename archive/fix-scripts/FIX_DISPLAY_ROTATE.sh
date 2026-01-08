#!/bin/bash
# FIX display_rotate=2 - RUN WITH SUDO
# sudo /Users/andrevollmer/moodeaudio-cursor/FIX_DISPLAY_ROTATE.sh

SD_MOUNT="/Volumes/bootfs"
[ ! -d "$SD_MOUNT" ] && SD_MOUNT="/Volumes/boot"
CONFIG_FILE="$SD_MOUNT/config.txt"

echo "=== FIX display_rotate=2 ==="
echo ""

# Read config
CURRENT=$(cat "$CONFIG_FILE")

# Add display_rotate=2 after [pi5]
NEW_CONFIG=$(echo "$CURRENT" | awk '/^\[pi5\]/ {print; print "display_rotate=2"; next} {print}')

# Write back
echo "$NEW_CONFIG" > "$CONFIG_FILE"
sync

# Verify
if awk '/^\[pi5\]/,/^\[/ {if (/^display_rotate=2/) print}' "$CONFIG_FILE" | grep -q "display_rotate=2"; then
    echo "✅ display_rotate=2 hinzugefügt"
    echo ""
    echo "[pi5] Section:"
    awk '/^\[pi5\]/,/^\[/ {if (/^\[/ && !/^\[pi5\]/) exit; print}' "$CONFIG_FILE"
else
    echo "❌ display_rotate=2 konnte nicht hinzugefügt werden"
    exit 1
fi

