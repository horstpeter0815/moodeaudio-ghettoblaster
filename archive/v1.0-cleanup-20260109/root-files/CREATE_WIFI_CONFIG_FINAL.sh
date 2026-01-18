#!/bin/bash
# Create WiFi config for Centara Nova Hotel on boot partition
# Run: sudo ./CREATE_WIFI_CONFIG_FINAL.sh

BOOTFS="/Volumes/bootfs"

if [ ! -d "$BOOTFS" ]; then
    echo "❌ Boot partition not found at $BOOTFS"
    echo "Please mount boot partition first"
    exit 1
fi

echo "=== Creating WiFi Configuration ==="
echo "Location: $BOOTFS/wpa_supplicant.conf"
echo ""

sudo tee "$BOOTFS/wpa_supplicant.conf" > /dev/null << 'EOF'
country=US
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
update_config=1

network={
    ssid="Centara Nova Hotel"
    key_mgmt=WPA-EAP
    eap=PEAP
    identity="309"
    password="Password"
    phase2="auth=MSCHAPV2"
}
EOF

echo "✅ WiFi configuration created!"
echo ""
echo "Verifying..."
cat "$BOOTFS/wpa_supplicant.conf"
echo ""
echo "✅ Done! Eject SD card and boot Pi."

