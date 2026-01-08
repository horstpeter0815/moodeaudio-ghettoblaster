#!/bin/bash
################################################################################
# Quick check of SD card network configuration
################################################################################

echo "Checking SD card network configuration..."
echo ""

if [ -d "/Volumes/rootfs" ]; then
    ROOTFS="/Volumes/rootfs"
elif [ -d "/Volumes/rootfs 1" ]; then
    ROOTFS="/Volumes/rootfs 1"
else
    echo "❌ SD card not found"
    exit 1
fi

echo "✅ SD card found: $ROOTFS"
echo ""

# Check network mode manager
if [ -f "$ROOTFS/usr/local/bin/network-mode-manager.sh" ]; then
    echo "✅ Network mode manager script exists"
else
    echo "❌ Network mode manager script MISSING"
fi

if [ -L "$ROOTFS/etc/systemd/system/multi-user.target.wants/network-mode-manager.service" ]; then
    echo "✅ Network mode manager service is ENABLED"
else
    echo "❌ Network mode manager service is NOT enabled"
fi

# Check for network-mode file
if [ -f "/Volumes/bootfs/network-mode" ]; then
    echo "✅ Network mode file exists: $(cat /Volumes/bootfs/network-mode)"
else
    echo "ℹ️  No network-mode file (will use default: ethernet-static → 192.168.10.2)"
fi

echo ""
echo "When Pi boots, it should:"
echo "  1. Detect eth0 interface"
echo "  2. Use ethernet-static mode (default)"
echo "  3. Configure IP: 192.168.10.2"
echo ""
echo "Make sure:"
echo "  - Ethernet cable is connected Mac ↔ Pi"
echo "  - Mac is sharing internet via Ethernet (if using DHCP mode)"
echo "  - Wait 30-60 seconds after boot for network to configure"
echo ""



