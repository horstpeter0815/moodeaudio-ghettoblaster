#!/bin/bash
# FIX FINAL - RUN WITH SUDO
# sudo /Users/andrevollmer/moodeaudio-cursor/FIX_FINAL.sh

SD_MOUNT="/Volumes/bootfs"
[ ! -d "$SD_MOUNT" ] && SD_MOUNT="/Volumes/boot"

if [ ! -d "$SD_MOUNT" ]; then
    echo "❌ SD-Karte nicht gefunden"
    exit 1
fi

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  🔧 FIX FINAL                                                 ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

################################################################################
# FIX 1: SSH FLAG (remove directory if exists, create file)
################################################################################

echo "=== FIX 1: SSH FLAG ==="

SSH_PATH="$SD_MOUNT/ssh"

# Check if it's a directory
if [ -d "$SSH_PATH" ]; then
    echo "⚠️  $SSH_PATH ist ein Verzeichnis - lösche es..."
    rm -rf "$SSH_PATH"
fi

# Create empty file
if printf "" > "$SSH_PATH" 2>/dev/null; then
    chmod 644 "$SSH_PATH"
    sync
    if [ -f "$SSH_PATH" ]; then
        echo "✅ SSH-Flag erstellt: $SSH_PATH"
        ls -lh "$SSH_PATH"
        SSH_OK=true
    else
        echo "❌ SSH-Flag konnte nicht erstellt werden"
        SSH_OK=false
    fi
else
    echo "❌ SSH-Flag konnte nicht erstellt werden"
    SSH_OK=false
fi
echo ""

################################################################################
# FIX 2: display_rotate=2 (fix duplicate [pi5] sections)
################################################################################

echo "=== FIX 2: display_rotate=2 ==="

CONFIG_FILE="$SD_MOUNT/config.txt"

if [ ! -f "$CONFIG_FILE" ]; then
    echo "❌ config.txt nicht gefunden"
    DISPLAY_OK=false
else
    # Check for duplicate [pi5] sections
    PI5_COUNT=$(grep -c "^\[pi5\]" "$CONFIG_FILE" || echo "0")
    
    if [ "$PI5_COUNT" -gt 1 ]; then
        echo "⚠️  $PI5_COUNT [pi5] Sections gefunden - entferne Duplikate..."
        
        # Remove duplicates - keep only first [pi5] section
        awk '
            /^\[pi5\]/ {
                if (pi5_seen) {
                    skip_section=1
                    next
                }
                pi5_seen=1
                print
                next
            }
            /^\[/ {
                skip_section=0
            }
            !skip_section {
                print
            }
        ' "$CONFIG_FILE" > /tmp/config_fixed.txt
        
        cp /tmp/config_fixed.txt "$CONFIG_FILE"
        sync
        echo "✅ Duplikate entfernt"
    fi
    
    # Check if display_rotate=2 exists in [pi5] section
    DISPLAY_ROTATE=$(awk '/^\[pi5\]/,/^\[/ {if (/^display_rotate=2/) print}' "$CONFIG_FILE" | head -1)
    
    if [ -n "$DISPLAY_ROTATE" ]; then
        echo "✅ display_rotate=2 bereits vorhanden: $DISPLAY_ROTATE"
        DISPLAY_OK=true
    else
        echo "⚠️  display_rotate=2 fehlt - füge hinzu..."
        
        # Add display_rotate=2 after [pi5]
        awk '/^\[pi5\]/ {print; print "display_rotate=2"; next} {print}' "$CONFIG_FILE" > /tmp/config_fixed.txt
        cp /tmp/config_fixed.txt "$CONFIG_FILE"
        sync
        
        # Verify
        DISPLAY_ROTATE=$(awk '/^\[pi5\]/,/^\[/ {if (/^display_rotate=2/) print}' "$CONFIG_FILE" | head -1)
        if [ -n "$DISPLAY_ROTATE" ]; then
            echo "✅ display_rotate=2 hinzugefügt: $DISPLAY_ROTATE"
            DISPLAY_OK=true
        else
            echo "❌ display_rotate=2 konnte nicht hinzugefügt werden"
            DISPLAY_OK=false
        fi
    fi
    
    # Show [pi5] section
    echo ""
    echo "Aktuelle [pi5] Section:"
    awk '/^\[pi5\]/,/^\[/ {if (/^\[/ && !/^\[pi5\]/) exit; print}' "$CONFIG_FILE" | head -10
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

