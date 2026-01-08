#!/bin/bash
# FIX NETWORK FOR DIRECT LAN CONNECTION - RUN WITH SUDO
# Configures Pi to use static IP 192.168.10.2 for direct LAN cable connection
# sudo /Users/andrevollmer/moodeaudio-cursor/FIX_NETWORK_DIRECT_LAN.sh

SD_MOUNT="/Volumes/bootfs"
[ ! -d "$SD_MOUNT" ] && SD_MOUNT="/Volumes/boot"

if [ ! -d "$SD_MOUNT" ]; then
    echo "❌ SD-Karte nicht gefunden"
    exit 1
fi

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  🔌 FIX NETWORK FOR DIRECT LAN CONNECTION                   ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

################################################################################
# CREATE NETWORK CONFIGURATION ON SD CARD
################################################################################

echo "=== CREATE NETWORK CONFIGURATION ==="
echo ""

# Create directory for network configs
NETWORK_DIR="$SD_MOUNT/network"
mkdir -p "$NETWORK_DIR"

# Method 1: NetworkManager (Moode uses this)
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
echo "✅ NetworkManager config: $NM_FILE"

# Method 2: systemd-networkd (fallback)
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
echo "✅ systemd-networkd config: $NETWORKD_FILE"

# Method 3: dhcpcd (fallback)
DHCPCD_FILE="$SD_MOUNT/dhcpcd.conf"
cat > "$DHCPCD_FILE" << 'EOF'
# Static IP for direct LAN connection
interface eth0
static ip_address=192.168.10.2/24
static routers=192.168.10.1
static domain_name_servers=192.168.10.1
EOF

chmod 644 "$DHCPCD_FILE"
echo "✅ dhcpcd config: $DHCPCD_FILE"

# Method 4: Create script that runs on boot
BOOT_SCRIPT="$SD_MOUNT/fix-network-direct-lan.sh"
cat > "$BOOT_SCRIPT" << 'EOF'
#!/bin/bash
# Fix network for direct LAN connection
# Runs on boot to set static IP

# Wait for eth0 to be available
for i in {1..30}; do
    if ip link show eth0 >/dev/null 2>&1; then
        break
    fi
    sleep 1
done

# Set static IP directly
if ip link show eth0 >/dev/null 2>&1; then
    ip addr add 192.168.10.2/24 dev eth0 2>/dev/null || true
    ip link set eth0 up
    ip route add default via 192.168.10.1 dev eth0 2>/dev/null || true
    echo "nameserver 192.168.10.1" > /etc/resolv.conf
    echo "✅ Static IP set: 192.168.10.2"
fi
EOF

chmod +x "$BOOT_SCRIPT"
echo "✅ Boot script: $BOOT_SCRIPT"

sync
echo ""
echo "✅ NETZWERK KONFIGURIERT!"
echo ""
echo "Pi IP: 192.168.10.2"
echo "Gateway: 192.168.10.1"
echo ""
echo "Nächste Schritte:"
echo "  1. Setze Mac IP: sudo ifconfig en4 192.168.10.1 netmask 255.255.255.0"
echo "  2. SD-Karte in Pi einstecken"
echo "  3. Pi booten"
echo "  4. Pi sollte 192.168.10.2 bekommen (nicht mehr 127.0.1.1)"

