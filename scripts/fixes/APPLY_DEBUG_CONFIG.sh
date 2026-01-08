#!/bin/bash
# Apply debug config to SD card
# Run: cd ~/moodeaudio-cursor && sudo ./APPLY_DEBUG_CONFIG.sh

ROOTFS="/Volumes/rootfs"

if [ ! -d "$ROOTFS" ]; then
    echo "❌ SD card not mounted"
    exit 1
fi

echo "=== Applying Debug Configuration ==="
echo ""

# 1. Create Ethernet.nmconnection
echo "1. Creating Ethernet.nmconnection..."
UUID=$(uuidgen)
sudo mkdir -p "$ROOTFS/etc/NetworkManager/system-connections"
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
sudo chmod 600 "$ROOTFS/etc/NetworkManager/system-connections/Ethernet.nmconnection"
echo "✅ Ethernet.nmconnection created"

# 2. Copy instrumented network-mode-manager.sh
echo "2. Copying instrumented network-mode-manager.sh..."
sudo cp "$ROOTFS/usr/local/bin/network-mode-manager.sh" "$ROOTFS/usr/local/bin/network-mode-manager.sh.bak" 2>/dev/null || true
sudo cp "moode-source/usr/local/bin/network-mode-manager.sh" "$ROOTFS/usr/local/bin/network-mode-manager.sh"
sudo chmod +x "$ROOTFS/usr/local/bin/network-mode-manager.sh"
echo "✅ network-mode-manager.sh updated with logging"

# 3. Create log collection script
echo "3. Creating log collection script..."
sudo tee "$ROOTFS/usr/local/bin/collect-network-debug.sh" > /dev/null << 'EOF'
#!/bin/bash
# Collect network debug logs
LOG_FILE="/tmp/network-debug.log"
OUTPUT="/tmp/network-debug-collected.log"

echo "=== Network Debug Logs ===" > "$OUTPUT"
echo "Timestamp: $(date)" >> "$OUTPUT"
echo "" >> "$OUTPUT"

if [ -f "$LOG_FILE" ]; then
    echo "=== network-debug.log ===" >> "$OUTPUT"
    cat "$LOG_FILE" >> "$OUTPUT"
    echo "" >> "$OUTPUT"
fi

echo "=== Network Status ===" >> "$OUTPUT"
ip addr show eth0 >> "$OUTPUT" 2>&1
echo "" >> "$OUTPUT"
ip route show >> "$OUTPUT" 2>&1
echo "" >> "$OUTPUT"

echo "=== NetworkManager Status ===" >> "$OUTPUT"
systemctl status NetworkManager --no-pager -l >> "$OUTPUT" 2>&1
echo "" >> "$OUTPUT"

echo "=== NetworkManager Connections ===" >> "$OUTPUT"
nmcli connection show >> "$OUTPUT" 2>&1
echo "" >> "$OUTPUT"

cat "$OUTPUT"
EOF
sudo chmod +x "$ROOTFS/usr/local/bin/collect-network-debug.sh"
echo "✅ Log collection script created"

echo ""
echo "✅✅✅ Debug Configuration Applied ✅✅✅"
echo ""
echo "After boot, collect logs with:"
echo "  ssh andre@192.168.10.2"
echo "  sudo /usr/local/bin/collect-network-debug.sh"
echo ""

