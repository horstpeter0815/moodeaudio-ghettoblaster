#!/bin/bash
# Create WiFi configuration on SD card boot partition
# Run: sudo ~/moodeaudio-cursor/WIFI_SETUP_SD_CARD.sh

BOOT="/Volumes/bootfs"

if [ ! -d "$BOOT" ]; then
    echo "❌ Boot partition not mounted at $BOOT"
    echo "Mount SD card first: diskutil mount disk4s1"
    exit 1
fi

echo "Creating WiFi configuration..."

cat > "$BOOT/wpa_supplicant.conf" << 'EOF'
country=US
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
update_config=1

network={
    ssid="Centara Nova Hotel"
    psk="password"
}
EOF

echo "✅ WiFi configuration created at $BOOT/wpa_supplicant.conf"
echo ""
echo "Configuration:"
echo "  SSID: Centara Nova Hotel"
echo "  Password: password"
echo ""
echo "Note: If hotel WiFi requires username (WPA-EAP), you may need to"
echo "configure via moOde Web UI after first connection."
echo ""
echo "Eject SD card and boot Pi. WiFi should connect automatically."




