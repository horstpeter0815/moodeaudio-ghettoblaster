#!/bin/bash
################################################################################
# FIX NETWORKMANAGER TO USE DHCP
# NetworkManager is overriding our DHCP service - need to configure it directly
################################################################################

set -e

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  🔧 FIXING NETWORKMANAGER FOR DHCP                           ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

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

NM_CONN_DIR="$ROOTFS/etc/NetworkManager/system-connections"

echo "1. Updating Ethernet.nmconnection to use DHCP..."
cat > "$NM_CONN_DIR/Ethernet.nmconnection" << 'EOF'
[connection]
id=Ethernet
type=ethernet
interface-name=eth0
autoconnect=true
autoconnect-priority=10

[ethernet]

[ipv4]
method=auto
dns=8.8.8.8;8.8.4.4

[ipv6]
method=auto
EOF
chmod 600 "$NM_CONN_DIR/Ethernet.nmconnection"
echo "   ✅ Ethernet.nmconnection set to DHCP (method=auto)"

echo ""
echo "2. Ensuring eth0-dhcp.nmconnection uses DHCP..."
cat > "$NM_CONN_DIR/eth0-dhcp.nmconnection" << 'EOF'
[connection]
id=eth0-dhcp
type=ethernet
interface-name=eth0
autoconnect=true
autoconnect-priority=100

[ethernet]

[ipv4]
method=auto
dns=8.8.8.8;8.8.4.4

[ipv6]
method=auto
EOF
chmod 600 "$NM_CONN_DIR/eth0-dhcp.nmconnection"
echo "   ✅ eth0-dhcp.nmconnection configured with higher priority (100)"

echo ""
echo "3. Removing any static IP configs..."
# Remove static IP configs if they exist
find "$NM_CONN_DIR" -name "*.nmconnection" -exec grep -l "method=manual\|192.168.10.2" {} \; 2>/dev/null | while read file; do
    if [ "$(basename "$file")" != "Ethernet.nmconnection" ] && [ "$(basename "$file")" != "eth0-dhcp.nmconnection" ]; then
        echo "   Removing static config: $(basename "$file")"
        rm -f "$file"
    fi
done

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  ✅ NETWORKMANAGER CONFIGURED FOR DHCP                       ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "NetworkManager will now:"
echo "  ✅ Use DHCP (method=auto) for eth0"
echo "  ✅ Get IP from Mac's Internet Sharing"
echo "  ✅ Not use static IP"
echo ""

