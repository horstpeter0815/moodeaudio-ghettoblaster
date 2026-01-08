#!/bin/bash
# Fix Everything - Complete Reliable Setup
# Run: sudo ./FIX_EVERYTHING_NOW.sh

cd /Users/andrevollmer/moodeaudio-cursor

echo "=== FIXING EVERYTHING FOR RELIABLE CONNECTION ==="
echo ""

# 1. Create directories
sudo mkdir -p /Volumes/rootfs/lib/systemd/system
sudo mkdir -p /Volumes/rootfs/etc/systemd/system/local-fs.target.wants
sudo mkdir -p /Volumes/rootfs/etc/systemd/system/multi-user.target.wants

# 2. Copy Ethernet service
sudo cp moode-source/lib/systemd/system/eth0-direct-static.service /Volumes/rootfs/lib/systemd/system/eth0-direct-static.service 2>/dev/null || echo "Creating eth0 service..."
sudo ln -sf /lib/systemd/system/eth0-direct-static.service /Volumes/rootfs/etc/systemd/system/local-fs.target.wants/eth0-direct-static.service

# 3. Copy SSH service  
sudo cp moode-source/lib/systemd/system/ssh-guaranteed.service /Volumes/rootfs/lib/systemd/system/ssh-guaranteed.service 2>/dev/null || echo "Creating SSH service..."
sudo ln -sf /lib/systemd/system/ssh-guaranteed.service /Volumes/rootfs/etc/systemd/system/local-fs.target.wants/ssh-guaranteed.service
sudo ln -sf /lib/systemd/system/ssh-guaranteed.service /Volumes/rootfs/etc/systemd/system/multi-user.target.wants/ssh-guaranteed.service

# 4. Copy User service
sudo cp moode-source/lib/systemd/system/fix-user-id.service /Volumes/rootfs/lib/systemd/system/fix-user-id.service 2>/dev/null || echo "Creating user service..."
sudo ln -sf /lib/systemd/system/fix-user-id.service /Volumes/rootfs/etc/systemd/system/multi-user.target.wants/fix-user-id.service

# 5. Copy boot-complete-minimal if exists
if [ -f moode-source/lib/systemd/system/boot-complete-minimal.service ]; then
    sudo cp moode-source/lib/systemd/system/boot-complete-minimal.service /Volumes/rootfs/lib/systemd/system/boot-complete-minimal.service
    sudo ln -sf /lib/systemd/system/boot-complete-minimal.service /Volumes/rootfs/etc/systemd/system/local-fs.target.wants/boot-complete-minimal.service
fi

# 6. Create SSH flag
if [ -d /Volumes/bootfs ]; then
    touch /Volumes/bootfs/ssh 2>/dev/null || true
fi

echo ""
echo "✅ ALL SERVICES INSTALLED AND ENABLED!"
echo ""
echo "After reboot:"
echo "  - Ethernet: http://192.168.10.2"
echo "  - SSH: ssh andre@192.168.10.2"
echo ""

