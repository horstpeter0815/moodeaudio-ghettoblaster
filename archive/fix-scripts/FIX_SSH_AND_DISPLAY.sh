#!/bin/bash
# FIX SSH FLAG AND DISPLAY - RUN WITH SUDO
# sudo /Users/andrevollmer/moodeaudio-cursor/FIX_SSH_AND_DISPLAY.sh

SD_MOUNT="/Volumes/bootfs"
[ ! -d "$SD_MOUNT" ] && SD_MOUNT="/Volumes/boot"

if [ ! -d "$SD_MOUNT" ]; then
    echo "❌ SD-Karte nicht gefunden"
    exit 1
fi

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  🔧 FIX SSH FLAG AND DISPLAY                                ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

################################################################################
# FIX 1: SSH FLAG (with explicit sudo commands)
################################################################################

echo "=== FIX 1: SSH FLAG ==="

# Try multiple methods
if sudo touch "$SD_MOUNT/ssh" 2>/dev/null; then
    sudo chmod 644 "$SD_MOUNT/ssh"
    sync
    if [ -f "$SD_MOUNT/ssh" ]; then
        echo "✅ SSH-Flag erstellt: $SD_MOUNT/ssh"
        ls -lh "$SD_MOUNT/ssh"
        SSH_OK=true
    else
        echo "❌ SSH-Flag konnte nicht erstellt werden (Datei existiert nicht nach touch)"
        SSH_OK=false
    fi
else
    echo "❌ Konnte SSH-Flag nicht erstellen (touch fehlgeschlagen)"
    echo "   Versuche alternative Methode..."
    
    # Alternative: Use echo
    if echo "" | sudo tee "$SD_MOUNT/ssh" > /dev/null 2>&1; then
        sudo chmod 644 "$SD_MOUNT/ssh"
        sync
        if [ -f "$SD_MOUNT/ssh" ]; then
            echo "✅ SSH-Flag erstellt (alternative Methode)"
            ls -lh "$SD_MOUNT/ssh"
            SSH_OK=true
        else
            echo "❌ Alternative Methode fehlgeschlagen"
            SSH_OK=false
        fi
    else
        echo "❌ Alle Methoden fehlgeschlagen"
        SSH_OK=false
    fi
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
    
    # Remove existing display_rotate from [pi5] section
    awk '/^\[pi5\]/,/^\[/ {if (/^display_rotate=/) next; print} /^\[pi5\]/ {print; print "display_rotate=2"; next} {print}' "$CONFIG_FILE" > /tmp/config_fixed.txt
    
    # Add display_rotate=2 after [pi5] if not already there
    if ! grep -A 5 "^\[pi5\]" /tmp/config_fixed.txt | grep -q "^display_rotate=2"; then
        awk '/^\[pi5\]/ {print; print "display_rotate=2"; next} {print}' /tmp/config_fixed.txt > /tmp/config_fixed2.txt
        mv /tmp/config_fixed2.txt /tmp/config_fixed.txt
    fi
    
    sudo mv /tmp/config_fixed.txt "$CONFIG_FILE"
    sync
    
    # Verify
    DISPLAY_ROTATE=$(awk '/^\[pi5\]/,/^\[/ {if (/^display_rotate=2/) print}' "$CONFIG_FILE" | head -1)
    if [ -n "$DISPLAY_ROTATE" ]; then
        echo "✅ display_rotate=2 gesetzt: $DISPLAY_ROTATE"
        DISPLAY_OK=true
    else
        echo "❌ display_rotate=2 konnte nicht gesetzt werden"
        DISPLAY_OK=false
    fi
else
    echo "⚠️  [pi5] Section fehlt - füge hinzu..."
    awk '/^# Device filters$/ {print; print ""; print "[pi5]"; print "display_rotate=2"; next} {print}' "$CONFIG_FILE" > /tmp/config_fixed.txt
    sudo mv /tmp/config_fixed.txt "$CONFIG_FILE"
    sync
    
    if grep -q "^\[pi5\]" "$CONFIG_FILE"; then
        echo "✅ [pi5] Section mit display_rotate=2 hinzugefügt"
        DISPLAY_OK=true
    else
        echo "❌ [pi5] Section konnte nicht hinzugefügt werden"
        DISPLAY_OK=false
    fi
fi
echo ""

################################################################################
# VERIFICATION
################################################################################

echo "=== VERIFICATION ==="
echo ""

[ "$SSH_OK" = true ] && echo "✅ SSH-Flag" || echo "❌ SSH-Flag"
[ "$DISPLAY_OK" = true ] && echo "✅ display_rotate=2" || echo "❌ display_rotate=2"

echo ""
if [ "$SSH_OK" = true ] && [ "$DISPLAY_OK" = true ]; then
    echo "✅ ALLES FERTIG!"
    echo ""
    echo "Führe Test Suite aus:"
    echo "  ./tools/test/complete-verification.sh"
else
    echo "⚠️  Es gibt noch Probleme"
    exit 1
fi

