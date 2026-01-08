#!/bin/bash
################################################################################
# PRÜFE OB FIXES FUNKTIONIERT HABEN
#
# Prüft nach Boot:
# 1. Ist config.txt noch korrekt? (Header in Zeile 2, display_rotate=2)
# 2. Hat worker.php noch die Fixes? (Overwrite deaktiviert)
# 3. Wurde config.txt überschrieben?
################################################################################

set -e

echo "=== PRÜFE OB FIXES FUNKTIONIERT HABEN ==="
echo ""

# Prüfe ob Pi online ist
PI_IP=""
PI_USER="andre"
PI_PASS="0815"

# Versuche verschiedene IPs
# ⚠️ WICHTIG: 192.168.1.101 ist der FREMDE WLAN-ROUTER, NICHT der Pi!
for ip in "192.168.10.2" "192.168.1.100" "moodepi5.local" "GhettoBlaster.local"; do
    # ⚠️ KRITISCH: .101 ist der fremde Router, NICHT der Pi!
    if echo "$ip" | grep -q "\.101$"; then
        echo "⚠️  Überspringe $ip (fremder WLAN-Router, NICHT der Pi!)"
        continue
    fi
    if ping -c 1 -W 1 "$ip" >/dev/null 2>&1; then
        PI_IP="$ip"
        break
    fi
done

if [ -z "$PI_IP" ]; then
    echo "❌ Pi nicht gefunden"
    echo ""
    echo "Bitte manuell prüfen:"
    echo "  1. SSH zum Pi: ssh andre@<PI_IP>"
    echo "  2. Prüfe config.txt: head -3 /boot/firmware/config.txt"
    echo "  3. Prüfe worker.php: grep -A 2 'PERMANENT FIX' /var/www/daemon/worker.php"
    exit 1
fi

echo "✅ Pi gefunden: $PI_IP"
echo ""

# Prüfe config.txt
echo "=== PRÜFE config.txt ==="
CONFIG_CHECK=$(sshpass -p "$PI_PASS" ssh -o StrictHostKeyChecking=no "$PI_USER@$PI_IP" << 'EOF'
CONFIG="/boot/firmware/config.txt"
echo "Zeile 1: '$(head -1 "$CONFIG")'"
echo "Zeile 2: '$(sed -n '2p' "$CONFIG")'"
echo ""
if sed -n '2p' "$CONFIG" | grep -q "This file is managed by moOde"; then
    echo "✅ Main Header in Zeile 2"
else
    echo "❌ Main Header NICHT in Zeile 2"
fi
echo ""
if grep -q "display_rotate=2" "$CONFIG"; then
    echo "✅ display_rotate=2 vorhanden"
else
    echo "❌ display_rotate=2 FEHLT"
fi
echo ""
HEADER_COUNT=0
grep -q "^# This file is managed by moOde" "$CONFIG" && HEADER_COUNT=$((HEADER_COUNT+1))
grep -q "^# Device filters" "$CONFIG" && HEADER_COUNT=$((HEADER_COUNT+1))
grep -q "^# General settings" "$CONFIG" && HEADER_COUNT=$((HEADER_COUNT+1))
grep -q "^# Do not alter this section" "$CONFIG" && HEADER_COUNT=$((HEADER_COUNT+1))
grep -q "^# Audio overlays" "$CONFIG" && HEADER_COUNT=$((HEADER_COUNT+1))
echo "Header Count: $HEADER_COUNT/5"
EOF
)

echo "$CONFIG_CHECK"
echo ""

# Prüfe worker.php
echo "=== PRÜFE worker.php ==="
WORKER_CHECK=$(sshpass -p "$PI_PASS" ssh -o StrictHostKeyChecking=no "$PI_USER@$PI_IP" << 'EOF'
WORKER="/var/www/daemon/worker.php"
if grep -q "PERMANENT FIX" "$WORKER"; then
    echo "✅ worker.php hat PERMANENT FIX"
    grep "PERMANENT FIX" "$WORKER" | head -2
else
    echo "❌ worker.php hat KEINEN PERMANENT FIX"
    echo "   → config.txt wird überschrieben!"
fi
echo ""
if grep -q "chkBootConfigTxt()" "$WORKER" && ! grep -q "DISABLED" "$WORKER"; then
    echo "❌ chkBootConfigTxt() ist noch aktiv"
else
    echo "✅ chkBootConfigTxt() ist deaktiviert"
fi
EOF
)

echo "$WORKER_CHECK"
echo ""

echo "=== ZUSAMMENFASSUNG ==="
echo ""
if echo "$CONFIG_CHECK" | grep -q "✅ Main Header in Zeile 2" && echo "$CONFIG_CHECK" | grep -q "✅ display_rotate=2" && echo "$WORKER_CHECK" | grep -q "✅ worker.php hat PERMANENT FIX"; then
    echo "✅ ALLE FIXES FUNKTIONIEREN!"
    echo "   → config.txt wurde NICHT überschrieben"
    echo "   → worker.php hat Fixes"
    echo "   → display_rotate=2 vorhanden"
else
    echo "❌ EINIGE FIXES FUNKTIONIEREN NICHT"
    echo "   → Bitte prüfe die Fehlermeldungen oben"
fi
echo ""

