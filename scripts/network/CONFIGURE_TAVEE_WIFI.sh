#!/bin/bash
# CONFIGURE TAVEE WIFI ON SD CARD
# Configures WiFi from Tavee Guest House signs
# sudo /Users/andrevollmer/moodeaudio-cursor/CONFIGURE_TAVEE_WIFI.sh

SD_MOUNT="/Volumes/bootfs"
[ ! -d "$SD_MOUNT" ] && SD_MOUNT="/Volumes/boot"

if [ ! -d "$SD_MOUNT" ]; then
    echo "❌ SD-Karte nicht gefunden"
    exit 1
fi

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  📶 CONFIGURE TAVEE WIFI ON SD CARD                          ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

echo "=== WLAN-OPTIONEN AUS BILD ==="
echo ""
echo "1. Reception Network"
echo "   SSID: RRLVGB"
echo "   Passwort: tavee001"
echo ""
echo "2. Extended Network"
echo "   SSID: USEFRRLV6B_Extended"
echo "   Passwort: RRLVGB_Extended-56"
echo ""
echo "3. Back Side"
echo "   SSID: TAVEE-II"
echo "   Passwort: D76DE8F2CF"
echo ""
read -p "Welches WLAN? (1/2/3) [1]: " CHOICE
CHOICE=${CHOICE:-1}

case $CHOICE in
    1)
        WIFI_SSID="RRLVGB"
        WIFI_PASSWORD="tavee001"
        ;;
    2)
        WIFI_SSID="USEFRRLV6B_Extended"
        WIFI_PASSWORD="RRLVGB_Extended-56"
        ;;
    3)
        WIFI_SSID="TAVEE-II"
        WIFI_PASSWORD="D76DE8F2CF"
        ;;
    *)
        echo "❌ Ungültige Auswahl"
        exit 1
        ;;
esac

echo ""
echo "=== KONFIGURIERE WLAN: $WIFI_SSID ==="

# Create wpa_supplicant.conf (Raspberry Pi OS standard)
WPA_FILE="$SD_MOUNT/wpa_supplicant.conf"
cat > "$WPA_FILE" << EOF
country=DE
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
update_config=1

network={
    ssid="$WIFI_SSID"
    psk="$WIFI_PASSWORD"
}
EOF

chmod 600 "$WPA_FILE"
echo "✅ wpa_supplicant.conf erstellt: $WPA_FILE"

# Create NetworkManager connection file (for Moode)
NM_DIR="$SD_MOUNT/network"
mkdir -p "$NM_DIR"

NM_FILE="$NM_DIR/wifi-connection.nmconnection"
cat > "$NM_FILE" << EOF
[connection]
id=$WIFI_SSID
type=wifi
interface-name=wlan0
autoconnect=true
autoconnect-priority=100

[wifi]
mode=infrastructure
ssid=$WIFI_SSID

[wifi-security]
key-mgmt=wpa-psk
psk=$WIFI_PASSWORD

[ipv4]
method=auto

[ipv6]
method=auto
EOF

chmod 600 "$NM_FILE"
echo "✅ NetworkManager connection erstellt: $NM_FILE"

sync
echo ""
echo "✅ WLAN konfiguriert!"
echo ""
echo "SSID: $WIFI_SSID"
echo "Passwort: $WIFI_PASSWORD"
echo ""
echo "Nach Boot sollte der Pi sich automatisch mit '$WIFI_SSID' verbinden"

