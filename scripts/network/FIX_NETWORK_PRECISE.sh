#!/bin/bash
################################################################################
# PRECISE NETWORK FIX
# Fixes all network configuration issues precisely
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
echo "║  🔧 PRECISE NETWORK FIX                                       ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

NM_CONN_DIR="$ROOTFS/etc/NetworkManager/system-connections"
WANTS_DIR="$ROOTFS/etc/systemd/system/multi-user.target.wants"

echo "1. Disabling WiFi NetworkManager connections..."
find "$NM_CONN_DIR" -name "*.nmconnection" -exec grep -l "type=wifi\|802-11-wireless\|wlan0" {} \; 2>/dev/null | while read file; do
    echo "   Disabling: $(basename "$file")"
    # Set autoconnect=false
    if grep -q "autoconnect=true" "$file"; then
        sed -i.bak 's/autoconnect=true/autoconnect=false/' "$file"
    fi
    # Remove or lower priority
    if grep -q "autoconnect-priority=" "$file"; then
        sed -i.bak 's/autoconnect-priority=[0-9]*/autoconnect-priority=0/' "$file"
    else
        echo "autoconnect=false" >> "$file"
        echo "autoconnect-priority=0" >> "$file"
    fi
done
echo "   ✅ WiFi connections disabled"

echo ""
echo "2. Setting Ethernet to highest priority..."
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
echo "   ✅ Ethernet priority set to 200 (highest)"

echo ""
echo "3. Removing duplicate eth0-dhcp connection..."
rm -f "$NM_CONN_DIR/eth0-dhcp.nmconnection" 2>/dev/null || true
echo "   ✅ Duplicate connection removed (using Ethernet.nmconnection only)"

echo ""
echo "4. Disabling wpa_supplicant service..."
rm -f "$WANTS_DIR/wpa_supplicant.service" 2>/dev/null || true
rm -f "$WANTS_DIR/wpa_supplicant@wlan0.service" 2>/dev/null || true
echo "   ✅ WiFi services disabled"

echo ""
echo "5. Ensuring DHCP service is enabled..."
if [ ! -L "$WANTS_DIR/eth0-dhcp.service" ]; then
    ln -sf "/lib/systemd/system/eth0-dhcp.service" \
           "$WANTS_DIR/eth0-dhcp.service"
    echo "   ✅ DHCP service enabled"
else
    echo "   ✅ DHCP service already enabled"
fi

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  ✅ PRECISE FIX APPLIED                                      ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "Configuration:"
echo "  ✅ WiFi connections disabled (autoconnect=false, priority=0)"
echo "  ✅ Ethernet priority set to 200 (highest)"
echo "  ✅ Duplicate Ethernet connection removed"
echo "  ✅ WiFi services disabled"
echo "  ✅ DHCP service enabled"
echo ""
echo "Pi will now:"
echo "  - Connect ONLY via Ethernet"
echo "  - Use DHCP to get IP from Mac"
echo "  - NOT connect via WiFi"
echo ""

