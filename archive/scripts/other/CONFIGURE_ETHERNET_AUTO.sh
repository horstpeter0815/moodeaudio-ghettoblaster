#!/bin/bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  🔧 AUTOMATISCHE ETHERNET-KONFIGURATION                      ║
# ╚══════════════════════════════════════════════════════════════╝

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  🔧 ETHERNET AUTOMATISCH KONFIGURIEREN                       ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Versuche über networksetup (benötigt Admin)
echo "🔧 Versuche DHCP automatisch zu aktivieren..."
echo "   (Benötigt Admin-Passwort - wird automatisch versucht)"

# Prüfe ob bereits DHCP
CURRENT_CONFIG=$(networksetup -getinfo "AX88179A" 2>/dev/null | grep "Configuration:" | awk '{print $2}')

if [ "$CURRENT_CONFIG" = "DHCP" ]; then
    echo "✅ DHCP bereits aktiv!"
else
    echo "⚠️  Manuelle Konfiguration erforderlich:"
    echo ""
    echo "📋 SCHRITTE:"
    echo "   1. Systemeinstellungen öffnen (wird automatisch geöffnet)"
    echo "   2. 'Netzwerk' auswählen"
    echo "   3. 'AX88179A' auswählen"
    echo "   4. 'Konfiguration' → 'DHCP verwenden' wählen"
    echo ""
    
    # Öffne Systemeinstellungen automatisch
    open "x-apple.systempreferences:com.apple.preference.network"
    
    echo "✅ Systemeinstellungen geöffnet"
    echo "   Bitte DHCP manuell aktivieren (siehe Schritte oben)"
    echo ""
    echo "⏳ Warte 30 Sekunden auf Konfiguration..."
    sleep 30
    
    # Prüfe erneut
    NEW_CONFIG=$(networksetup -getinfo "AX88179A" 2>/dev/null | grep "Configuration:" | awk '{print $2}')
    if [ "$NEW_CONFIG" = "DHCP" ]; then
        echo "✅ DHCP aktiviert!"
    else
        echo "⚠️  DHCP noch nicht aktiv - bitte manuell konfigurieren"
    fi
fi

echo ""
echo "📊 Prüfe Status..."
sleep 3

NEW_IP=$(ifconfig en8 | grep "inet " | awk '{print $2}')
if [ -n "$NEW_IP" ] && [ "$NEW_IP" != "192.168.2.1" ]; then
    echo "✅ Neue IP erhalten: $NEW_IP"
    echo "✅ Ethernet konfiguriert!"
else
    echo "⚠️  Warte noch auf IP vom Router..."
    echo "   IP wird automatisch zugewiesen wenn Router verbunden ist"
fi

echo ""
echo "📋 Status prüfen:"
echo "   ./CHECK_NETWORK_SPEED.sh"
