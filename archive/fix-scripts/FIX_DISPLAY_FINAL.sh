#!/bin/bash
# FIX display_rotate - remove duplicates - RUN WITH SUDO
# sudo /Users/andrevollmer/moodeaudio-cursor/FIX_DISPLAY_FINAL.sh

SD_MOUNT="/Volumes/bootfs"
[ ! -d "$SD_MOUNT" ] && SD_MOUNT="/Volumes/boot"
CONFIG_FILE="$SD_MOUNT/config.txt"

echo "=== FIX display_rotate=2 (remove duplicates) ==="
echo ""

# Remove all display_rotate from [pi5] section
awk '
    /^\[pi5\]/ {
        in_pi5=1
        print
        next
    }
    /^\[/ {
        in_pi5=0
    }
    in_pi5 && /^display_rotate=/ {
        next
    }
    {
        print
    }
    END {
        if (in_pi5) {
            print "display_rotate=2"
        }
    }
' "$CONFIG_FILE" > /tmp/config_fixed.txt

# Add display_rotate=2 after [pi5] if not already there
if ! grep -A 5 "^\[pi5\]" /tmp/config_fixed.txt | grep -q "^display_rotate=2"; then
    awk '/^\[pi5\]/ {print; print "display_rotate=2"; next} {print}' /tmp/config_fixed.txt > /tmp/config_fixed2.txt
    mv /tmp/config_fixed2.txt /tmp/config_fixed.txt
fi

# Write back
cp /tmp/config_fixed.txt "$CONFIG_FILE"
sync

# Verify
echo "Neue [pi5] Section:"
awk '/^\[pi5\]/,/^\[/ {if (/^\[/ && !/^\[pi5\]/) exit; print}' "$CONFIG_FILE"
echo ""

if awk '/^\[pi5\]/,/^\[/ {if (/^display_rotate=2/) print}' "$CONFIG_FILE" | grep -q "display_rotate=2"; then
    echo "✅ display_rotate=2 korrekt gesetzt (keine Duplikate)"
else
    echo "❌ display_rotate=2 nicht gefunden"
    exit 1
fi

