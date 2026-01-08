#!/bin/bash
# Fix WiFi credentials DEFINITIVELY - ensure hotel WiFi works
# Run: cd ~/moodeaudio-cursor && sudo ./FIX_WIFI_CREDENTIALS_DEFINITIVE.sh

ROOTFS="/Volumes/rootfs"

if [ ! -d "$ROOTFS" ]; then
    echo "❌ SD card not mounted"
    exit 1
fi

echo "=== FIXING WIFI CREDENTIALS DEFINITIVELY ==="
echo ""

# 1. Create NetworkManager directory
sudo mkdir -p "$ROOTFS/etc/NetworkManager/system-connections"
echo "✅ Directory created"

# 2. Create hotel-wifi.nmconnection with AUTO-CONNECT
UUID=$(uuidgen)
sudo tee "$ROOTFS/etc/NetworkManager/system-connections/hotel-wifi.nmconnection" > /dev/null << EOF
[connection]
id=hotel-wifi
uuid=${UUID}
type=wifi
autoconnect=true
autoconnect-priority=100

[wifi]
mode=infrastructure
ssid=The Wing Hotel

[wifi-security]
key-mgmt=wpa-psk
psk=thewing2019

[ipv4]
method=auto

[ipv6]
method=auto
EOF

sudo chmod 600 "$ROOTFS/etc/NetworkManager/system-connections/hotel-wifi.nmconnection"
echo "✅ hotel-wifi.nmconnection created (autoconnect=true, priority=100)"

# 3. Create wpa_supplicant backup
sudo mkdir -p "$ROOTFS/etc/wpa_supplicant"
sudo tee "$ROOTFS/etc/wpa_supplicant/wpa_supplicant.conf" > /dev/null << EOF
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
update_config=1
country=DE

network={
    ssid="The Wing Hotel"
    psk="thewing2019"
    key_mgmt=WPA-PSK
    priority=100
}
EOF

sudo chmod 600 "$ROOTFS/etc/wpa_supplicant/wpa_supplicant.conf"
echo "✅ wpa_supplicant.conf created"

# 4. Verify
echo ""
echo "=== VERIFICATION ==="
echo "Hotel WiFi Config:"
sudo cat "$ROOTFS/etc/NetworkManager/system-connections/hotel-wifi.nmconnection" | grep -E "ssid=|autoconnect=|psk="
echo ""
echo "wpa_supplicant:"
sudo cat "$ROOTFS/etc/wpa_supplicant/wpa_supplicant.conf" | grep -E "ssid=|psk="
echo ""
echo "✅✅✅ WIFI CREDENTIALS FIXED ✅✅✅"
echo ""
echo "After boot:"
echo "  Pi will auto-connect to 'The Wing Hotel' WiFi"
echo "  Find Pi IP: arp -a | grep 192.168.110"
echo "  Or check router/hotel network for Pi IP"
echo ""

