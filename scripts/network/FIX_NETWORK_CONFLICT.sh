#!/bin/bash
################################################################################
# FIX NETWORK CONFLICT - Disable static IP, enable DHCP only
# The static IP services are preventing DHCP from working
################################################################################

set -e

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  🔧 FIXING NETWORK CONFLICT                                   ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

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

echo "Using rootfs: $ROOTFS"
echo ""

# Disable static IP services that conflict with DHCP
echo "1. Disabling static IP services..."
WANTS_DIR="$ROOTFS/etc/systemd/system/multi-user.target.wants"

# Disable static IP services
for service in "02-eth0-configure.service" "04-network-lan.service"; do
    if [ -L "$WANTS_DIR/$service" ]; then
        rm -f "$WANTS_DIR/$service"
        echo "   ✅ Disabled: $service"
    fi
done

# Ensure DHCP service is enabled and has higher priority
echo ""
echo "2. Ensuring DHCP service is enabled..."
if [ -f "$ROOTFS/lib/systemd/system/eth0-dhcp.service" ]; then
    ln -sf "/lib/systemd/system/eth0-dhcp.service" \
           "$WANTS_DIR/eth0-dhcp.service" 2>/dev/null || true
    echo "   ✅ DHCP service enabled"
else
    echo "   ⚠️  DHCP service not found - creating..."
    SERVICE_FILE="$ROOTFS/lib/systemd/system/eth0-dhcp.service"
    mkdir -p "$(dirname "$SERVICE_FILE")"
    
    cat > "$SERVICE_FILE" << 'EOF'
[Unit]
Description=Configure Ethernet with DHCP
After=network-pre.target
Before=network.target
Wants=network-pre.target

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/bin/bash -c '
    echo "Configuring Ethernet with DHCP..."
    sleep 5
    if [ -d /sys/class/net/eth0 ]; then
        ip link set eth0 up
        if command -v dhclient >/dev/null 2>&1; then
            dhclient -v eth0
        elif command -v dhcpcd >/dev/null 2>&1; then
            dhcpcd eth0
        fi
    fi
'

[Install]
WantedBy=multi-user.target
EOF
    chmod 644 "$SERVICE_FILE"
    ln -sf "/lib/systemd/system/eth0-dhcp.service" \
           "$WANTS_DIR/eth0-dhcp.service"
    echo "   ✅ DHCP service created and enabled"
fi

# Also create NetworkManager config for DHCP
echo ""
echo "3. Creating NetworkManager DHCP config..."
mkdir -p "$ROOTFS/etc/NetworkManager/system-connections"
cat > "$ROOTFS/etc/NetworkManager/system-connections/eth0-dhcp.nmconnection" << 'EOF'
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
EOF
chmod 600 "$ROOTFS/etc/NetworkManager/system-connections/eth0-dhcp.nmconnection"
echo "   ✅ NetworkManager DHCP config created"

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  ✅ NETWORK CONFLICT FIXED!                                   ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "Changes:"
echo "  ✅ Disabled static IP services (02-eth0-configure, 04-network-lan)"
echo "  ✅ Enabled DHCP service"
echo "  ✅ Created NetworkManager DHCP config"
echo ""
echo "Now Pi will:"
echo "  - Get IP from Mac's Internet Sharing (DHCP)"
echo "  - Not use static 192.168.10.2"
echo "  - Work with your Mac's network"
echo ""

