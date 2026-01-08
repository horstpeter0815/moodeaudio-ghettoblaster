#!/bin/bash
# FIX DIRECTLY - NO CHECKS, JUST DO IT
# sudo /Users/andrevollmer/moodeaudio-cursor/FIX_DIRECT.sh

SD_MOUNT="/Volumes/bootfs"
[ ! -d "$SD_MOUNT" ] && SD_MOUNT="/Volumes/boot"

echo "=== CREATE SSH FLAG ==="
sudo sh -c "touch $SD_MOUNT/ssh && chmod 644 $SD_MOUNT/ssh"
sync
echo ""

echo "=== FIX DISPLAY ==="
CONFIG_FILE="$SD_MOUNT/config.txt"
if grep -q "^\[pi5\]" "$CONFIG_FILE"; then
    sudo awk '/^\[pi5\]/,/^\[/ {if (/^display_rotate=/) next; print} /^\[pi5\]/ {print; print "display_rotate=2"; next} {print}' "$CONFIG_FILE" > /tmp/cfg.tmp && sudo mv /tmp/cfg.tmp "$CONFIG_FILE"
else
    sudo awk '/^# Device filters$/ {print; print ""; print "[pi5]"; print "display_rotate=2"; next} {print}' "$CONFIG_FILE" > /tmp/cfg.tmp && sudo mv /tmp/cfg.tmp "$CONFIG_FILE"
fi

CMDLINE_FILE="$SD_MOUNT/cmdline.txt"
CMDLINE=$(cat "$CMDLINE_FILE")
CMDLINE=$(echo "$CMDLINE" | sed 's/ fbcon=rotate:[0-9]//g')
if ! echo "$CMDLINE" | grep -q "fbcon=rotate:3"; then
    CMDLINE="${CMDLINE} fbcon=rotate:3"
fi
echo "$CMDLINE" | sudo tee "$CMDLINE_FILE" > /dev/null
sync
echo ""

echo "=== CHECK ==="
[ -f "$SD_MOUNT/ssh" ] && echo "SSH: ✅" || echo "SSH: ❌"
grep -q "display_rotate=2" "$CONFIG_FILE" && echo "Display: ✅" || echo "Display: ❌"
grep -q "fbcon=rotate:3" "$CMDLINE_FILE" && echo "fbcon: ✅" || echo "fbcon: ❌"

