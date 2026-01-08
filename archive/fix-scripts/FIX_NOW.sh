#!/bin/bash
# FIX SSH AND DISPLAY - RUN WITH SUDO
# sudo /Users/andrevollmer/moodeaudio-cursor/FIX_NOW.sh

SD_MOUNT="/Volumes/bootfs"
[ ! -d "$SD_MOUNT" ] && SD_MOUNT="/Volumes/boot"

echo "=== FIX SSH ==="
touch "$SD_MOUNT/ssh"
chmod 644 "$SD_MOUNT/ssh"
sync
[ -f "$SD_MOUNT/ssh" ] && echo "✅ SSH-Flag" || echo "❌ SSH-Flag"

echo ""
echo "=== FIX DISPLAY ==="
if [ -f "$SD_MOUNT/config.txt" ]; then
    if ! grep -q "^display_rotate=2" "$SD_MOUNT/config.txt"; then
        if grep -q "^\[pi5\]" "$SD_MOUNT/config.txt"; then
            awk '/^\[pi5\]/ {print; print "display_rotate=2"; next} {print}' "$SD_MOUNT/config.txt" > /tmp/cfg.txt
            mv /tmp/cfg.txt "$SD_MOUNT/config.txt"
        else
            echo "" >> "$SD_MOUNT/config.txt"
            echo "[pi5]" >> "$SD_MOUNT/config.txt"
            echo "display_rotate=2" >> "$SD_MOUNT/config.txt"
        fi
    fi
    echo "✅ display_rotate=2"
fi

if [ -f "$SD_MOUNT/cmdline.txt" ]; then
    CMDLINE=$(cat "$SD_MOUNT/cmdline.txt")
    CMDLINE=$(echo "$CMDLINE" | sed 's/ fbcon=rotate:[0-9]//g')
    if ! echo "$CMDLINE" | grep -q "fbcon=rotate:3"; then
        CMDLINE="${CMDLINE} fbcon=rotate:3"
    fi
    echo "$CMDLINE" > "$SD_MOUNT/cmdline.txt"
    echo "✅ fbcon=rotate:3"
fi

sync
echo ""
echo "✅ FERTIG"

