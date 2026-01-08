#!/bin/bash
# Apply local WiFi configuration to SD card
# Run: sudo ./APPLY_WIFI_CONFIG.sh

ROOTFS="/Volumes/rootfs"
BOOTFS="/Volumes/bootfs"

echo "=== APPLYING LOCAL WIFI CONFIG ==="
echo ""

if [ ! -d "$ROOTFS" ]; then
    echo "❌ SD card not mounted"
    exit 1
fi

# Create WiFi config
cat > /tmp/wpa_supplicant.conf << 'EOF'
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
update_config=1
country=US

network={
    ssid="moode-audio"
    psk="moode0815"
    key_mgmt=WPA-PSK
}
EOF

# Copy to boot partition
if [ -d "$BOOTFS" ]; then
    cp /tmp/wpa_supplicant.conf "$BOOTFS/wpa_supplicant.conf"
    echo "✅ WiFi config copied to boot partition"
elif [ -d "$ROOTFS/boot/firmware" ]; then
    cp /tmp/wpa_supplicant.conf "$ROOTFS/boot/firmware/wpa_supplicant.conf"
    echo "✅ WiFi config copied to rootfs boot"
else
    mkdir -p "$ROOTFS/boot/firmware"
    cp /tmp/wpa_supplicant.conf "$ROOTFS/boot/firmware/wpa_supplicant.conf"
    echo "✅ WiFi config created in rootfs boot"
fi

echo ""
echo "WiFi Configuration:"
echo "  SSID: moode-audio"
echo "  Password: moode0815"
echo ""
echo "✅✅✅ WIFI CONFIG APPLIED ✅✅✅"
echo ""
echo "Next:"
echo "1. Set up Mac hotspot 'moode-audio' (password: moode0815)"
echo "2. Eject SD card and boot Pi"
echo "3. Pi will connect automatically"
echo ""

