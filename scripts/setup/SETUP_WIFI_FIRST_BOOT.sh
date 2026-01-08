#!/bin/bash
# Setup WiFi configuration to work on first boot
# Run: sudo ~/moodeaudio-cursor/SETUP_WIFI_FIRST_BOOT.sh

BOOTFS="/Volumes/bootfs"
ROOTFS="/Volumes/rootfs"

if [ ! -d "$BOOTFS" ]; then
    echo "❌ Boot partition not mounted at $BOOTFS"
    exit 1
fi

if [ ! -d "$ROOTFS" ]; then
    echo "❌ Root partition not mounted at $ROOTFS"
    exit 1
fi

echo "=== Setting up WiFi for first boot ==="
echo ""

# 1. Create wpa_supplicant.conf on boot partition
echo "1. Creating wpa_supplicant.conf on boot partition..."
cat > "$BOOTFS/wpa_supplicant.conf" << 'EOF'
country=US
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
update_config=1

network={
    ssid="Centara Nova Hotel"
    psk="password"
    key_mgmt=WPA2-PSK
}
EOF
echo "✅ Created $BOOTFS/wpa_supplicant.conf"

# 2. Create copy script
echo ""
echo "2. Creating copy script..."
mkdir -p "$ROOTFS/usr/local/bin"
cat > "$ROOTFS/usr/local/bin/copy-wifi-config.sh" << 'SCRIPT_EOF'
#!/bin/bash
if [ -f /boot/firmware/wpa_supplicant.conf ]; then
    mkdir -p /etc/wpa_supplicant
    cp /boot/firmware/wpa_supplicant.conf /etc/wpa_supplicant/wpa_supplicant.conf
    chmod 600 /etc/wpa_supplicant/wpa_supplicant.conf
    echo "✅ WiFi config copied from boot partition"
    systemctl restart wpa_supplicant 2>/dev/null || true
fi
SCRIPT_EOF
chmod +x "$ROOTFS/usr/local/bin/copy-wifi-config.sh"
echo "✅ Created copy script"

# 3. Create systemd service
echo ""
echo "3. Creating systemd service..."
mkdir -p "$ROOTFS/etc/systemd/system"
cat > "$ROOTFS/etc/systemd/system/copy-wifi-config.service" << 'SERVICE_EOF'
[Unit]
Description=Copy WiFi Config from Boot Partition
After=local-fs.target
Before=NetworkManager.service
Before=wpa_supplicant.service

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/local/bin/copy-wifi-config.sh

[Install]
WantedBy=multi-user.target
SERVICE_EOF
echo "✅ Created service file"

# 4. Enable service (create symlink)
echo ""
echo "4. Enabling service..."
mkdir -p "$ROOTFS/etc/systemd/system/multi-user.target.wants"
ln -sf ../copy-wifi-config.service "$ROOTFS/etc/systemd/system/multi-user.target.wants/copy-wifi-config.service"
echo "✅ Service enabled"

echo ""
echo "=== Setup Complete ==="
echo ""
echo "Files created:"
echo "  ✅ $BOOTFS/wpa_supplicant.conf"
echo "  ✅ $ROOTFS/usr/local/bin/copy-wifi-config.sh"
echo "  ✅ $ROOTFS/etc/systemd/system/copy-wifi-config.service"
echo "  ✅ Service enabled (symlink created)"
echo ""
echo "Next steps:"
echo "  1. Eject SD card: diskutil eject /Volumes/bootfs && diskutil eject /Volumes/rootfs"
echo "  2. Boot Pi"
echo "  3. WiFi should connect automatically on first boot"




