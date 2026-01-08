#!/bin/bash
# SETUP DIRECT LAN CABLE CONNECTION
# Mac: 192.168.10.1, Pi: 192.168.10.2
# sudo /Users/andrevollmer/moodeaudio-cursor/SETUP_DIRECT_LAN_CONNECTION.sh

SD_MOUNT="/Volumes/bootfs"
[ ! -d "$SD_MOUNT" ] && SD_MOUNT="/Volumes/boot"

if [ ! -d "$SD_MOUNT" ]; then
    echo "❌ SD-Karte nicht gefunden"
    exit 1
fi

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  🔌 SETUP DIRECT LAN CABLE CONNECTION                        ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

################################################################################
# STEP 1: SET STATIC IP ON MAC (en4)
################################################################################

echo "=== STEP 1: SET STATIC IP ON MAC ==="
echo ""

# Find Ethernet interface
ETH_INTERFACE="en4"
if ! ifconfig $ETH_INTERFACE >/dev/null 2>&1; then
    # Try to find active Ethernet interface
    ETH_INTERFACE=$(ifconfig | grep -E "^en[0-9]" | grep -v "lo0" | head -1 | cut -d: -f1)
fi

if [ -z "$ETH_INTERFACE" ]; then
    echo "⚠️  Ethernet Interface nicht gefunden"
    echo "   Bitte manuell in System Settings konfigurieren:"
    echo "   System Settings → Network → Ethernet"
    echo "   IP: 192.168.10.1"
    echo "   Subnet: 255.255.255.0"
else
    echo "Ethernet Interface: $ETH_INTERFACE"
    echo ""
    echo "Setze statische IP auf Mac..."
    echo "IP: 192.168.10.1"
    echo "Subnet: 255.255.255.0"
    echo ""
    echo "Führe manuell aus:"
    echo "  sudo ifconfig $ETH_INTERFACE 192.168.10.1 netmask 255.255.255.0"
    echo ""
    echo "ODER in System Settings:"
    echo "  System Settings → Network → Ethernet → Configure IPv4 → Manually"
    echo "  IP: 192.168.10.1"
    echo "  Subnet: 255.255.255.0"
fi

echo ""

################################################################################
# STEP 2: CONFIGURE PI STATIC IP ON SD CARD
################################################################################

echo "=== STEP 2: CONFIGURE PI STATIC IP ON SD CARD ==="
echo ""

# Create network configuration for Pi
NETWORK_DIR="$SD_MOUNT/network"
mkdir -p "$NETWORK_DIR"

# Method 1: systemd-networkd (if used)
NETWORKD_FILE="$NETWORK_DIR/10-ethernet-static.network"
cat > "$NETWORKD_FILE" << 'EOF'
[Match]
Name=eth0

[Network]
Address=192.168.10.2/24
Gateway=192.168.10.1
DNS=192.168.10.1
EOF

chmod 644 "$NETWORKD_FILE"
echo "✅ systemd-networkd config erstellt: $NETWORKD_FILE"

# Method 2: dhcpcd (if used)
DHCPCD_FILE="$SD_MOUNT/dhcpcd.conf"
if [ ! -f "$DHCPCD_FILE" ]; then
    cat > "$DHCPCD_FILE" << 'EOF'
# Static IP for direct LAN connection
interface eth0
static ip_address=192.168.10.2/24
static routers=192.168.10.1
static domain_name_servers=192.168.10.1
EOF
    echo "✅ dhcpcd.conf erstellt: $DHCPCD_FILE"
fi

# Method 3: NetworkManager (for Moode)
NM_FILE="$NETWORK_DIR/Ethernet-static.nmconnection"
cat > "$NM_FILE" << 'EOF'
[connection]
id=Ethernet-static
type=ethernet
interface-name=eth0
autoconnect=true
autoconnect-priority=100

[ethernet]

[ipv4]
method=manual
addresses=192.168.10.2/24
gateway=192.168.10.1
dns=192.168.10.1;

[ipv6]
method=auto
EOF

chmod 600 "$NM_FILE"
echo "✅ NetworkManager config erstellt: $NM_FILE"

sync
echo ""

################################################################################
# VERIFICATION
################################################################################

echo "=== VERIFICATION ==="
echo ""

echo "Pi Konfiguration auf SD-Karte:"
echo "  IP: 192.168.10.2"
echo "  Gateway: 192.168.10.1"
echo "  Subnet: 255.255.255.0"
echo ""

echo "Nächste Schritte:"
echo "  1. Setze Mac IP: 192.168.10.1 (siehe oben)"
echo "  2. SD-Karte in Pi einstecken"
echo "  3. Pi booten"
echo "  4. Pi sollte erreichbar sein: 192.168.10.2"
echo ""

echo "✅ Konfiguration auf SD-Karte abgeschlossen!"

