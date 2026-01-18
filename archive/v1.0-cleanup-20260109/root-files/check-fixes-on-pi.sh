#!/bin/bash
################################################################################
# PRÜFE OB FIXES FUNKTIONIERT HABEN - Auf dem Pi ausführen
################################################################################

echo "=== PRÜFE OB FIXES FUNKTIONIERT HABEN ==="
echo ""

CONFIG="/boot/firmware/config.txt"
WORKER="/var/www/daemon/worker.php"

# Prüfe config.txt
echo "=== PRÜFE config.txt ==="
if [ -f "$CONFIG" ]; then
    echo "Zeile 1: '$(head -1 "$CONFIG")'"
    echo "Zeile 2: '$(sed -n '2p' "$CONFIG")'"
    echo ""
    
    if sed -n '2p' "$CONFIG" | grep -q "This file is managed by moOde"; then
        echo "✅ Main Header in Zeile 2 (wird erkannt)"
    else
        echo "❌ Main Header NICHT in Zeile 2"
    fi
    
    HEADER_COUNT=0
    grep -q "^# This file is managed by moOde" "$CONFIG" && HEADER_COUNT=$((HEADER_COUNT+1))
    grep -q "^# Device filters" "$CONFIG" && HEADER_COUNT=$((HEADER_COUNT+1))
    grep -q "^# General settings" "$CONFIG" && HEADER_COUNT=$((HEADER_COUNT+1))
    grep -q "^# Do not alter this section" "$CONFIG" && HEADER_COUNT=$((HEADER_COUNT+1))
    grep -q "^# Audio overlays" "$CONFIG" && HEADER_COUNT=$((HEADER_COUNT+1))
    
    echo "Header Count: $HEADER_COUNT/5"
    
    if grep -q "display_rotate=2" "$CONFIG"; then
        echo "✅ display_rotate=2 vorhanden"
    else
        echo "❌ display_rotate=2 FEHLT"
    fi
else
    echo "❌ config.txt nicht gefunden"
fi
echo ""

# Prüfe worker.php
echo "=== PRÜFE worker.php ==="
if [ -f "$WORKER" ]; then
    if grep -q "PERMANENT FIX" "$WORKER"; then
        echo "✅ worker.php hat PERMANENT FIX"
        grep "PERMANENT FIX" "$WORKER" | head -2
    else
        echo "❌ worker.php hat KEINEN PERMANENT FIX"
        echo "   → config.txt wird überschrieben!"
    fi
    
    if grep -q "chkBootConfigTxt()" "$WORKER" && ! grep -q "DISABLED" "$WORKER"; then
        echo "❌ chkBootConfigTxt() ist noch aktiv"
    else
        echo "✅ chkBootConfigTxt() ist deaktiviert"
    fi
else
    echo "❌ worker.php nicht gefunden"
fi
echo ""

echo "=== ZUSAMMENFASSUNG ==="
echo ""
if [ -f "$CONFIG" ] && sed -n '2p' "$CONFIG" | grep -q "This file is managed by moOde" && grep -q "display_rotate=2" "$CONFIG" && [ -f "$WORKER" ] && grep -q "PERMANENT FIX" "$WORKER"; then
    echo "✅ ALLE FIXES FUNKTIONIEREN!"
    echo "   → config.txt wurde NICHT überschrieben"
    echo "   → worker.php hat Fixes"
    echo "   → display_rotate=2 vorhanden"
else
    echo "❌ EINIGE FIXES FUNKTIONIEREN NICHT"
    echo "   → Bitte prüfe die Fehlermeldungen oben"
fi
echo ""

