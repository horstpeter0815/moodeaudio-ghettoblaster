#!/bin/bash
# Setup WiFi for moOde using NetworkManager (REAL SOLUTION)
# Run: sudo ~/moodeaudio-cursor/SETUP_NETWORKMANAGER_WIFI.sh

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

SSID="Centara Nova Hotel"
PSK="password"

echo "=== Setting up WiFi for moOde (NetworkManager) ==="
echo ""

# 1. Create NetworkManager connection file on boot partition
echo "1. Creating NetworkManager connection file..."
UUID=$(uuidgen | tr '[:upper:]' '[:lower:]')
cat > "$BOOTFS/preconfigured.nmconnection" << EOF
[connection]
id=preconfigured
type=wifi
interface-name=wlan0

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
EOF
echo "✅ Created $BOOTFS/preconfigured.nmconnection"

# 2. Create script to copy NetworkManager config on boot
echo ""
echo "2. Creating copy script..."
mkdir -p "$ROOTFS/usr/local/bin"
cat > "$ROOTFS/usr/local/bin/copy-nm-wifi-config.sh" << 'SCRIPT_EOF'
#!/bin/bash
if [ -f /boot/firmware/preconfigured.nmconnection ]; then
    mkdir -p /etc/NetworkManager/system-connections
    cp /boot/firmware/preconfigured.nmconnection /etc/NetworkManager/system-connections/preconfigured.nmconnection
    chmod 600 /etc/NetworkManager/system-connections/preconfigured.nmconnection
    echo "✅ NetworkManager WiFi config copied"
    systemctl restart NetworkManager 2>/dev/null || true
fi
SCRIPT_EOF
chmod +x "$ROOTFS/usr/local/bin/copy-nm-wifi-config.sh"
echo "✅ Created copy script"

# 3. Create systemd service
echo ""
echo "3. Creating systemd service..."
mkdir -p "$ROOTFS/etc/systemd/system"
cat > "$ROOTFS/etc/systemd/system/copy-nm-wifi-config.service" << 'SERVICE_EOF'
[Unit]
Description=Copy NetworkManager WiFi Config from Boot Partition
After=local-fs.target
Before=NetworkManager.service

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/local/bin/copy-nm-wifi-config.sh

[Install]
WantedBy=multi-user.target
SERVICE_EOF
echo "✅ Created service file"

# 4. Enable service
echo ""
echo "4. Enabling service..."
mkdir -p "$ROOTFS/etc/systemd/system/multi-user.target.wants"
ln -sf ../copy-nm-wifi-config.service "$ROOTFS/etc/systemd/system/multi-user.target.wants/copy-nm-wifi-config.service"
echo "✅ Service enabled"

echo ""
echo "=== Setup Complete ==="
echo ""
echo "NetworkManager WiFi configuration created for:"
echo "  SSID: $SSID"
echo ""
echo "Next steps:"
echo "  1. Eject SD card"
echo "  2. Boot Pi"
echo "  3. WiFi should connect via NetworkManager"




