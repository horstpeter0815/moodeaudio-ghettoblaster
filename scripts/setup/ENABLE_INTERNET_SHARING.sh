#!/bin/bash
# ENABLE INTERNET SHARING ON MAC
# Shares Mac's internet connection with Pi via Ethernet

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  🌐 ENABLE INTERNET SHARING ON MAC                           ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

echo "=== SCHRITT 1: PRÜFE NETZWERK-INTERFACES ==="
echo ""

# Find network interfaces
WIFI_INTERFACE=$(networksetup -listallhardwareports | grep -A 1 "Wi-Fi" | grep "Device" | awk '{print $2}')
ETHERNET_INTERFACE=$(networksetup -listallhardwareports | grep -A 1 "Ethernet\|USB.*Ethernet\|Thunderbolt.*Ethernet" | grep "Device" | awk '{print $2}' | head -1)

echo "Wi-Fi Interface: ${WIFI_INTERFACE:-nicht gefunden}"
echo "Ethernet Interface: ${ETHERNET_INTERFACE:-nicht gefunden}"
echo ""

if [ -z "$ETHERNET_INTERFACE" ]; then
    echo "⚠️  Ethernet-Interface nicht gefunden"
    echo "   Bitte LAN-Kabel prüfen"
    exit 1
fi

echo "=== SCHRITT 2: AKTIVIERE INTERNET SHARING ==="
echo ""

# Check current status
CURRENT_STATUS=$(sudo /usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate 2>/dev/null || echo "unknown")

echo "Aktueller Status: $CURRENT_STATUS"
echo ""
echo "Um Internet Sharing zu aktivieren:"
echo ""
echo "METHODE 1: System Settings (GUI)"
echo "  1. Öffne: System Settings → General → Sharing"
echo "  2. Aktiviere: 'Internet Sharing'"
echo "  3. Wähle: 'Share your connection from: Wi-Fi'"
echo "  4. Aktiviere: 'To computers using: Ethernet'"
echo ""

echo "METHODE 2: Terminal (automatisch)"
echo "  Führe aus:"
echo "    sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate on"
echo "    sudo defaults write /Library/Preferences/SystemConfiguration/com.apple.nat NAT -dict-add Enabled -int 1"
echo ""

echo "=== SCHRITT 3: PRÜFE PI NETZWERK ==="
echo ""

echo "Nach Aktivierung sollte der Pi eine IP-Adresse erhalten:"
echo "  - Normalerweise: 192.168.2.x (Mac Internet Sharing)"
echo "  - Oder: 169.254.x.x (Link-Local, falls kein DHCP)"
echo ""

echo "Prüfe Pi IP:"
for ip in "192.168.2.100" "192.168.2.101" "192.168.2.102" "169.254.1.1" "169.254.1.2"; do
    if ping -c 1 -W 1 $ip >/dev/null 2>&1; then
        echo "  ✅ Pi gefunden: $ip"
        PI_IP=$ip
        break
    fi
done

if [ -z "$PI_IP" ]; then
    echo "  ⚠️  Pi noch nicht gefunden"
    echo "     Warte 30 Sekunden nach Aktivierung von Internet Sharing"
fi

echo ""
echo "=== HINWEISE ==="
echo ""
echo "1. Internet Sharing aktivieren (siehe oben)"
echo "2. Warte 30 Sekunden"
echo "3. Prüfe Pi IP mit:"
echo "   arp -a | grep -i 'b8:27:eb\|dc:a6:32\|e4:5f:01'"
echo "   (Raspberry Pi MAC-Adressen)"
echo ""

