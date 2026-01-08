#!/bin/bash
# WLAN Konfiguration für Moode Audio

set -e

echo "=== WLAN Konfiguration Moode Audio ==="

# Prüfe WLAN-Interface
WLAN_IFACE=$(ip link show | grep -i "wlan" | head -1 | awk -F: '{print $2}' | xargs)

if [ -z "$WLAN_IFACE" ]; then
    echo "❌ Kein WLAN-Interface gefunden"
    exit 1
fi

echo "WLAN-Interface: $WLAN_IFACE"

# Konfiguriere wpa_supplicant
sudo tee -a /etc/wpa_supplicant/wpa_supplicant.conf > /dev/null << 'WPA_EOF'

network={
    ssid="Martin Router King"
    psk="0815"
}
WPA_EOF

# Starte WLAN
sudo systemctl restart wpa_supplicant 2>/dev/null || sudo ifup "$WLAN_IFACE" 2>/dev/null

sleep 5

echo "IP-Adressen:"
hostname -I

echo "✅ WLAN konfiguriert"

