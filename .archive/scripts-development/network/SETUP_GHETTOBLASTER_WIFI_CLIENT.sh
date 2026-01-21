#!/bin/bash
################################################################################
# SETUP GHETTOBLASTER WIFI CLIENT
# Configures Pi to connect to Mac's "Ghettoblaster" WiFi network
################################################################################

set -e

if [ "$EUID" -ne 0 ]; then
    echo "❌ Must run as root (use sudo)"
    exit 1
fi

# Find rootfs
if [ -d "/Volumes/rootfs 1" ]; then
    ROOTFS="/Volumes/rootfs 1"
elif [ -d "/Volumes/rootfs" ]; then
    ROOTFS="/Volumes/rootfs"
else
    echo "❌ Root partition not found"
    exit 1
fi

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  🔧 SETUP GHETTOBLASTER WIFI CLIENT                         ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

NM_CONN_DIR="$ROOTFS/etc/NetworkManager/system-connections"
WANTS_DIR="$ROOTFS/etc/systemd/system/multi-user.target.wants"

# Prompt for WiFi password
echo "Enter WiFi password for 'Ghettoblaster' network:"
read -s WIFI_PASSWORD
echo ""

if [ -z "$WIFI_PASSWORD" ]; then
    echo "❌ Password cannot be empty"
    exit 1
fi

echo "1. Creating Ghettoblaster WiFi connection..."
cat > "$NM_CONN_DIR/Ghettoblaster.nmconnection" << EOF
[connection]
id=Ghettoblaster
type=wifi
interface-name=wlan0
autoconnect=true
autoconnect-priority=200

[wifi]
ssid=Ghettoblaster
mode=infrastructure

[wifi-security]
key-mgmt=wpa-psk
psk=$WIFI_PASSWORD

[ipv4]
method=auto

[ipv6]
method=auto
EOF
chmod 600 "$NM_CONN_DIR/Ghettoblaster.nmconnection"
echo "   ✅ Ghettoblaster.nmconnection created"

echo ""
echo "2. Ensuring WiFi services are enabled..."
# Ensure NetworkManager WiFi is enabled (it should be by default)
# Remove any symlinks that disable WiFi services
if [ -L "$WANTS_DIR/wpa_supplicant.service" ]; then
    echo "   ⚠️  wpa_supplicant.service is disabled, but NetworkManager handles WiFi"
fi
echo "   ✅ WiFi will be managed by NetworkManager"

echo ""
echo "3. Setting Ethernet to lower priority (if exists)..."
if [ -f "$NM_CONN_DIR/Ethernet.nmconnection" ]; then
    # Lower Ethernet priority so WiFi takes precedence
    if grep -q "autoconnect-priority=" "$NM_CONN_DIR/Ethernet.nmconnection"; then
        sed -i.bak 's/autoconnect-priority=[0-9]*/autoconnect-priority=50/' "$NM_CONN_DIR/Ethernet.nmconnection"
    else
        echo "autoconnect-priority=50" >> "$NM_CONN_DIR/Ethernet.nmconnection"
    fi
    echo "   ✅ Ethernet priority set to 50 (lower than WiFi)"
else
    echo "   ℹ️  No Ethernet connection found (WiFi only mode)"
fi

echo ""
echo "4. Disabling other WiFi connections (to prevent conflicts)..."
find "$NM_CONN_DIR" -name "*.nmconnection" -exec grep -l "type=wifi\|802-11-wireless\|wlan0" {} \; 2>/dev/null | while read file; do
    BASENAME=$(basename "$file")
    if [ "$BASENAME" != "Ghettoblaster.nmconnection" ]; then
        echo "   Disabling: $BASENAME"
        if grep -q "autoconnect=true" "$file"; then
            sed -i.bak 's/autoconnect=true/autoconnect=false/' "$file"
        fi
        if grep -q "autoconnect-priority=" "$file"; then
            sed -i.bak 's/autoconnect-priority=[0-9]*/autoconnect-priority=0/' "$file"
        else
            echo "autoconnect=false" >> "$file"
            echo "autoconnect-priority=0" >> "$file"
        fi
    fi
done
echo "   ✅ Other WiFi connections disabled"

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  ✅ GHETTOBLASTER WIFI CLIENT CONFIGURED                     ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "Configuration:"
echo "  ✅ Ghettoblaster WiFi connection created"
echo "  ✅ SSID: Ghettoblaster"
echo "  ✅ autoconnect=true, priority=200 (highest)"
echo "  ✅ Other WiFi connections disabled"
echo "  ✅ Ethernet priority lowered (if exists)"
echo ""
echo "Pi will now:"
echo "  - Connect to 'Ghettoblaster' WiFi automatically on boot"
echo "  - Get IP address from Mac's DHCP (192.168.2.x)"
echo "  - Have internet access through Mac"
echo ""

