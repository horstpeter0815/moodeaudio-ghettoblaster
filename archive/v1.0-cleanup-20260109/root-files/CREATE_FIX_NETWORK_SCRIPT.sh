#!/bin/bash
# Create fix-network script on SD card
# Run: sudo ~/moodeaudio-cursor/CREATE_FIX_NETWORK_SCRIPT.sh

ROOTFS="/Volumes/rootfs"

if [ ! -d "$ROOTFS" ]; then
    echo "❌ Root partition not mounted at $ROOTFS"
    exit 1
fi

echo "=== Creating fix-network script on SD card ==="
echo ""

# Create script in /usr/local/bin/
mkdir -p "$ROOTFS/usr/local/bin"
cat > "$ROOTFS/usr/local/bin/fix-network.sh" << 'SCRIPT_EOF'
#!/bin/bash
# Fix Network - Bring up Ethernet and configure WiFi

echo "=== Fixing Network ==="
echo ""

# 1. Bring up Ethernet
echo "1. Bringing up Ethernet..."
sudo ip link set eth0 up 2>/dev/null || echo "  ⚠️  eth0 not found"
sleep 2

# 2. Restart NetworkManager
echo "2. Restarting NetworkManager..."
sudo systemctl restart NetworkManager 2>/dev/null || echo "  ⚠️  NetworkManager not running"
sleep 5

# 3. Check Ethernet IP
echo "3. Checking Ethernet..."
ETH_IP=$(ip addr show eth0 2>/dev/null | grep "inet " | awk '{print $2}' | cut -d/ -f1)
if [ -n "$ETH_IP" ]; then
    echo "  ✅ Ethernet IP: $ETH_IP"
else
    echo "  ❌ Ethernet: No IP address"
fi

# 4. Convert WiFi config if needed
echo "4. Checking WiFi configuration..."
if [ -f /boot/firmware/wpa_supplicant.conf ] && [ ! -f /etc/NetworkManager/system-connections/preconfigured.nmconnection ]; then
    echo "  Converting wpa_supplicant.conf to NetworkManager format..."
    SSID=$(grep 'ssid=' /boot/firmware/wpa_supplicant.conf | sed 's/.*ssid="\([^"]*\)".*/\1/' | head -1)
    PSK=$(grep 'psk=' /boot/firmware/wpa_supplicant.conf | sed 's/.*psk="\([^"]*\)".*/\1/' | head -1)
    
    if [ -n "$SSID" ] && [ -n "$PSK" ]; then
        UUID=$(uuidgen | tr '[:upper:]' '[:lower:]' 2>/dev/null || echo "$(cat /proc/sys/kernel/random/uuid 2>/dev/null)")
        mkdir -p /etc/NetworkManager/system-connections
        cat > /etc/NetworkManager/system-connections/preconfigured.nmconnection << NMEOF
[connection]
id=preconfigured
uuid=$UUID
type=wifi
interface-name=wlan0
autoconnect=true
autoconnect-priority=100

[wifi]
mode=infrastructure
ssid=$SSID

[wifi-security]
key-mgmt=wpa-psk
psk=$PSK

[ipv4]
method=auto

[ipv6]
addr-gen-mode=stable-privacy
method=auto
NMEOF
        chmod 600 /etc/NetworkManager/system-connections/preconfigured.nmconnection
        sudo systemctl restart NetworkManager 2>/dev/null || true
        echo "  ✅ WiFi config converted"
        sleep 3
    fi
fi

# 5. Check all IP addresses
echo ""
echo "=== Network Status ==="
echo "Ethernet (eth0):"
ip addr show eth0 2>/dev/null | grep "inet " || echo "  No IP address"
echo ""
echo "WiFi (wlan0):"
ip addr show wlan0 2>/dev/null | grep "inet " || echo "  No IP address"
echo ""
echo "All IP addresses:"
hostname -I 2>/dev/null || ip addr show | grep "inet " | grep -v "127.0.0.1"

echo ""
echo "=== Done ==="
SCRIPT_EOF

chmod +x "$ROOTFS/usr/local/bin/fix-network.sh"
echo "✅ Created: $ROOTFS/usr/local/bin/fix-network.sh"
echo ""

# Also create in home directory for easy access
mkdir -p "$ROOTFS/home/andre"
cp "$ROOTFS/usr/local/bin/fix-network.sh" "$ROOTFS/home/andre/fix-network.sh"
chmod +x "$ROOTFS/home/andre/fix-network.sh"
echo "✅ Also created: $ROOTFS/home/andre/fix-network.sh"
echo ""

echo "=== Script Created ==="
echo ""
echo "On the Pi, run:"
echo "  sudo /usr/local/bin/fix-network.sh"
echo ""
echo "OR:"
echo "  sudo ~/fix-network.sh"
echo ""
echo "The script will:"
echo "  1. Bring up Ethernet"
echo "  2. Restart NetworkManager"
echo "  3. Convert WiFi config if needed"
echo "  4. Show all IP addresses"




