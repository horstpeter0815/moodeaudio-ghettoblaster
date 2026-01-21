#!/bin/bash
# Simple script to connect to "nam yang 2" WiFi
# Copy this to Pi and run: bash CONNECT_NAM_YANG_2_SIMPLE.sh

if [ "$EUID" -ne 0 ]; then
    echo "❌ Must run as root (use sudo)"
    exit 1
fi

echo "=== WLAN VERBINDUNG: nam yang 2 ==="
echo ""

# Ask for WiFi password
read -sp "WLAN Passwort für 'nam yang 2' (Enter für kein Passwort): " WIFI_PASSWORD
echo ""
echo ""

# Use nmcli to connect directly
if [ -z "$WIFI_PASSWORD" ]; then
    echo "Verbinde mit offenem Netzwerk 'nam yang 2'..."
    nmcli device wifi connect "nam yang 2" 2>&1
else
    echo "Verbinde mit 'nam yang 2' (mit Passwort)..."
    nmcli device wifi connect "nam yang 2" password "$WIFI_PASSWORD" 2>&1
fi

sleep 3

# Show status
echo ""
echo "=== VERBINDUNGSSTATUS ==="
nmcli device status
echo ""

# Show IP address
IP=$(ip -4 addr show wlan0 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | head -1)
if [ -n "$IP" ]; then
    echo "✅ IP-Adresse: $IP"
    echo "   SSH: ssh pi@$IP"
else
    echo "⚠️  Keine IP-Adresse zugewiesen"
    echo "   Prüfe: nmcli connection show"
fi

echo ""
echo "✅ Fertig!"
