#!/bin/bash
# FIX HEADER LINE 1 - CRITICAL FIX
# Zeile 1 MUSS "# This file is managed by moOde" sein, sonst überschreibt worker.php alles!
# sudo /Users/andrevollmer/moodeaudio-cursor/FIX_HEADER_LINE1.sh

SD_MOUNT="/Volumes/bootfs"
[ ! -d "$SD_MOUNT" ] && SD_MOUNT="/Volumes/boot"

if [ ! -d "$SD_MOUNT" ]; then
    echo "❌ SD-Karte nicht gefunden"
    exit 1
fi

CONFIG_FILE="$SD_MOUNT/config.txt"

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  🔧 FIX HEADER LINE 1 - CRITICAL                             ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

echo "=== PROBLEM ==="
echo "Zeile 1 MUSS sein: # This file is managed by moOde"
echo "Aktuell:"
head -1 "$CONFIG_FILE"
echo ""

if head -1 "$CONFIG_FILE" | grep -q "managed by moOde"; then
    echo "✅ Zeile 1 hat bereits Main Header"
else
    echo "❌ Zeile 1 hat KEINEN Main Header"
    echo ""
    echo "=== FIXE ZEILE 1 ==="
    
    # Backup
    cp "$CONFIG_FILE" "${CONFIG_FILE}.backup_$(date +%Y%m%d_%H%M%S)"
    
    # If line 1 is just comment chars, replace it
    if head -1 "$CONFIG_FILE" | grep -q "^#\+$"; then
        # Replace first line
        sed -i '' '1s/^.*$/# This file is managed by moOde/' "$CONFIG_FILE"
        echo "✅ Zeile 1 ersetzt"
    else
        # Insert at beginning
        sed -i '' '1i\
# This file is managed by moOde
' "$CONFIG_FILE"
        echo "✅ Main Header in Zeile 1 eingefügt"
    fi
    
    sync
fi

echo ""
echo "=== VERIFICATION ==="
LINE1=$(head -1 "$CONFIG_FILE")
echo "Zeile 1: $LINE1"
if echo "$LINE1" | grep -q "managed by moOde"; then
    echo "✅ Zeile 1 hat Main Header (korrekt)"
else
    echo "❌ Zeile 1 hat immer noch keinen Main Header"
    exit 1
fi

echo ""
HEADER_COUNT=$(grep -cE 'managed by moOde|Device filters|General settings|Do not alter|Audio overlays' "$CONFIG_FILE" 2>/dev/null || echo "0")
echo "Header-Count: $HEADER_COUNT/5"
if [ "$HEADER_COUNT" -eq 5 ]; then
    echo "✅ Alle 5 Headers vorhanden"
    echo ""
    echo "✅ FERTIG - worker.php wird config.txt NICHT überschreiben!"
else
    echo "⚠️  Headers fehlen noch"
fi

