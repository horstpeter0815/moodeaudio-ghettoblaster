#!/bin/bash
# Fix Ethernet EXACTLY like yesterday (working config)
# Run: cd ~/moodeaudio-cursor && sudo ./FIX_ETHERNET_EXACT.sh

ROOTFS="/Volumes/rootfs"

if [ ! -d "$ROOTFS" ]; then
    echo "❌ SD card not mounted"
    exit 1
fi

echo "=== FIXING ETHERNET (EXACT LIKE YESTERDAY) ==="
echo ""

# Exact config from WORKING_CONFIG_2026-01-03.md
UUID=$(uuidgen)
sudo tee "$ROOTFS/etc/NetworkManager/system-connections/Ethernet.nmconnection" > /dev/null << 'EOF'
[connection]
id=Ethernet
uuid=PLACEHOLDER_UUID
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

# Replace UUID
sudo sed -i '' "s/PLACEHOLDER_UUID/${UUID}/" "$ROOTFS/etc/NetworkManager/system-connections/Ethernet.nmconnection"
sudo chmod 600 "$ROOTFS/etc/NetworkManager/system-connections/Ethernet.nmconnection"

echo "✅ Ethernet configured EXACTLY like yesterday"
echo ""
echo "Config:"
echo "  Pi IP: 192.168.10.2 (static)"
echo "  Gateway: 192.168.10.1 (Mac)"
echo "  DNS: 8.8.8.8"
echo ""
echo "Mac must have: sudo ifconfig en8 192.168.10.1 netmask 255.255.255.0 up"
echo ""

