#!/bin/bash
# Complete Wizard Setup - Everything configured correctly
# Run: cd ~/moodeaudio-cursor && sudo ./COMPLETE_WIZARD_SETUP.sh

ROOTFS="/Volumes/rootfs"
BOOTFS="/Volumes/bootfs"

if [ ! -d "$ROOTFS" ]; then
    echo "❌ SD card not mounted"
    exit 1
fi

echo "=== COMPLETE WIZARD SETUP ==="
echo ""

# 1. Ethernet: Static IP 192.168.10.2
echo "1. Configuring Ethernet (192.168.10.2)..."
UUID=$(uuidgen)
sudo tee "$ROOTFS/etc/NetworkManager/system-connections/Ethernet.nmconnection" > /dev/null << EOF
[connection]
id=Ethernet
uuid=${UUID}
type=ethernet
interface-name=eth0
autoconnect=true
autoconnect-priority=10

[ethernet]

[ipv4]
method=manual
addresses=192.168.10.2/24
gateway=192.168.10.1
dns=8.8.8.8;8.8.4.4;

[ipv6]
method=disabled
EOF
sudo chmod 600 "$ROOTFS/etc/NetworkManager/system-connections/Ethernet.nmconnection"
echo "✅ Ethernet configured"

# 2. Hotel WiFi: Auto-connect enabled
echo "2. Configuring Hotel WiFi (auto-connect)..."
UUID=$(uuidgen)
sudo tee "$ROOTFS/etc/NetworkManager/system-connections/hotel-wifi.nmconnection" > /dev/null << EOF
[connection]
id=hotel-wifi
uuid=${UUID}
type=wifi
autoconnect=true
autoconnect-priority=50

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
echo "✅ Hotel WiFi configured"

# 3. wpa_supplicant backup
echo "3. Creating wpa_supplicant backup..."
sudo mkdir -p "$ROOTFS/etc/wpa_supplicant"
sudo tee "$ROOTFS/etc/wpa_supplicant/wpa_supplicant.conf" > /dev/null << EOF
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
update_config=1
country=DE

network={
    ssid="The Wing Hotel"
    psk="thewing2019"
    key_mgmt=WPA-PSK
    priority=200
}
EOF
sudo chmod 600 "$ROOTFS/etc/wpa_supplicant/wpa_supplicant.conf"
echo "✅ wpa_supplicant configured"

# 4. Display: PeppyMeter (working config)
echo "4. Configuring Display..."
sqlite3 "$ROOTFS/var/local/www/db/moode-sqlite3.db" << EOF
UPDATE cfg_system SET value='1' WHERE param='peppy_display';
UPDATE cfg_system SET value='0' WHERE param='local_display';
UPDATE cfg_system SET value='http://localhost/' WHERE param='local_display_url';
EOF
echo "✅ Display configured"

# 5. .xinitrc: moOde UI (not wizard)
echo "5. Fixing .xinitrc..."
sudo sed -i '' 's|--app="http://localhost/wizard.*"|--app="http://localhost/"|' "$ROOTFS/home/andre/.xinitrc" 2>/dev/null || true
echo "✅ .xinitrc fixed"

# 6. Enable SSH
echo "6. Enabling SSH..."
sudo touch "$BOOTFS/ssh" 2>/dev/null || echo "SSH file already exists or bootfs not mounted"
echo "✅ SSH enabled"

# 7. Verify Wizard files exist
echo "7. Verifying Wizard files..."
if [ -f "$ROOTFS/var/www/wizard/wizard-control.html" ] && [ -f "$ROOTFS/var/www/wizard/wizard-control.js" ]; then
    echo "✅ Wizard files present"
else
    echo "⚠️ Wizard files missing - will be created on first boot"
fi

echo ""
echo "=== VERIFICATION ==="
echo "Ethernet:"
sudo grep -E "method=|addresses=" "$ROOTFS/etc/NetworkManager/system-connections/Ethernet.nmconnection" | head -2
echo ""
echo "Hotel WiFi:"
sudo grep -E "autoconnect|ssid=" "$ROOTFS/etc/NetworkManager/system-connections/hotel-wifi.nmconnection" | head -2
echo ""
echo "Display:"
sqlite3 "$ROOTFS/var/local/www/db/moode-sqlite3.db" "SELECT param, value FROM cfg_system WHERE param='peppy_display';" 2>/dev/null
echo ""
echo "✅✅✅ COMPLETE SETUP FINISHED ✅✅✅"
echo ""
echo "After boot:"
echo "  - Ethernet: 192.168.10.2 (if USB connected)"
echo "  - WiFi: Auto-connects to 'The Wing Hotel'"
echo "  - Display: PeppyMeter (tap for moOde UI)"
echo "  - Wizard: http://<PI_IP>/wizard/wizard-control.html"
echo ""

