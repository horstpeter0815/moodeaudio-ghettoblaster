#!/bin/bash
# Create network diagnostic script with unique name
# Run: sudo ~/moodeaudio-cursor/CREATE_NET_DIAG_SCRIPT.sh

ROOTFS="/Volumes/rootfs"

if [ ! -d "$ROOTFS" ]; then
    echo "❌ Root partition not mounted"
    exit 1
fi

echo "=== Creating network diagnostic script ==="

mkdir -p "$ROOTFS/usr/local/bin"
cat > "$ROOTFS/usr/local/bin/ndiag" << 'EOF'
#!/bin/bash
echo "========================================"
echo "NETWORK DIAGNOSTICS"
echo "========================================"
echo ""
echo "=== IP ADDRESSES ==="
hostname -I
echo ""
echo "=== ETHERNET (eth0) ==="
ip link show eth0 2>/dev/null | head -2
ip addr show eth0 2>/dev/null | grep "inet "
echo ""
echo "=== WIFI (wlan0) ==="
ip link show wlan0 2>/dev/null | head -2
ip addr show wlan0 2>/dev/null | grep "inet "
echo ""
echo "=== NETWORKMANAGER STATUS ==="
systemctl is-active NetworkManager 2>/dev/null && echo "NetworkManager: RUNNING" || echo "NetworkManager: NOT RUNNING"
echo ""
echo "=== NETWORKMANAGER DEVICES ==="
nmcli device status 2>/dev/null || echo "nmcli not available"
echo ""
echo "========================================"
EOF

chmod +x "$ROOTFS/usr/local/bin/ndiag"
echo "✅ Created: ndiag (run: ndiag)"

# Also create full diagnostic
cat > "$ROOTFS/usr/local/bin/nfix" << 'EOF'
#!/bin/bash
echo "=== FIXING NETWORK ==="
sudo ip link set eth0 up 2>/dev/null
sudo systemctl restart NetworkManager 2>/dev/null
sleep 3
echo "=== STATUS AFTER FIX ==="
ip addr show eth0 2>/dev/null | grep "inet " || echo "No IP address"
EOF

chmod +x "$ROOTFS/usr/local/bin/nfix"
echo "✅ Created: nfix (run: sudo nfix)"

# Copy to home directory
mkdir -p "$ROOTFS/home/andre"
cp "$ROOTFS/usr/local/bin/ndiag" "$ROOTFS/home/andre/ndiag"
cp "$ROOTFS/usr/local/bin/nfix" "$ROOTFS/home/andre/nfix"
chmod +x "$ROOTFS/home/andre/"*
echo "✅ Also created in /home/andre/"

echo ""
echo "=== DONE ==="
echo "Commands:"
echo "  ndiag  - Network diagnostics"
echo "  nfix   - Fix network (needs sudo)"




