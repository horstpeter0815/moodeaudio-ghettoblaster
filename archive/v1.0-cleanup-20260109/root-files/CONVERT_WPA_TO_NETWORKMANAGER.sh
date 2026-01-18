#!/bin/bash
# Convert wpa_supplicant.conf to NetworkManager format
# Multiple fallback solutions for WiFi on first boot

BOOTFS="/Volumes/bootfs"
ROOTFS="/Volumes/rootfs"

if [ ! -d "$BOOTFS" ]; then
    echo "❌ Boot partition not mounted"
    exit 1
fi

if [ ! -d "$ROOTFS" ]; then
    echo "❌ Root partition not mounted"
    exit 1
fi

WPA_FILE="$BOOTFS/wpa_supplicant.conf"

if [ ! -f "$WPA_FILE" ]; then
    echo "❌ wpa_supplicant.conf not found on boot partition"
    exit 1
fi

echo "=== Converting wpa_supplicant.conf to NetworkManager format ==="
echo ""

# Extract SSID and PSK from wpa_supplicant.conf (macOS compatible)
SSID=$(grep 'ssid=' "$WPA_FILE" | sed 's/.*ssid="\([^"]*\)".*/\1/' | head -1)
PSK=$(grep 'psk=' "$WPA_FILE" | sed 's/.*psk="\([^"]*\)".*/\1/' | head -1)

if [ -z "$SSID" ] || [ -z "$PSK" ]; then
    echo "❌ Could not extract SSID or PSK from wpa_supplicant.conf"
    exit 1
fi

echo "Found WiFi config:"
echo "  SSID: $SSID"
echo "  PSK: $PSK"
echo ""

# Generate UUID
UUID=$(uuidgen | tr '[:upper:]' '[:lower:]')

# Create NetworkManager connection file
echo "1. Creating preconfigured.nmconnection on boot partition..."
cat > "$BOOTFS/preconfigured.nmconnection" << EOF
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
EOF
echo "✅ Created $BOOTFS/preconfigured.nmconnection"
echo ""

# Create conversion script that runs on boot
echo "2. Creating conversion script for boot..."
mkdir -p "$ROOTFS/usr/local/bin"
cat > "$ROOTFS/usr/local/bin/convert-wpa-to-nm.sh" << 'SCRIPT_EOF'
#!/bin/bash
# Convert wpa_supplicant.conf to NetworkManager format on boot

# Fallback 1: Copy preconfigured.nmconnection if it exists
if [ -f /boot/firmware/preconfigured.nmconnection ]; then
    mkdir -p /etc/NetworkManager/system-connections
    cp /boot/firmware/preconfigured.nmconnection /etc/NetworkManager/system-connections/preconfigured.nmconnection
    chmod 600 /etc/NetworkManager/system-connections/preconfigured.nmconnection
    echo "✅ Copied preconfigured.nmconnection"
fi

# Fallback 2: Convert wpa_supplicant.conf if NetworkManager file doesn't exist
if [ ! -f /etc/NetworkManager/system-connections/preconfigured.nmconnection ] && [ -f /boot/firmware/wpa_supplicant.conf ]; then
    SSID=$(grep 'ssid=' /boot/firmware/wpa_supplicant.conf | sed 's/.*ssid="\([^"]*\)".*/\1/' | head -1)
    PSK=$(grep 'psk=' /boot/firmware/wpa_supplicant.conf | sed 's/.*psk="\([^"]*\)".*/\1/' | head -1)
    
    if [ -n "$SSID" ] && [ -n "$PSK" ]; then
        UUID=$(uuidgen | tr '[:upper:]' '[:lower:]')
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
        echo "✅ Converted wpa_supplicant.conf to NetworkManager format"
    fi
fi

# Restart NetworkManager if file was created
if [ -f /etc/NetworkManager/system-connections/preconfigured.nmconnection ]; then
    systemctl restart NetworkManager 2>/dev/null || true
fi
SCRIPT_EOF
chmod +x "$ROOTFS/usr/local/bin/convert-wpa-to-nm.sh"
echo "✅ Created conversion script"
echo ""

# Create systemd service
echo "3. Creating systemd service..."
mkdir -p "$ROOTFS/etc/systemd/system"
cat > "$ROOTFS/etc/systemd/system/convert-wpa-to-nm.service" << 'SERVICE_EOF'
[Unit]
Description=Convert WiFi Config to NetworkManager Format
After=local-fs.target
Before=NetworkManager.service

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/local/bin/convert-wpa-to-nm.sh

[Install]
WantedBy=multi-user.target
SERVICE_EOF
echo "✅ Created service file"
echo ""

# Enable service
echo "4. Enabling service..."
mkdir -p "$ROOTFS/etc/systemd/system/multi-user.target.wants"
ln -sf ../convert-wpa-to-nm.service "$ROOTFS/etc/systemd/system/multi-user.target.wants/convert-wpa-to-nm.service"
echo "✅ Service enabled"
echo ""

# Also copy wpa_supplicant.conf to /etc/wpa_supplicant/ as additional fallback
echo "5. Creating additional fallback (wpa_supplicant)..."
mkdir -p "$ROOTFS/etc/wpa_supplicant"
cp "$WPA_FILE" "$ROOTFS/etc/wpa_supplicant/wpa_supplicant.conf"
echo "✅ Copied wpa_supplicant.conf to /etc/wpa_supplicant/"
echo ""

echo "=== Setup Complete ==="
echo ""
echo "Created multiple fallbacks:"
echo "  1. ✅ preconfigured.nmconnection on boot partition (moOde format)"
echo "  2. ✅ Conversion script (converts wpa_supplicant.conf if needed)"
echo "  3. ✅ Systemd service (runs on boot)"
echo "  4. ✅ wpa_supplicant.conf in /etc/ (traditional fallback)"
echo ""
echo "WiFi should work on first boot!"

