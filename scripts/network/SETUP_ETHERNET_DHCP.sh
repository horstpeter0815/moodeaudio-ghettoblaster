#!/bin/bash
################################################################################
# SETUP ETHERNET DHCP FOR INTERNET SHARING
# Configures Ethernet to use DHCP so Pi gets IP from Mac's internet sharing
################################################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${GREEN}[ETH-DHCP]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  🔧 SETTING UP ETHERNET DHCP FOR INTERNET ACCESS             ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Find rootfs
if [ -d "/Volumes/rootfs 1" ]; then
    ROOTFS="/Volumes/rootfs 1"
elif [ -d "/Volumes/rootfs" ]; then
    ROOTFS="/Volumes/rootfs"
else
    error "Root partition not found"
    exit 1
fi

log "Using rootfs: $ROOTFS"

# Create DHCP Ethernet service
log "1. Creating Ethernet DHCP service..."
SERVICE_FILE="$ROOTFS/lib/systemd/system/eth0-dhcp.service"
mkdir -p "$(dirname "$SERVICE_FILE")"

cat > "$SERVICE_FILE" << 'EOF'
[Unit]
Description=Configure Ethernet with DHCP for Internet Access
After=network-pre.target
Before=network.target
Wants=network-pre.target

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/bin/bash -c '
    echo "🔧 Configuring Ethernet with DHCP..."
    
    # Wait for eth0 interface
    for i in {1..20}; do
        if [ -d /sys/class/net/eth0 ]; then
            echo "✅ eth0 interface found"
            break
        fi
        sleep 1
    done
    
    if [ -d /sys/class/net/eth0 ]; then
        # Bring up interface
        ip link set eth0 up
        
        # Use dhclient for DHCP (if available)
        if command -v dhclient >/dev/null 2>&1; then
            echo "Using dhclient for DHCP..."
            dhclient -v eth0 2>&1 || true
        elif command -v dhcpcd >/dev/null 2>&1; then
            echo "Using dhcpcd for DHCP..."
            dhcpcd eth0 2>&1 || true
        else
            echo "⚠️  No DHCP client found, trying NetworkManager..."
        fi
        
        # Also create NetworkManager connection for DHCP
        mkdir -p /etc/NetworkManager/system-connections
        cat > /etc/NetworkManager/system-connections/eth0-dhcp.nmconnection << NMEOF
[connection]
id=eth0-dhcp
type=ethernet
interface-name=eth0
autoconnect=true
autoconnect-priority=100

[ethernet]

[ipv4]
method=auto
dns=8.8.8.8;8.8.4.4

[ipv6]
method=auto
NMEOF
        chmod 600 /etc/NetworkManager/system-connections/eth0-dhcp.nmconnection
        echo "✅ NetworkManager DHCP connection created"
    else
        echo "⚠️  eth0 interface not found"
    fi
    
    echo "✅ Ethernet DHCP configuration complete"
'

[Install]
WantedBy=multi-user.target
EOF

log "✅ Service file created"

# Enable service
log "2. Enabling Ethernet DHCP service..."
ENABLE_DIR="$ROOTFS/etc/systemd/system/multi-user.target.wants"
mkdir -p "$ENABLE_DIR"
ln -sf "/lib/systemd/system/eth0-dhcp.service" \
       "$ENABLE_DIR/eth0-dhcp.service" 2>/dev/null || true
log "✅ Service enabled"

echo ""
log "=== ETHERNET DHCP SETUP COMPLETE ==="
echo ""
warn "Note: Static IP service (eth0-configure) will be disabled in favor of DHCP"
echo ""
echo "Configuration:"
echo "  - Ethernet will use DHCP"
echo "  - Pi will get IP from Mac's internet sharing"
echo "  - Internet access will be available"
echo ""
warn "Next steps:"
echo "  1. Eject SD card"
echo "  2. Boot Pi with Ethernet cable connected to Mac"
echo "  3. Mac should have Internet Sharing enabled"
echo "  4. Pi will automatically get IP and internet access"
echo ""

