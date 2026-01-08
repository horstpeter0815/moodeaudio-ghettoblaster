#!/bin/bash
# Create WiFi config for Centara Nova Hotel
# This creates the file content - you need to run with sudo

BOOT_PATH="/Volumes/rootfs/boot/firmware"
ALT_BOOT_PATH="/Volumes/bootfs"

echo "=== Creating WiFi Configuration ==="
echo ""
echo "Network: Centara Nova Hotel"
echo "Username: 309"
echo "Password: Password"
echo ""

# Try to create in firmware directory first
if [ -d "$BOOT_PATH" ]; then
    echo "Creating wpa_supplicant.conf in: $BOOT_PATH"
    sudo tee "$BOOT_PATH/wpa_supplicant.conf" > /dev/null << 'EOF'
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
    echo "✅ Created: $BOOT_PATH/wpa_supplicant.conf"
elif [ -d "$ALT_BOOT_PATH" ]; then
    echo "Creating wpa_supplicant.conf in: $ALT_BOOT_PATH"
    sudo tee "$ALT_BOOT_PATH/wpa_supplicant.conf" > /dev/null << 'EOF'
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
    echo "✅ Created: $ALT_BOOT_PATH/wpa_supplicant.conf"
else
    echo "❌ Boot partition not found"
    echo "Please mount SD card boot partition first"
    exit 1
fi

echo ""
echo "✅ WiFi configuration created!"
echo ""
echo "📋 Next: Eject SD card and boot Pi"

