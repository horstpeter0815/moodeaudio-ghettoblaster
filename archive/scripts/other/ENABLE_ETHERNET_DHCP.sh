#!/bin/bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  🔧 ETHERNET DHCP AKTIVIEREN                                 ║
# ╚══════════════════════════════════════════════════════════════╝

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  🔧 USB-ETHERNET DHCP AKTIVIEREN                             ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Prüfe aktuellen Status
echo "📊 Aktueller Status:"
CURRENT_IP=$(ifconfig en8 | grep "inet " | awk '{print $2}')
echo "   IP: $CURRENT_IP"
echo ""

# Setze DHCP
echo "🔧 Aktiviere DHCP für USB-Ethernet..."
sudo networksetup -setdhcp "AX88179A"

if [ $? -eq 0 ]; then
    echo "✅ DHCP aktiviert!"
    echo ""
    echo "⏳ Warte auf IP-Zuweisung vom Router..."
    sleep 5
    
    # Prüfe neue IP
    NEW_IP=$(ifconfig en8 | grep "inet " | awk '{print $2}')
    if [ -n "$NEW_IP" ] && [ "$NEW_IP" != "192.168.2.1" ]; then
        echo "✅ Neue IP erhalten: $NEW_IP"
        echo "✅ Ethernet konfiguriert!"
    else
        echo "⚠️  Warte noch auf IP..."
        sleep 5
        NEW_IP=$(ifconfig en8 | grep "inet " | awk '{print $2}')
        if [ -n "$NEW_IP" ] && [ "$NEW_IP" != "192.168.2.1" ]; then
            echo "✅ IP erhalten: $NEW_IP"
        else
            echo "⚠️  Keine neue IP - prüfe Kabel-Verbindung"
        fi
    fi
    
    echo ""
    echo "📊 Prüfe Standard-Route..."
    sleep 2
    DEFAULT_IF=$(route get default 2>/dev/null | grep interface | awk '{print $2}')
    
    if [ "$DEFAULT_IF" = "en8" ]; then
        echo "✅ Ethernet ist jetzt Standard-Route!"
        echo "🚀 Build nutzt jetzt Ethernet (schneller)!"
    elif [ "$DEFAULT_IF" = "en0" ]; then
        echo "⚠️  Wi-Fi ist noch Standard-Route"
        echo ""
        echo "💡 Optionen:"
        echo "   1. Wi-Fi temporär deaktivieren (Systemeinstellungen → Netzwerk → Wi-Fi → deaktivieren)"
        echo "   2. Oder: Ethernet-Priorität erhöhen (Systemeinstellungen → Netzwerk → Reihenfolge anpassen)"
    fi
    
    echo ""
    echo "🧪 Teste Internet-Verbindung..."
    if ping -c 2 8.8.8.8 >/dev/null 2>&1; then
        echo "✅ Internet erreichbar"
    else
        echo "❌ Internet nicht erreichbar"
    fi
    
else
    echo "❌ Fehler beim Aktivieren von DHCP"
    echo ""
    echo "💡 Manuelle Konfiguration:"
    echo "   1. Systemeinstellungen → Netzwerk"
    echo "   2. 'AX88179A' auswählen"
    echo "   3. 'Konfiguration' → 'DHCP verwenden'"
fi

echo ""
echo "📋 Status prüfen:"
echo "   ./CHECK_NETWORK_SPEED.sh"

