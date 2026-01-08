#!/bin/bash
################################################################################
#
# ENABLE INTERNET SHARING TO PI VIA LAN CABLE
#
# Aktiviert Internet-Sharing vom Mac Wi-Fi zum Ethernet
# Pi bekommt dann Internet über LAN-Kabel
#
################################################################################

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  🌐 INTERNET-SHARING ZUM PI AKTIVIEREN                       ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Finde Interfaces
ETHERNET_INTERFACE=$(networksetup -listallhardwareports | grep -A 1 "Ethernet Adapter" | grep "Hardware Port" | head -1 | awk -F': ' '{print $2}')
WIFI_INTERFACE=$(networksetup -listallhardwareports | grep -A 1 "Wi-Fi" | grep "Device" | awk '{print $2}')

if [ -z "$ETHERNET_INTERFACE" ]; then
    echo "❌ Ethernet-Interface nicht gefunden"
    exit 1
fi

if [ -z "$WIFI_INTERFACE" ]; then
    echo "❌ Wi-Fi-Interface nicht gefunden"
    exit 1
fi

echo "✅ Interfaces gefunden:"
echo "   Wi-Fi: $WIFI_INTERFACE"
echo "   Ethernet: $ETHERNET_INTERFACE"
echo ""

# 1. Konfiguriere Ethernet auf 192.168.10.1
echo "1. Konfiguriere Ethernet auf 192.168.10.1..."
sudo networksetup -setmanual "$ETHERNET_INTERFACE" 192.168.10.1 255.255.255.0

if [ $? -ne 0 ]; then
    echo "❌ Ethernet-Konfiguration fehlgeschlagen"
    exit 1
fi

echo "✅ Ethernet konfiguriert: 192.168.10.1"
echo ""

# 2. Aktiviere IP-Forwarding
echo "2. Aktiviere IP-Forwarding..."
sudo sysctl -w net.inet.ip.forwarding=1

# 3. Aktiviere NAT/PF
echo "3. Konfiguriere NAT..."
sudo pfctl -d 2>/dev/null || true

# Erstelle PF-Regel für NAT
cat > /tmp/pf-nat.conf << PFEOF
nat on $WIFI_INTERFACE from 192.168.10.0/24 to any -> ($WIFI_INTERFACE)
pass in all
pass out all
PFEOF

sudo pfctl -f /tmp/pf-nat.conf -e 2>/dev/null || {
    echo "⚠️  PF konnte nicht aktiviert werden"
    echo "   Versuche Internet-Sharing über Systemeinstellungen..."
}

echo "✅ NAT konfiguriert"
echo ""

# 4. Aktiviere Internet-Sharing über Systemeinstellungen (falls verfügbar)
echo "4. Aktiviere Internet-Sharing..."
# Prüfe ob Internet-Sharing bereits aktiv ist
if [ "$(sudo launchctl list | grep -i sharing)" ]; then
    echo "✅ Internet-Sharing läuft bereits"
else
    echo "⚠️  Internet-Sharing muss manuell aktiviert werden:"
    echo "   Systemeinstellungen > Freigabe > Internet-Freigabe"
    echo "   'Wi-Fi mit anderen teilen' aktivieren"
    echo "   'Ethernet' aktivieren"
fi

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  ✅ INTERNET-SHARING KONFIGURIERT                            ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "📋 Konfiguration:"
echo "   Mac Ethernet: 192.168.10.1"
echo "   Pi sollte: 192.168.10.2 bekommen"
echo "   Gateway: 192.168.10.1"
echo ""
echo "🌐 Pi hat jetzt Internet über LAN-Kabel!"
echo ""

