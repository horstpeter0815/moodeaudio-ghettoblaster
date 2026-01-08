#!/bin/bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  🔧 USB-ETHERNET ADAPTER KONFIGURIEREN                       ║
# ╚══════════════════════════════════════════════════════════════╝

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  🔧 USB-ETHERNET ADAPTER SETUP                               ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Prüfe aktuellen Status
CURRENT_IP=$(networksetup -getinfo "AX88179A" 2>/dev/null | grep "IP address:" | awk '{print $3}')
CURRENT_CONFIG=$(networksetup -getinfo "AX88179A" 2>/dev/null | grep "Configuration:" | awk '{print $2}')

echo "📊 Aktuelle Konfiguration:"
echo "   IP: $CURRENT_IP"
echo "   Konfiguration: $CURRENT_CONFIG"
echo ""

# Prüfe ob DHCP bereits aktiv
if [ "$CURRENT_CONFIG" = "DHCP" ]; then
    echo "✅ DHCP bereits aktiv!"
    echo ""
    echo "Prüfe Verbindung..."
    sleep 2
    
    NEW_IP=$(ifconfig en8 | grep "inet " | awk '{print $2}')
    if [ -n "$NEW_IP" ] && [ "$NEW_IP" != "192.168.2.1" ]; then
        echo "✅ Ethernet hat IP: $NEW_IP"
        echo "✅ Konfiguration OK!"
    else
        echo "⚠️  Ethernet hat noch alte IP oder keine IP"
        echo "   Bitte USB-Ethernet-Kabel an Router anschließen"
    fi
else
    echo "🔧 Konfiguriere DHCP..."
    echo ""
    echo "⚠️  MANUELLE KONFIGURATION ERFORDERLICH:"
    echo ""
    echo "1. Öffne: Systemeinstellungen → Netzwerk"
    echo "2. Wähle: 'AX88179A'"
    echo "3. Setze: 'Konfiguration' → 'DHCP verwenden'"
    echo "4. Stelle sicher: USB-Ethernet-Kabel ist an Router angeschlossen"
    echo ""
    echo "Nach Konfiguration:"
    echo "   ./CHECK_NETWORK_SPEED.sh"
    echo ""
    
    # Versuche automatisch DHCP zu setzen (benötigt Admin-Rechte)
    read -p "Automatisch DHCP aktivieren? (benötigt Admin-Passwort) (j/n): " AUTO
    
    if [ "$AUTO" = "j" ]; then
        echo ""
        echo "🔧 Setze DHCP..."
        sudo networksetup -setdhcp "AX88179A"
        
        if [ $? -eq 0 ]; then
            echo "✅ DHCP aktiviert!"
            echo ""
            echo "⏳ Warte auf IP-Zuweisung..."
            sleep 5
            
            NEW_IP=$(ifconfig en8 | grep "inet " | awk '{print $2}')
            if [ -n "$NEW_IP" ] && [ "$NEW_IP" != "192.168.2.1" ]; then
                echo "✅ Ethernet hat neue IP: $NEW_IP"
                echo "✅ Konfiguration erfolgreich!"
            else
                echo "⚠️  Keine IP erhalten - prüfe Kabel-Verbindung zum Router"
            fi
        else
            echo "❌ Fehler beim Setzen von DHCP"
        fi
    fi
fi

echo ""
echo "📊 Prüfe Standard-Route..."
DEFAULT_IF=$(route get default 2>/dev/null | grep interface | awk '{print $2}')

if [ "$DEFAULT_IF" = "en8" ]; then
    echo "✅ Ethernet ist Standard-Route - Build nutzt Ethernet! 🚀"
elif [ "$DEFAULT_IF" = "en0" ]; then
    echo "⚠️  Wi-Fi ist noch Standard-Route"
    echo "   Build nutzt noch Wi-Fi"
    echo ""
    echo "💡 Tipp: Wi-Fi temporär deaktivieren für Build"
else
    echo "📍 Standard-Route: $DEFAULT_IF"
fi

echo ""
echo "🧪 Teste Internet-Verbindung..."
if ping -c 2 8.8.8.8 >/dev/null 2>&1; then
    echo "✅ Internet erreichbar"
else
    echo "❌ Internet nicht erreichbar"
fi

