#!/bin/bash
# Restore basic moOde functionality - minimal changes
# Run: cd ~/moodeaudio-cursor && sudo ./RESTORE_BASIC_MOODE.sh

ROOTFS="/Volumes/rootfs"

if [ ! -d "$ROOTFS" ]; then
    echo "❌ SD card not mounted"
    exit 1
fi

echo "=== Restoring Basic moOde Configuration ==="
echo ""

# 1. Display: PeppyMeter (working config)
echo "1. Setting display to PeppyMeter..."
sqlite3 "$ROOTFS/var/local/www/db/moode-sqlite3.db" << EOF
UPDATE cfg_system SET value='1' WHERE param='peppy_display';
UPDATE cfg_system SET value='0' WHERE param='local_display';
UPDATE cfg_system SET value='http://localhost/' WHERE param='local_display_url';
EOF
echo "✅ Display settings restored"

# 2. .xinitrc: Show moOde UI (not wizard)
echo "2. Restoring .xinitrc..."
sed -i '' 's|--app="http://localhost/wizard.*"|--app="http://localhost/"|' "$ROOTFS/home/andre/.xinitrc" 2>/dev/null || true
echo "✅ .xinitrc restored"

# 3. Ethernet: Static IP 192.168.10.2 (working config)
echo "3. Checking Ethernet config..."
if ! grep -q "192.168.10.2" "$ROOTFS/etc/NetworkManager/system-connections/Ethernet.nmconnection" 2>/dev/null; then
    echo "   Setting Ethernet to static IP..."
    UUID=$(uuidgen)
    cat > "$ROOTFS/etc/NetworkManager/system-connections/Ethernet.nmconnection" << EOF
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
    chmod 600 "$ROOTFS/etc/NetworkManager/system-connections/Ethernet.nmconnection"
    echo "✅ Ethernet configured"
else
    echo "✅ Ethernet already configured"
fi

echo ""
echo "✅✅✅ Basic moOde Configuration Restored ✅✅✅"
echo ""
echo "After boot:"
echo "  - Display: PeppyMeter (tap to show moOde UI)"
echo "  - Network: 192.168.10.2 (USB Ethernet)"
echo "  - moOde should work normally"

