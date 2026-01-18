#!/bin/bash
################################################################################
# PRIORITIZE ETHERNET OVER WIFI
# WiFi is connecting first, preventing Ethernet/DHCP from working
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

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  🔧 PRIORITIZING ETHERNET OVER WIFI                          ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

echo "1. Disabling WiFi services..."
# Disable wpa_supplicant
rm -f "$ROOTFS/etc/systemd/system/multi-user.target.wants/wpa_supplicant.service" 2>/dev/null || true
rm -f "$ROOTFS/etc/systemd/system/multi-user.target.wants/wpa_supplicant@wlan0.service" 2>/dev/null || true
echo "   ✅ WiFi services disabled"

echo ""
echo "2. Removing WiFi config..."
# Backup and remove WiFi config
if [ -f "$ROOTFS/etc/wpa_supplicant/wpa_supplicant.conf" ]; then
    mv "$ROOTFS/etc/wpa_supplicant/wpa_supplicant.conf" \
       "$ROOTFS/etc/wpa_supplicant/wpa_supplicant.conf.disabled" 2>/dev/null || true
    echo "   ✅ WiFi config disabled (backed up)"
fi

echo ""
echo "3. Setting Ethernet priority in NetworkManager..."
NM_CONN_DIR="$ROOTFS/etc/NetworkManager/system-connections"

# Update Ethernet connection to have highest priority
cat > "$NM_CONN_DIR/Ethernet.nmconnection" << 'EOF'
[connection]
id=Ethernet
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
chmod 600 "$NM_CONN_DIR/Ethernet.nmconnection"
echo "   ✅ Ethernet priority set to 100 (highest)"

echo ""
echo "4. Disabling WiFi NetworkManager connections..."
# Disable any WiFi connections
find "$NM_CONN_DIR" -name "*.nmconnection" -exec grep -l "type=wifi\|802-11-wireless" {} \; 2>/dev/null | while read file; do
    echo "   Disabling: $(basename "$file")"
    sed -i.bak 's/autoconnect=true/autoconnect=false/' "$file" 2>/dev/null || true
done

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  ✅ ETHERNET PRIORITIZED                                     ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "Changes:"
echo "  ✅ WiFi services disabled"
echo "  ✅ WiFi config disabled"
echo "  ✅ Ethernet has highest priority (100)"
echo "  ✅ WiFi NetworkManager connections disabled"
echo ""
echo "Pi will now:"
echo "  - Use Ethernet only"
echo "  - Get IP from Mac's Internet Sharing via DHCP"
echo "  - Not connect via WiFi"
echo ""

