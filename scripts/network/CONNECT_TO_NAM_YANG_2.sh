#!/bin/bash
# Connect Ghettoblaster to "nam yang 2" WiFi network (on running system)
# Run: ssh pi@<IP> 'bash -s' < CONNECT_TO_NAM_YANG_2.sh
# OR: Run directly on Pi: sudo ./CONNECT_TO_NAM_YANG_2.sh

if [ "$EUID" -ne 0 ]; then
    echo "❌ Must run as root (use sudo)"
    exit 1
fi

echo "=== WLAN VERBINDUNG: nam yang 2 ==="
echo ""

# Ask for WiFi password
read -sp "WLAN Passwort für 'nam yang 2': " WIFI_PASSWORD
echo ""
echo ""

if [ -z "$WIFI_PASSWORD" ]; then
    echo "⚠️  Kein Passwort eingegeben. Versuche offenes Netzwerk."
    KEY_MGMT="none"
    PSK_LINE=""
else
    KEY_MGMT="wpa-psk"
    PSK_LINE="psk=${WIFI_PASSWORD}"
fi

# Create NetworkManager connection
UUID=$(uuidgen)
NM_CONN_FILE="/etc/NetworkManager/system-connections/nam-yang-2.nmconnection"

cat > "$NM_CONN_FILE" << EOF
[connection]
id=nam-yang-2
uuid=${UUID}
type=wifi
autoconnect=true
autoconnect-priority=100

[wifi]
mode=infrastructure
ssid=nam yang 2

[wifi-security]
key-mgmt=${KEY_MGMT}
${PSK_LINE}

[ipv4]
method=auto

[ipv6]
method=auto
EOF

chmod 600 "$NM_CONN_FILE"
echo "✅ NetworkManager Konfiguration erstellt"

# Reload NetworkManager
systemctl reload NetworkManager
sleep 2

# Connect to the network
echo "Verbinde mit 'nam yang 2'..."
nmcli connection up "nam-yang-2" 2>/dev/null || {
    echo "⚠️  Automatische Verbindung fehlgeschlagen, versuche manuell..."
    nmcli device wifi connect "nam yang 2" password "$WIFI_PASSWORD" 2>/dev/null || {
        if [ -z "$WIFI_PASSWORD" ]; then
            nmcli device wifi connect "nam yang 2" 2>/dev/null
        fi
    }
}

sleep 3

# Show connection status
echo ""
echo "=== VERBINDUNGSSTATUS ==="
nmcli connection show "nam-yang-2" 2>/dev/null || echo "⚠️  Verbindung nicht gefunden"
echo ""
nmcli device status
echo ""

# Show IP address
IP=$(ip -4 addr show wlan0 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | head -1)
if [ -n "$IP" ]; then
    echo "✅ IP-Adresse: $IP"
    echo "   SSH: ssh pi@$IP"
else
    echo "⚠️  Keine IP-Adresse zugewiesen (noch verbinden...)"
fi

echo ""
echo "✅✅✅ KONFIGURATION ABGESCHLOSSEN ✅✅✅"
