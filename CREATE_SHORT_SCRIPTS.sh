#!/bin/bash
# Create short scripts on SD card
# Run: sudo ~/moodeaudio-cursor/CREATE_SHORT_SCRIPTS.sh

ROOTFS="/Volumes/rootfs"

if [ ! -d "$ROOTFS" ]; then
    echo "❌ Root partition not mounted"
    exit 1
fi

echo "=== Creating short diagnostic scripts ==="

# 1. NET - Network diagnostics (very short command)
mkdir -p "$ROOTFS/usr/local/bin"
cat > "$ROOTFS/usr/local/bin/net" << 'EOF'
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

chmod +x "$ROOTFS/usr/local/bin/net"
echo "✅ Created: net (run: net)"

# 2. FIX - Fix network (bring up eth0)
cat > "$ROOTFS/usr/local/bin/fix" << 'EOF'
#!/bin/bash
echo "=== FIXING NETWORK ==="
sudo ip link set eth0 up
sudo systemctl restart NetworkManager
sleep 3
echo "=== STATUS ==="
ip addr show eth0 | grep "inet "
EOF

chmod +x "$ROOTFS/usr/local/bin/fix"
echo "✅ Created: fix (run: sudo fix)"

# 3. DIAG - Full diagnostics
cat > "$ROOTFS/usr/local/bin/diag" << 'EOF'
#!/bin/bash
echo "========================================"
echo "FULL NETWORK DIAGNOSTICS"
echo "========================================"
echo ""
echo "=== ALL IP ADDRESSES ==="
hostname -I
ip addr show | grep "inet " | grep -v "127.0.0.1"
echo ""
echo "=== ETHERNET ==="
ip link show eth0
ip addr show eth0
echo ""
echo "=== WIFI ==="
ip link show wlan0 2>/dev/null || echo "wlan0 not found"
ip addr show wlan0 2>/dev/null || echo "wlan0 no IP"
echo ""
echo "=== NETWORKMANAGER ==="
sudo systemctl status NetworkManager --no-pager | head -15
echo ""
echo "=== NETWORKMANAGER DEVICES ==="
sudo nmcli device status
echo ""
echo "=== NETWORKMANAGER CONNECTIONS ==="
sudo nmcli connection show
echo ""
echo "=== SYSTEMD NETWORK SERVICES ==="
systemctl list-units | grep -i network
echo ""
echo "========================================"
EOF

chmod +x "$ROOTFS/usr/local/bin/diag"
echo "✅ Created: diag (run: diag)"

# Also create in home directory for easy access
mkdir -p "$ROOTFS/home/andre"
cp "$ROOTFS/usr/local/bin/net" "$ROOTFS/home/andre/net"
cp "$ROOTFS/usr/local/bin/fix" "$ROOTFS/home/andre/fix"
cp "$ROOTFS/usr/local/bin/diag" "$ROOTFS/home/andre/diag"
chmod +x "$ROOTFS/home/andre/"*
echo "✅ Also created in /home/andre/"

echo ""
echo "=== DONE ==="
echo ""
echo "Short commands available:"
echo "  net   - Quick network status"
echo "  fix   - Fix network (bring up eth0)"
echo "  diag  - Full diagnostics"
echo ""
echo "Run on Pi:"
echo "  net          (no sudo needed)"
echo "  sudo fix     (needs sudo)"
echo "  diag         (shows everything)"




