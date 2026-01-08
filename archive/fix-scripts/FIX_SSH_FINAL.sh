#!/bin/bash
# FIX SSH - WITH ABSOLUTE PATHS
# sudo /Users/andrevollmer/moodeaudio-cursor/FIX_SSH_FINAL.sh

SD_MOUNT="/Volumes/bootfs"
[ ! -d "$SD_MOUNT" ] && SD_MOUNT="/Volumes/boot"

if [ ! -d "$SD_MOUNT" ]; then
    echo "❌ SD-Karte nicht gefunden"
    exit 1
fi

CONFIG_FILE="$SD_MOUNT/config.txt"
CMDLINE_FILE="$SD_MOUNT/cmdline.txt"
SSH_FLAG="$SD_MOUNT/ssh"

echo "=== FIX SSH ==="
sudo touch "$SSH_FLAG"
sudo chmod 644 "$SSH_FLAG"
sync
[ -f "$SSH_FLAG" ] && echo "✅ SSH-Flag erstellt" || echo "❌ SSH-Flag fehlt"

echo ""
echo "=== FIX DISPLAY ==="
if grep -q "^\[pi5\]" "$CONFIG_FILE"; then
    sudo awk '/^\[pi5\]/,/^\[/ {if (/^display_rotate=/) next; print} /^\[pi5\]/ {print; print "display_rotate=2"; next} {print}' "$CONFIG_FILE" > /tmp/config_fixed.txt
    sudo mv /tmp/config_fixed.txt "$CONFIG_FILE"
else
    sudo awk '/^# Device filters$/ {print; print ""; print "[pi5]"; print "display_rotate=2"; next} {print}' "$CONFIG_FILE" > /tmp/config_fixed.txt
    sudo mv /tmp/config_fixed.txt "$CONFIG_FILE"
fi
echo "✅ display_rotate=2 gesetzt"

CMDLINE=$(cat "$CMDLINE_FILE")
CMDLINE=$(echo "$CMDLINE" | sed 's/ fbcon=rotate:[0-9]//g')
if ! echo "$CMDLINE" | grep -q "fbcon=rotate:3"; then
    CMDLINE="${CMDLINE} fbcon=rotate:3"
fi
echo "$CMDLINE" | sudo tee "$CMDLINE_FILE" > /dev/null
echo "✅ fbcon=rotate:3 gesetzt"

sync
echo ""
echo "=== VERIFICATION ==="
[ -f "$SSH_FLAG" ] && echo "✅ SSH-Flag" || echo "❌ SSH-Flag"
grep -q "display_rotate=2" "$CONFIG_FILE" && echo "✅ display_rotate=2" || echo "❌ display_rotate=2"
grep -q "fbcon=rotate:3" "$CMDLINE_FILE" && echo "✅ fbcon=rotate:3" || echo "❌ fbcon=rotate:3"
echo ""
echo "✅ FERTIG"

