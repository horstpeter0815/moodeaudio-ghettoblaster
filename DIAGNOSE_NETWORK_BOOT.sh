#!/bin/bash
################################################################################
# DIAGNOSE NETWORK AT BOOT
# Creates diagnostic script to run on Pi to see what's happening
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

echo "Creating network diagnostic script on Pi..."
DIAG_SCRIPT="$ROOTFS/usr/local/bin/diagnose-network.sh"

cat > "$DIAG_SCRIPT" << 'EOF'
#!/bin/bash
echo "=== NETWORK DIAGNOSTIC ==="
echo ""
echo "1. Network interfaces:"
ip addr show
echo ""
echo "2. NetworkManager status:"
systemctl status NetworkManager --no-pager | head -20
echo ""
echo "3. NetworkManager connections:"
nmcli connection show
echo ""
echo "4. NetworkManager devices:"
nmcli device status
echo ""
echo "5. Active connections:"
nmcli connection show --active
echo ""
echo "6. eth0 details:"
nmcli device show eth0 2>/dev/null || echo "eth0 not found"
echo ""
echo "7. DHCP leases:"
cat /var/lib/dhcpcd5/dhcpcd-eth0.lease 2>/dev/null || echo "No DHCP lease file"
echo ""
echo "8. Routing table:"
ip route show
echo ""
echo "9. DNS:"
cat /etc/resolv.conf
EOF

chmod +x "$DIAG_SCRIPT"
echo "✅ Diagnostic script created: $DIAG_SCRIPT"
echo ""
echo "Run this on Pi after boot to see what's happening:"
echo "  sudo /usr/local/bin/diagnose-network.sh"

