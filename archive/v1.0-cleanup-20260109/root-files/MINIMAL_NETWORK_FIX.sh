#!/bin/bash
################################################################################
# MINIMAL NETWORK FIX - Just get the Pi reachable
# One service. One IP. No conflicts. That's it.
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

echo "Creating minimal network fix..."
echo ""

################################################################################
# ONE SERVICE - That's it
################################################################################

SERVICE_FILE="$ROOTFS/lib/systemd/system/minimal-network.service"
WANTS_DIR="$ROOTFS/etc/systemd/system/multi-user.target.wants"

cat > "$SERVICE_FILE" << 'EOF'
[Unit]
Description=Minimal Network - Just get an IP address
DefaultDependencies=no
After=local-fs.target
Before=network.target

[Service]
Type=oneshot
RemainAfterExit=yes

# Wait for eth0, then set IP. That's it.
ExecStart=/bin/bash -c '
    # Wait up to 20 seconds for eth0
    for i in {1..20}; do
        [ -d /sys/class/net/eth0 ] && break
        sleep 1
    done
    
    # If eth0 exists, configure it
    if [ -d /sys/class/net/eth0 ]; then
        ip link set eth0 up
        ip addr add 192.168.10.2/24 dev eth0 2>/dev/null || true
        ip route add default via 192.168.10.1 dev eth0 2>/dev/null || true
        echo "nameserver 192.168.10.1" > /etc/resolv.conf
        echo "nameserver 8.8.8.8" >> /etc/resolv.conf
    fi
'

[Install]
WantedBy=local-fs.target
EOF

chmod 644 "$SERVICE_FILE"

# Enable it
mkdir -p "$WANTS_DIR"
ln -sf "/lib/systemd/system/minimal-network.service" "$WANTS_DIR/minimal-network.service"

echo "✅ Created minimal-network.service"
echo ""
echo "This service:"
echo "  - Waits for eth0"
echo "  - Sets IP: 192.168.10.2/24"
echo "  - Sets gateway: 192.168.10.1"
echo "  - That's it."
echo ""
echo "Boot the Pi. After 30 seconds, it should have IP 192.168.10.2"
echo "Then you can SSH: ssh pi@192.168.10.2"
echo ""



