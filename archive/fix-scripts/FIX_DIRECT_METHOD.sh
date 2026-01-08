#!/bin/bash
# FIX WITH DIRECT METHOD - RUN WITH SUDO
# sudo /Users/andrevollmer/moodeaudio-cursor/FIX_DIRECT_METHOD.sh

SD_MOUNT="/Volumes/bootfs"
[ ! -d "$SD_MOUNT" ] && SD_MOUNT="/Volumes/boot"

if [ ! -d "$SD_MOUNT" ]; then
    echo "❌ SD-Karte nicht gefunden"
    exit 1
fi

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  🔧 FIX WITH DIRECT METHOD                                   ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

################################################################################
# FIX 1: SSH FLAG (direct method)
################################################################################

echo "=== FIX 1: SSH FLAG ==="

# Method 1: echo to file
if echo "" | tee "$SD_MOUNT/ssh" > /dev/null 2>&1; then
    chmod 644 "$SD_MOUNT/ssh"
    sync
    if [ -f "$SD_MOUNT/ssh" ]; then
        echo "✅ SSH-Flag erstellt (Methode 1)"
        ls -lh "$SD_MOUNT/ssh"
        SSH_OK=true
    else
        SSH_OK=false
    fi
else
    SSH_OK=false
fi

# If method 1 failed, try method 2
if [ "$SSH_OK" != true ]; then
    if printf "" > "$SD_MOUNT/ssh" 2>/dev/null; then
        chmod 644 "$SD_MOUNT/ssh"
        sync
        if [ -f "$SD_MOUNT/ssh" ]; then
            echo "✅ SSH-Flag erstellt (Methode 2)"
            ls -lh "$SD_MOUNT/ssh"
            SSH_OK=true
        fi
    fi
fi

if [ "$SSH_OK" != true ]; then
    echo "❌ SSH-Flag konnte nicht erstellt werden"
    echo "   SD-Karte könnte schreibgeschützt sein"
    echo "   Versuche: SD-Karte auswerfen und neu einstecken"
fi
echo ""

################################################################################
# FIX 2: display_rotate=2 (direct method)
################################################################################

echo "=== FIX 2: display_rotate=2 ==="

CONFIG_FILE="$SD_MOUNT/config.txt"

if [ ! -f "$CONFIG_FILE" ]; then
    echo "❌ config.txt nicht gefunden"
    DISPLAY_OK=false
else
    # Read current config
    CURRENT=$(cat "$CONFIG_FILE")
    
    # Check if [pi5] section exists
    if echo "$CURRENT" | grep -q "^\[pi5\]"; then
        echo "✅ [pi5] Section vorhanden"
        
        # Remove old display_rotate and add new one
        NEW_CONFIG=$(echo "$CURRENT" | awk '
            /^\[pi5\]/ { 
                print; 
                in_pi5=1; 
                next 
            }
            /^\[/ && in_pi5 { 
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
        ')
        
        # Add display_rotate=2 after [pi5] if not already there
        if ! echo "$NEW_CONFIG" | grep -A 5 "^\[pi5\]" | grep -q "^display_rotate=2"; then
            NEW_CONFIG=$(echo "$NEW_CONFIG" | awk '/^\[pi5\]/ {print; print "display_rotate=2"; next} {print}')
        fi
        
        # Write back
        echo "$NEW_CONFIG" > /tmp/config_fixed.txt
        cp /tmp/config_fixed.txt "$CONFIG_FILE"
        sync
        
        # Verify
        DISPLAY_ROTATE=$(awk '/^\[pi5\]/,/^\[/ {if (/^display_rotate=2/) print}' "$CONFIG_FILE" | head -1)
        if [ -n "$DISPLAY_ROTATE" ]; then
            echo "✅ display_rotate=2 gesetzt: $DISPLAY_ROTATE"
            DISPLAY_OK=true
        else
            echo "❌ display_rotate=2 konnte nicht gesetzt werden"
            echo "   Aktueller Inhalt der [pi5] Section:"
            grep -A 5 "^\[pi5\]" "$CONFIG_FILE" | head -10
            DISPLAY_OK=false
        fi
    else
        echo "⚠️  [pi5] Section fehlt - füge hinzu..."
        # Find insertion point
        if echo "$CURRENT" | grep -q "^# Device filters"; then
            NEW_CONFIG=$(echo "$CURRENT" | awk '/^# Device filters$/ {print; print ""; print "[pi5]"; print "display_rotate=2"; next} {print}')
        else
            NEW_CONFIG=$(echo -e "[pi5]\ndisplay_rotate=2\n\n$CURRENT")
        fi
        
        echo "$NEW_CONFIG" > /tmp/config_fixed.txt
        cp /tmp/config_fixed.txt "$CONFIG_FILE"
        sync
        
        if grep -q "^\[pi5\]" "$CONFIG_FILE"; then
            echo "✅ [pi5] Section mit display_rotate=2 hinzugefügt"
            DISPLAY_OK=true
        else
            echo "❌ [pi5] Section konnte nicht hinzugefügt werden"
            DISPLAY_OK=false
        fi
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
    echo ""
    echo "Falls SSH-Flag nicht erstellt werden kann:"
    echo "  1. SD-Karte auswerfen"
    echo "  2. SD-Karte neu einstecken"
    echo "  3. Script erneut ausführen"
    exit 1
fi

