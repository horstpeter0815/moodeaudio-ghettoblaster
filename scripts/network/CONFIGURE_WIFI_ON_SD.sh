#!/bin/bash
# CONFIGURE WIFI ON SD CARD
# Configures WiFi SSID and password on SD card

SD_MOUNT="/Volumes/bootfs"
[ ! -d "$SD_MOUNT" ] && SD_MOUNT="/Volumes/boot"

if [ ! -d "$SD_MOUNT" ]; then
    echo "❌ SD-Karte nicht gefunden"
    exit 1
fi

echo "=== WLAN KONFIGURATION ==="
echo ""
read -p "WLAN SSID: " WIFI_SSID
read -sp "WLAN Passwort: " WIFI_PASSWORD
echo ""

if [ -z "$WIFI_SSID" ]; then
    echo "⚠️  Keine SSID eingegeben, überspringe WLAN"
    exit 0
fi

cat > "$SD_MOUNT/wpa_supplicant.conf" << EOF
country=DE
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
update_config=1

network={
    ssid="$WIFI_SSID"
    psk="$WIFI_PASSWORD"
}
EOF

chmod 600 "$SD_MOUNT/wpa_supplicant.conf"
echo "✅ WLAN-Konfiguration erstellt"
sync
