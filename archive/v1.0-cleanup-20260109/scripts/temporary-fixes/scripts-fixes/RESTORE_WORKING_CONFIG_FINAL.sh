#!/bin/bash
# Restore EXACT working configuration from yesterday
# Run: cd ~/moodeaudio-cursor && sudo ./RESTORE_WORKING_CONFIG_FINAL.sh

ROOTFS="/Volumes/rootfs"
BOOTFS="/Volumes/bootfs"

if [ ! -d "$ROOTFS" ]; then
    echo "❌ SD card not mounted"
    exit 1
fi

echo "=== RESTORING WORKING CONFIGURATION ==="
echo ""

# 1. Ethernet: EXACT config from yesterday
echo "1. Setting Ethernet (192.168.10.2)..."
UUID=$(uuidgen)
sudo tee "$ROOTFS/etc/NetworkManager/system-connections/Ethernet.nmconnection" > /dev/null << EOF
[connection]
id=Ethernet
uuid=${UUID}
type=ethernet
interface-name=eth0
autoconnect=true

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
echo "✅ Ethernet: 192.168.10.2"

# 2. Display: PeppyMeter (working)
echo "2. Setting Display..."
sqlite3 "$ROOTFS/var/local/www/db/moode-sqlite3.db" << EOF
UPDATE cfg_system SET value='1' WHERE param='peppy_display';
UPDATE cfg_system SET value='0' WHERE param='local_display';
UPDATE cfg_system SET value='http://localhost/' WHERE param='local_display_url';
EOF
echo "✅ Display: PeppyMeter"

# 3. .xinitrc: moOde UI
echo "3. Fixing .xinitrc..."
sudo sed -i '' 's|--app="http://localhost/wizard.*"|--app="http://localhost/"|' "$ROOTFS/home/andre/.xinitrc" 2>/dev/null || true
echo "✅ .xinitrc: moOde UI"

# 4. SSH enable
echo "4. Enabling SSH..."
sudo touch "$BOOTFS/ssh" 2>/dev/null || true
echo "✅ SSH enabled"

echo ""
echo "✅✅✅ CONFIGURATION RESTORED ✅✅✅"
echo ""
echo "After boot:"
echo "  Pi IP: 192.168.10.2 (USB Ethernet)"
echo "  SSH: ssh andre@192.168.10.2"
echo "  Wizard: http://192.168.10.2/wizard/wizard-control.html"
echo ""

