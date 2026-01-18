#!/bin/bash
################################################################################
# Fix NetworkManager priority to ensure Ethernet static IP works
################################################################################

set -e

if [ "$EUID" -ne 0 ]; then
    echo "❌ Must run as root (use sudo)"
    exit 1
fi

# Find rootfs
if [ -d "/Volumes/rootfs 1" ]; then
    ROOTFS="/Volumes/rootfs 1"
elif [ -d "/Volumes/rootfs" ]; then
    ROOTFS="/Volumes/rootfs"
else
    echo "❌ Root partition not found"
    exit 1
fi

echo "Fixing NetworkManager priority..."
echo ""

NM_CONN_DIR="$ROOTFS/etc/NetworkManager/system-connections"

# Update Ethernet connection to have highest priority and ensure it's configured for static IP by default
cat > "$NM_CONN_DIR/Ethernet.nmconnection" << 'EOF'
[connection]
id=Ethernet
type=ethernet
interface-name=eth0
autoconnect=true
autoconnect-priority=200

[ethernet]

[ipv4]
method=auto
dns=8.8.8.8;8.8.4.4

[ipv6]
method=auto
EOF

chmod 600 "$NM_CONN_DIR/Ethernet.nmconnection"

echo "✅ NetworkManager Ethernet connection updated"
echo "   - Priority: 200 (highest)"
echo "   - Method: auto (DHCP)"
echo ""
echo "Note: The network mode manager will override this with static IP 192.168.10.2"
echo "      when it runs. NetworkManager priority ensures Ethernet is selected."
echo ""



