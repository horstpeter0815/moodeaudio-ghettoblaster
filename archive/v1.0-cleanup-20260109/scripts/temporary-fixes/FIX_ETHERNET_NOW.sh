#!/bin/bash
# Fix Ethernet configuration - Run with sudo

echo "=== Fixing Ethernet Configuration ==="

# Create directories
sudo mkdir -p /Volumes/rootfs/lib/systemd/system
sudo mkdir -p /Volumes/rootfs/etc/systemd/system/local-fs.target.wants

# Copy service file
sudo cp moode-source/lib/systemd/system/boot-complete-minimal.service /Volumes/rootfs/lib/systemd/system/boot-complete-minimal.service

# Enable service
sudo ln -sf /lib/systemd/system/boot-complete-minimal.service /Volumes/rootfs/etc/systemd/system/local-fs.target.wants/boot-complete-minimal.service

echo "✅ Ethernet configuration service installed!"
echo ""
echo "This will configure eth0 to 192.168.10.2 on boot"
echo ""
echo "🎯 REBOOT PI - Ethernet will work!"

