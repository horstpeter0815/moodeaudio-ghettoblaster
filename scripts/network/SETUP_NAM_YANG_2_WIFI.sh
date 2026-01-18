#!/bin/bash
# Configure Ghettoblaster WiFi for "nam yang 2" network
# Run: cd ~/moodeaudio-cursor && sudo ./scripts/network/SETUP_NAM_YANG_2_WIFI.sh

ROOTFS="/Volumes/rootfs"
BOOTFS="/Volumes/bootfs"

if [ ! -d "$ROOTFS" ]; then
    echo "❌ SD-Karte nicht gemountet (rootfs nicht gefunden)"
    echo "Bitte SD-Karte einstecken und erneut versuchen"
    exit 1
fi

echo "=== WLAN KONFIGURATION: nam yang 2 ==="
echo ""

# Ask for WiFi password
read -sp "WLAN Passwort für 'nam yang 2': " WIFI_PASSWORD
echo ""
echo ""

if [ -z "$WIFI_PASSWORD" ]; then
    echo "⚠️  Kein Passwort eingegeben. Verwende offenes Netzwerk (kein Passwort)."
    WIFI_PASSWORD=""
    KEY_MGMT="none"
else
    KEY_MGMT="WPA-PSK"
fi

# 1. NetworkManager configuration (primary method for moOde)
echo "1. Konfiguriere NetworkManager..."
UUID=$(uuidgen)
sudo tee "$ROOTFS/etc/NetworkManager/system-connections/nam-yang-2.nmconnection" > /dev/null << EOF
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
EOF

# Add password if provided
if [ -n "$WIFI_PASSWORD" ]; then
    sudo tee -a "$ROOTFS/etc/NetworkManager/system-connections/nam-yang-2.nmconnection" > /dev/null << EOF
psk=${WIFI_PASSWORD}
EOF
fi

# Add IPv4 configuration
sudo tee -a "$ROOTFS/etc/NetworkManager/system-connections/nam-yang-2.nmconnection" > /dev/null << EOF

[ipv4]
method=auto

[ipv6]
method=auto
EOF

sudo chmod 600 "$ROOTFS/etc/NetworkManager/system-connections/nam-yang-2.nmconnection"
echo "✅ NetworkManager Konfiguration erstellt"

# 2. wpa_supplicant backup (fallback)
echo "2. Erstelle wpa_supplicant Backup..."
if [ -d "$BOOTFS" ]; then
    WPA_FILE="$BOOTFS/wpa_supplicant.conf"
else
    WPA_FILE="$ROOTFS/boot/firmware/wpa_supplicant.conf"
    mkdir -p "$(dirname "$WPA_FILE")"
fi

if [ -n "$WIFI_PASSWORD" ]; then
    sudo tee "$WPA_FILE" > /dev/null << EOF
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
update_config=1
country=DE

network={
    ssid="nam yang 2"
    psk="${WIFI_PASSWORD}"
    key_mgmt=WPA-PSK
    priority=200
}
EOF
else
    sudo tee "$WPA_FILE" > /dev/null << EOF
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
update_config=1
country=DE

network={
    ssid="nam yang 2"
    key_mgmt=NONE
    priority=200
}
EOF
fi

sudo chmod 600 "$WPA_FILE"
echo "✅ wpa_supplicant Konfiguration erstellt"

# 3. Verify configuration
echo ""
echo "=== VERIFICATION ==="
echo "NetworkManager:"
sudo grep -E "ssid=|autoconnect=" "$ROOTFS/etc/NetworkManager/system-connections/nam-yang-2.nmconnection" | head -2
echo ""
echo "wpa_supplicant:"
sudo grep -E "ssid=|priority=" "$WPA_FILE" | head -2
echo ""

echo "✅✅✅ WLAN KONFIGURATION FÜR 'nam yang 2' ABGESCHLOSSEN ✅✅✅"
echo ""
echo "Nach dem Boot:"
echo "  - Ghettoblaster verbindet sich automatisch mit 'nam yang 2'"
echo "  - IP-Adresse wird per DHCP zugewiesen"
echo "  - SSH: ssh pi@<IP_ADRESSE> (oder ssh pi@nam-yang-2.local wenn mDNS funktioniert)"
echo ""
echo "Zum Testen nach dem Boot:"
echo "  ssh pi@<IP_ADRESSE>"
echo "  sudo nmcli connection show"
echo "  sudo nmcli device wifi list"
echo ""
