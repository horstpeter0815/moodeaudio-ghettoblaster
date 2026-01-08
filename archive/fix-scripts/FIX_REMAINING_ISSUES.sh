#!/bin/bash
# FIX REMAINING ISSUES FROM TEST SUITE
# sudo /Users/andrevollmer/moodeaudio-cursor/FIX_REMAINING_ISSUES.sh

SD_MOUNT="/Volumes/bootfs"
[ ! -d "$SD_MOUNT" ] && SD_MOUNT="/Volumes/boot"

if [ ! -d "$SD_MOUNT" ]; then
    echo "❌ SD-Karte nicht gefunden"
    exit 1
fi

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  🔧 FIX REMAINING ISSUES                                     ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

################################################################################
# FIX 1: SSH FLAG
################################################################################

echo "=== FIX 1: SSH FLAG ==="
touch "$SD_MOUNT/ssh"
chmod 644 "$SD_MOUNT/ssh"
sync

if [ -f "$SD_MOUNT/ssh" ]; then
    echo "✅ SSH-Flag erstellt: $SD_MOUNT/ssh"
    ls -lh "$SD_MOUNT/ssh"
else
    echo "❌ SSH-Flag konnte nicht erstellt werden"
    exit 1
fi
echo ""

################################################################################
# FIX 2: display_rotate=2 IN [pi5] SECTION
################################################################################

echo "=== FIX 2: display_rotate=2 IN [pi5] SECTION ==="

CONFIG_FILE="$SD_MOUNT/config.txt"

# Check if [pi5] section exists
if grep -q "^\[pi5\]" "$CONFIG_FILE"; then
    echo "✅ [pi5] Section vorhanden"
    
    # Check if display_rotate already exists in [pi5] section
    DISPLAY_ROTATE=$(awk '/^\[pi5\]/,/^\[/ {if (/^display_rotate=/) print}' "$CONFIG_FILE" | head -1)
    
    if [ -n "$DISPLAY_ROTATE" ]; then
        if echo "$DISPLAY_ROTATE" | grep -q "display_rotate=2"; then
            echo "✅ display_rotate=2 bereits vorhanden: $DISPLAY_ROTATE"
        else
            echo "⚠️  display_rotate vorhanden, aber nicht 2: $DISPLAY_ROTATE"
            echo "Ersetze..."
            awk '/^\[pi5\]/,/^\[/ {if (/^display_rotate=/) {print "display_rotate=2"; next} print}' "$CONFIG_FILE" > /tmp/config_fixed.txt
            mv /tmp/config_fixed.txt "$CONFIG_FILE"
            echo "✅ display_rotate=2 gesetzt"
        fi
    else
        echo "⚠️  display_rotate fehlt in [pi5] Section"
        echo "Füge hinzu..."
        awk '/^\[pi5\]/ {print; print "display_rotate=2"; next} {print}' "$CONFIG_FILE" > /tmp/config_fixed.txt
        mv /tmp/config_fixed.txt "$CONFIG_FILE"
        echo "✅ display_rotate=2 hinzugefügt"
    fi
else
    echo "❌ [pi5] Section fehlt"
    echo "Füge [pi5] Section mit display_rotate=2 hinzu..."
    awk '/^# Device filters$/ {print; print ""; print "[pi5]"; print "display_rotate=2"; next} {print}' "$CONFIG_FILE" > /tmp/config_fixed.txt
    mv /tmp/config_fixed.txt "$CONFIG_FILE"
    echo "✅ [pi5] Section mit display_rotate=2 hinzugefügt"
fi

sync
echo ""

################################################################################
# VERIFICATION
################################################################################

echo "=== VERIFICATION ==="
echo ""

[ -f "$SD_MOUNT/ssh" ] && echo "✅ SSH-Flag" || echo "❌ SSH-Flag"
DISPLAY_ROTATE=$(awk '/^\[pi5\]/,/^\[/ {if (/^display_rotate=2/) print}' "$CONFIG_FILE" | head -1)
[ -n "$DISPLAY_ROTATE" ] && echo "✅ display_rotate=2" || echo "❌ display_rotate=2"

echo ""
echo "✅ FERTIG - Führe Test Suite erneut aus:"
echo "  ./tools/test/complete-verification.sh"

