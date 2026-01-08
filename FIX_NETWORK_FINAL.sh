#!/bin/bash
# FINAL Network Fix - Based on actual moOde NetworkManager configuration
# Run: sudo ~/moodeaudio-cursor/FIX_NETWORK_FINAL.sh

ROOTFS="/Volumes/rootfs"
BOOTFS="/Volumes/bootfs"

if [ ! -d "$ROOTFS" ] || [ ! -d "$BOOTFS" ]; then
    echo "❌ SD card partitions not mounted"
    exit 1
fi

echo "=== Creating FINAL Network Fix (NetworkManager) ==="
echo ""

# 1. Create script that converts wpa_supplicant.conf to preconfigured.nmconnection
mkdir -p "$ROOTFS/usr/local/bin"
cat > "$ROOTFS/usr/local/bin/import-wifi-config.sh" << 'SCRIPT_EOF'
#!/bin/bash
# Import WiFi config from boot partition to NetworkManager format
# Runs BEFORE NetworkManager starts

BOOT_WPA="/boot/firmware/wpa_supplicant.conf"
BOOT_NM="/boot/firmware/preconfigured.nmconnection"
NM_DIR="/etc/NetworkManager/system-connections"
NM_FILE="$NM_DIR/preconfigured.nmconnection"

# Create directory
mkdir -p "$NM_DIR"

# Priority 1: Use preconfigured.nmconnection if it exists on boot partition
if [ -f "$BOOT_NM" ]; then
    cp "$BOOT_NM" "$NM_FILE"
    chmod 600 "$NM_FILE"
    echo "✅ Copied preconfigured.nmconnection from boot partition"
    exit 0
fi

# Priority 2: Convert wpa_supplicant.conf to NetworkManager format
if [ -f "$BOOT_WPA" ]; then
    SSID=$(grep 'ssid=' "$BOOT_WPA" | sed 's/.*ssid="\([^"]*\)".*/\1/' | head -1)
    PSK=$(grep 'psk=' "$BOOT_WPA" | sed 's/.*psk="\([^"]*\)".*/\1/' | head -1)
    
    if [ -n "$SSID" ] && [ -n "$PSK" ]; then
        # Generate UUID (use system method)
        if command -v uuidgen >/dev/null 2>&1; then
            UUID=$(uuidgen | tr '[:upper:]' '[:lower:]')
        elif [ -f /proc/sys/kernel/random/uuid ]; then
            UUID=$(cat /proc/sys/kernel/random/uuid)
        else
            UUID=$(python3 -c "import uuid; print(str(uuid.uuid4()))" 2>/dev/null || echo "f8eba0b7-862d-4ccc-b93a-52815eb9c28d")
        fi
        
        cat > "$NM_FILE" << NMEOF
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
        chmod 600 "$NM_FILE"
        echo "✅ Converted wpa_supplicant.conf to NetworkManager format"
        exit 0
    fi
fi

echo "⚠️  No WiFi configuration found on boot partition"
exit 1
SCRIPT_EOF

chmod +x "$ROOTFS/usr/local/bin/import-wifi-config.sh"
echo "✅ Created import script"

# 2. Create systemd service that runs BEFORE NetworkManager
mkdir -p "$ROOTFS/etc/systemd/system"
cat > "$ROOTFS/etc/systemd/system/import-wifi-config.service" << 'SERVICE_EOF'
[Unit]
Description=Import WiFi Config from Boot Partition
After=local-fs.target
Before=NetworkManager.service
Before=network-pre.target

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/local/bin/import-wifi-config.sh

[Install]
WantedBy=multi-user.target
SERVICE_EOF
echo "✅ Created systemd service"

# 3. Enable service
mkdir -p "$ROOTFS/etc/systemd/system/multi-user.target.wants"
ln -sf ../import-wifi-config.service "$ROOTFS/etc/systemd/system/multi-user.target.wants/import-wifi-config.service"
echo "✅ Service enabled"

# 4. Also create preconfigured.nmconnection on boot partition (if wpa_supplicant.conf exists)
if [ -f "$BOOTFS/wpa_supplicant.conf" ]; then
    SSID=$(grep 'ssid=' "$BOOTFS/wpa_supplicant.conf" | sed 's/.*ssid="\([^"]*\)".*/\1/' | head -1)
    PSK=$(grep 'psk=' "$BOOTFS/wpa_supplicant.conf" | sed 's/.*psk="\([^"]*\)".*/\1/' | head -1)
    
    if [ -n "$SSID" ] && [ -n "$PSK" ]; then
        UUID=$(uuidgen | tr '[:upper:]' '[:lower:]' 2>/dev/null || echo "f8eba0b7-862d-4ccc-b93a-52815eb9c28d")
        cat > "$BOOTFS/preconfigured.nmconnection" << NMEOF
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
        echo "✅ Created preconfigured.nmconnection on boot partition"
    fi
fi

echo ""
echo "=== Setup Complete ==="
echo ""
echo "Network fix created based on moOde NetworkManager architecture:"
echo "  ✅ Import script: /usr/local/bin/import-wifi-config.sh"
echo "  ✅ Systemd service: import-wifi-config.service"
echo "  ✅ Runs BEFORE NetworkManager starts"
echo "  ✅ Creates /etc/NetworkManager/system-connections/preconfigured.nmconnection"
echo "  ✅ worker.php will import it automatically"
echo ""
echo "WiFi will work on first boot!"




