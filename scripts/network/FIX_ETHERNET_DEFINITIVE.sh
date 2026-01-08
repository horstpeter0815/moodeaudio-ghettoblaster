#!/bin/bash
# Fix Ethernet DEFINITIVELY - create config if missing, fix if wrong
# Run: cd ~/moodeaudio-cursor && sudo ./FIX_ETHERNET_DEFINITIVE.sh

ROOTFS="/Volumes/rootfs"

if [ ! -d "$ROOTFS" ]; then
    echo "❌ SD card not mounted"
    exit 1
fi

echo "=== FIXING ETHERNET DEFINITIVELY ==="
echo ""

# Ensure directory exists
sudo mkdir -p "$ROOTFS/etc/NetworkManager/system-connections"

# Create/Overwrite Ethernet config with EXACT working config
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

# Set correct permissions (CRITICAL!)
sudo chmod 600 "$ROOTFS/etc/NetworkManager/system-connections/Ethernet.nmconnection"
sudo chown root:root "$ROOTFS/etc/NetworkManager/system-connections/Ethernet.nmconnection" 2>/dev/null || true

echo "✅ Ethernet config created/fixed"
echo ""
echo "Config:"
sudo cat "$ROOTFS/etc/NetworkManager/system-connections/Ethernet.nmconnection"
echo ""
echo "✅✅✅ ETHERNET FIXED ✅✅✅"
echo ""
echo "After boot:"
echo "  Pi should get: 192.168.10.2"
echo "  Test: ping 192.168.10.2"
echo "  SSH: ssh andre@192.168.10.2"
echo ""

