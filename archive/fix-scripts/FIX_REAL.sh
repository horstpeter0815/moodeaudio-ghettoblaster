#!/bin/bash
# FIX FOR REAL - READ ACTUAL FILES AND FIX THEM
# sudo /Users/andrevollmer/moodeaudio-cursor/FIX_REAL.sh

SD_MOUNT="/Volumes/bootfs"
[ ! -d "$SD_MOUNT" ] && SD_MOUNT="/Volumes/boot"

echo "=== STEP 1: SSH FLAG ==="
sudo sh -c "echo '' > $SD_MOUNT/ssh"
sudo chmod 644 "$SD_MOUNT/ssh"
sync
sleep 1
if [ -f "$SD_MOUNT/ssh" ]; then
    echo "✅ SSH-Flag erstellt"
    ls -lh "$SD_MOUNT/ssh"
else
    echo "❌ SSH-Flag konnte nicht erstellt werden"
fi
echo ""

echo "=== STEP 2: DISPLAY ==="
CONFIG_FILE="$SD_MOUNT/config.txt"

# Read current file
CURRENT=$(cat "$CONFIG_FILE")

# Check if [pi5] exists
if echo "$CURRENT" | grep -q "^\[pi5\]"; then
    echo "✅ [pi5] Section vorhanden"
    # Remove old display_rotate and add new one
    echo "$CURRENT" | sudo awk '
        /^\[pi5\]/ { in_pi5=1; print; next }
        /^\[/ && in_pi5 { in_pi5=0 }
        in_pi5 && /^display_rotate=/ { next }
        /^\[pi5\]/ && !in_pi5 { print; print "display_rotate=2"; in_pi5=1; next }
        { print }
    ' > /tmp/config_new.txt
    # Fix: Add display_rotate after [pi5]
    sudo awk '/^\[pi5\]/ {print; print "display_rotate=2"; next} {print}' /tmp/config_new.txt > /tmp/config_final.txt
    sudo mv /tmp/config_final.txt "$CONFIG_FILE"
    sudo rm /tmp/config_new.txt
else
    echo "⚠️  [pi5] Section fehlt - füge hinzu"
    # Find where to insert
    if echo "$CURRENT" | grep -q "^# Device filters"; then
        echo "$CURRENT" | sudo awk '/^# Device filters$/ {print; print ""; print "[pi5]"; print "display_rotate=2"; next} {print}' > /tmp/config_new.txt
    else
        # Add at beginning
        echo -e "[pi5]\ndisplay_rotate=2\n\n$CURRENT" | sudo tee /tmp/config_new.txt > /dev/null
    fi
    sudo mv /tmp/config_new.txt "$CONFIG_FILE"
fi

sync
echo "✅ config.txt aktualisiert"
echo ""

echo "=== VERIFICATION ==="
[ -f "$SD_MOUNT/ssh" ] && echo "SSH: ✅" || echo "SSH: ❌"
grep -q "display_rotate=2" "$CONFIG_FILE" && echo "Display: ✅" || echo "Display: ❌"
grep -q "fbcon=rotate:3" "$SD_MOUNT/cmdline.txt" && echo "fbcon: ✅" || echo "fbcon: ❌"

