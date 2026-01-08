#!/bin/bash
################################################################################
#
# CONFIGURE MAC ETHERNET FOR DIRECT LAN CONNECTION TO PI
#
# Konfiguriert Mac Ethernet für direkte Verbindung zum Pi
# Mac: 192.168.10.1
# Pi: 192.168.10.2
#
################################################################################

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  🔧 MAC ETHERNET FÜR PI KONFIGURIEREN                        ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Finde Ethernet-Interface
ETHERNET_INTERFACE=$(networksetup -listallhardwareports | grep -A 1 "Ethernet" | grep "Hardware Port" | head -1 | awk -F': ' '{print $2}')

if [ -z "$ETHERNET_INTERFACE" ]; then
    echo "❌ FEHLER: Ethernet-Interface nicht gefunden"
    echo "   Bitte prüfe, ob LAN-Kabel angeschlossen ist"
    exit 1
fi

echo "✅ Ethernet-Interface gefunden: $ETHERNET_INTERFACE"
echo ""

# Konfiguriere statische IP
echo "🔧 Konfiguriere statische IP: 192.168.10.1"
echo "   (Benötigt sudo-Passwort)"
echo ""

sudo networksetup -setmanual "$ETHERNET_INTERFACE" 192.168.10.1 255.255.255.0 192.168.10.1

if [ $? -eq 0 ]; then
    echo "✅ Ethernet konfiguriert"
    echo ""
    echo "📋 Konfiguration:"
    echo "   Mac IP: 192.168.10.1"
    echo "   Pi IP: 192.168.10.2 (sollte automatisch via DHCP kommen)"
    echo "   Subnet: 255.255.255.0"
    echo ""
    echo "⏳ Warte 5 Sekunden..."
    sleep 5
    echo ""
    echo "🔍 Prüfe Verbindung zum Pi..."
    if ping -c 3 -W 2 192.168.10.2 >/dev/null 2>&1; then
        echo "✅ Pi ist erreichbar: 192.168.10.2"
    else
        echo "⏳ Pi antwortet noch nicht (kann 30-60 Sekunden dauern)"
        echo "   Prüfe erneut mit: ping 192.168.10.2"
    fi
else
    echo "❌ FEHLER: Konfiguration fehlgeschlagen"
    exit 1
fi

echo ""

