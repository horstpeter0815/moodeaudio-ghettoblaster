#!/bin/bash
# Configure WiFi for Centara Nova Hotel on SD card
# Run: sudo ./configure-hotel-wifi.sh

set -e

BOOTFS_MOUNT="/Volumes/bootfs"
ROOTFS_MOUNT="/Volumes/rootfs"

echo "=== WiFi Configuration for Centara Nova Hotel ==="
echo ""

# Check if boot partition is mounted
if [ ! -d "$BOOTFS_MOUNT" ]; then
    echo "❌ ERROR: Boot partition not mounted at $BOOTFS_MOUNT"
    echo "Please mount the boot partition first"
    exit 1
fi

echo "✅ Boot partition found at: $BOOTFS_MOUNT"
echo ""

# Network information
SSID="Centara Nova Hotel"
USERNAME="309"
PASSWORD="Password"

echo "📝 Creating wpa_supplicant.conf..."
echo "   Network: $SSID"
echo "   Username: $USERNAME"
echo "   Password: $PASSWORD"
echo ""

# Create wpa_supplicant.conf with WPA2 Enterprise (hotel networks usually use this)
sudo tee "$BOOTFS_MOUNT/wpa_supplicant.conf" > /dev/null << EOF
country=US
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
update_config=1

network={
    ssid="$SSID"
    key_mgmt=WPA-EAP
    eap=PEAP
    identity="$USERNAME"
    password="$PASSWORD"
    phase2="auth=MSCHAPV2"
}
EOF

echo "✅ WiFi configuration created"
echo ""
echo "📋 Configuration saved to: $BOOTFS_MOUNT/wpa_supplicant.conf"
echo ""
echo "✅ Pi will connect to 'Centara Nova Hotel' on next boot"
echo ""
echo "📋 Next Steps:"
echo "1. Eject SD card safely"
echo "2. Boot Raspberry Pi"
echo "3. Pi will connect to hotel WiFi automatically"
echo "4. Find Pi's IP address on the network"
echo ""

