#!/bin/bash
# Configure WiFi for network "309" on SD card
# Run: sudo ./configure-wifi-309.sh

set -e

BOOTFS_MOUNT="/Volumes/bootfs"
ROOTFS_MOUNT="/Volumes/rootfs"

echo "=== WiFi Configuration for Network '309' ==="
echo ""

# Check if boot partition is mounted
if [ ! -d "$BOOTFS_MOUNT" ]; then
    echo "❌ ERROR: Boot partition not mounted at $BOOTFS_MOUNT"
    echo "Please mount the boot partition first"
    exit 1
fi

echo "✅ Boot partition found at: $BOOTFS_MOUNT"
echo ""

# Create wpa_supplicant.conf
echo "📝 Creating wpa_supplicant.conf..."
sudo tee "$BOOTFS_MOUNT/wpa_supplicant.conf" > /dev/null << 'EOF'
country=US
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
update_config=1

network={
    ssid="309"
    psk="Password"
    key_mgmt=WPA-PSK
}
EOF

echo "✅ WiFi configuration created"
echo ""
echo "📋 Configuration:"
echo "  Network: 309"
echo "  Password: Password"
echo ""
echo "✅ WiFi will be configured on next boot"
echo ""
echo "📋 Next Steps:"
echo "1. Eject SD card safely"
echo "2. Boot Raspberry Pi"
echo "3. Pi will connect to network '309' automatically"
echo "4. Find Pi's IP address on network '309'"
echo ""

