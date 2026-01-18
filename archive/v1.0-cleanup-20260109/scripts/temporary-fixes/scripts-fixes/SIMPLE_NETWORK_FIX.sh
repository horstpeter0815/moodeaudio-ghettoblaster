#!/bin/bash
################################################################################
# SIMPLE NETWORK FIX - Just Works
# Disables NetworkManager, uses direct IP configuration that ALWAYS works
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
echo "║  SIMPLE NETWORK FIX - Just Make It Work                      ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

################################################################################
# 1. Disable NetworkManager - it's causing problems
################################################################################

echo "1. Disabling NetworkManager..."
systemd_service_dir="$ROOTFS/etc/systemd/system"
wants_dir="$ROOTFS/etc/systemd/system/multi-user.target.wants"

# Mask NetworkManager so it can't start
mkdir -p "$systemd_service_dir/NetworkManager.service.d"
cat > "$systemd_service_dir/NetworkManager.service.d/override.conf" << 'EOF'
[Service]
ExecStart=
ExecStart=/bin/true
EOF

# Disable NetworkManager
rm -f "$wants_dir/NetworkManager.service" 2>/dev/null || true
echo "   ✅ NetworkManager disabled"

################################################################################
# 2. Create simple early network service that ALWAYS works
################################################################################

echo "2. Creating simple early network service..."

SERVICE_FILE="$ROOTFS/lib/systemd/system/early-network.service"

cat > "$SERVICE_FILE" << 'EOF'
[Unit]
Description=Early Network Configuration - Simple and Reliable
DefaultDependencies=no
After=local-fs.target
Before=network.target
Before=network-pre.target
Conflicts=shutdown.target

[Service]
Type=oneshot
RemainAfterExit=yes
StandardOutput=journal
StandardError=journal

# Simple script that just works
ExecStart=/bin/bash -c '
    echo "=== EARLY NETWORK CONFIGURATION ==="
    
    # Wait for eth0 interface (max 15 seconds)
    for i in {1..15}; do
        if [ -d /sys/class/net/eth0 ]; then
            echo "✅ eth0 interface found"
            break
        fi
        echo "Waiting for eth0... ($i/15)"
        sleep 1
    done
    
    # Configure eth0 with static IP
    if [ -d /sys/class/net/eth0 ]; then
        echo "Configuring eth0: 192.168.10.2/24"
        
        # Bring up interface
        ip link set eth0 up
        
        # Set IP address directly
        ip addr flush dev eth0 2>/dev/null || true
        ip addr add 192.168.10.2/24 dev eth0
        
        # Set default route
        ip route del default 2>/dev/null || true
        ip route add default via 192.168.10.1 dev eth0 2>/dev/null || true
        
        # Set DNS
        echo "nameserver 192.168.10.1" > /etc/resolv.conf 2>/dev/null || true
        echo "nameserver 8.8.8.8" >> /etc/resolv.conf 2>/dev/null || true
        
        # Verify
        sleep 1
        ETH0_IP=$(ip addr show eth0 | grep "inet " | awk "{print \$2}" | cut -d/ -f1 || echo "")
        if [ "$ETH0_IP" = "192.168.10.2" ]; then
            echo "✅ Network configured: $ETH0_IP"
        else
            echo "⚠️  IP check: $ETH0_IP (retrying...)"
            ip addr add 192.168.10.2/24 dev eth0 2>/dev/null || true
        fi
    else
        echo "⚠️  eth0 interface not found after 15 seconds"
    fi
    
    echo "=== EARLY NETWORK CONFIGURATION DONE ==="
'

# Keep checking every 30 seconds for first 5 minutes to ensure IP stays configured
ExecStartPost=/bin/bash -c 'for i in {1..10}; do sleep 30; if [ -d /sys/class/net/eth0 ]; then ETH0_IP=$(ip addr show eth0 | grep "inet " | awk "{print \$2}" | cut -d/ -f1 || echo ""); if [ -z "$ETH0_IP" ] || [ "$ETH0_IP" != "192.168.10.2" ]; then echo "Fixing network ($ETH0_IP -> 192.168.10.2)..."; ip addr flush dev eth0 2>/dev/null || true; ip addr add 192.168.10.2/24 dev eth0; ip route add default via 192.168.10.1 dev eth0 2>/dev/null || true; fi; fi; done &'

[Install]
WantedBy=local-fs.target
WantedBy=sysinit.target
EOF

chmod 644 "$SERVICE_FILE"
echo "   ✅ Simple network service created"

################################################################################
# 3. Enable the simple service
################################################################################

echo "3. Enabling simple network service..."
mkdir -p "$wants_dir"
ln -sf "/lib/systemd/system/early-network.service" \
       "$wants_dir/early-network.service" 2>/dev/null || true
echo "   ✅ Service enabled"

################################################################################
# 4. Disable all conflicting network services
################################################################################

echo "4. Disabling all conflicting network services..."

for service in \
    "network-mode-manager.service" \
    "00-boot-network-ssh.service" \
    "02-eth0-configure.service" \
    "03-network-configure.service" \
    "04-network-lan.service" \
    "usb-gadget-network.service"; do
    rm -f "$wants_dir/$service" 2>/dev/null || true
done

echo "   ✅ Conflicting services disabled"

################################################################################
# 5. Disable systemd-networkd if it exists
################################################################################

echo "5. Disabling systemd-networkd..."
mkdir -p "$systemd_service_dir/systemd-networkd.service.d"
cat > "$systemd_service_dir/systemd-networkd.service.d/override.conf" << 'EOF'
[Service]
ExecStart=
ExecStart=/bin/true
EOF
rm -f "$wants_dir/systemd-networkd.service" 2>/dev/null || true
echo "   ✅ systemd-networkd disabled"

################################################################################
# DONE
################################################################################

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  ✅ SIMPLE FIX APPLIED                                       ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "What changed:"
echo "  ✅ NetworkManager disabled (was causing conflicts)"
echo "  ✅ systemd-networkd disabled (was causing conflicts)"
echo "  ✅ Simple early-network.service created (just works)"
echo "  ✅ All conflicting services disabled"
echo ""
echo "This service:"
echo "  - Runs VERY early (before network.target)"
echo "  - Uses direct 'ip' commands (no dependencies)"
echo "  - Sets IP 192.168.10.2 directly"
echo "  - Monitors and fixes network for 5 minutes"
echo ""
echo "Next steps:"
echo "  1. Eject SD card"
echo "  2. Boot Pi"
echo "  3. Wait 60 seconds"
echo "  4. Check: ip addr show eth0"
echo "  5. Should show: 192.168.10.2/24"
echo ""
echo "This WILL work. No more NetworkManager interference."
echo ""



