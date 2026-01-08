#!/bin/bash
################################################################################
# RESTORE MOODE DEFAULT NETWORK - Work WITH moOde, not against it
# Remove all our custom network configurations and let moOde handle it
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
echo "║  RESTORING MOODE DEFAULT NETWORK                             ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "Removing ALL custom network configurations..."
echo "Let moOde handle network its own way."
echo ""

WANTS_DIR="$ROOTFS/etc/systemd/system/multi-user.target.wants"

# Remove ALL our custom network services
echo "Removing custom network services..."
for service in \
    "early-network.service" \
    "network-mode-manager.service" \
    "network-mode-usb-gadget.service" \
    "network-mode-ethernet-static.service" \
    "network-mode-ethernet-dhcp.service" \
    "network-mode-wifi.service" \
    "00-boot-network-ssh.service" \
    "02-eth0-configure.service" \
    "03-network-configure.service" \
    "04-network-lan.service" \
    "usb-gadget-network.service" \
    "network-watchdog.service"; do
    rm -f "$WANTS_DIR/$service" 2>/dev/null || true
    rm -f "$ROOTFS/lib/systemd/system/$service" 2>/dev/null || true
done

# Remove NetworkManager overrides
rm -rf "$ROOTFS/etc/systemd/system/NetworkManager.service.d" 2>/dev/null || true

# Remove systemd-networkd overrides
rm -rf "$ROOTFS/etc/systemd/system/systemd-networkd.service.d" 2>/dev/null || true

# Remove custom NetworkManager connections (keep only what moOde needs)
# Actually, let's just leave NetworkManager alone - let moOde manage it

# Remove our network mode manager script
rm -f "$ROOTFS/usr/local/bin/network-mode-manager.sh" 2>/dev/null || true

echo "✅ All custom network configurations removed"
echo ""
echo "moOde will now use its default network configuration."
echo ""
echo "Next steps:"
echo "  1. Boot Pi normally"
echo "  2. moOde will configure network via its web interface or default DHCP"
echo "  3. Check network via moOde web UI or: ip addr show"
echo ""
echo "To configure static IP later:"
echo "  - Use moOde web interface (Network config)"
echo "  - Or configure via NetworkManager: nmtui"
echo ""



