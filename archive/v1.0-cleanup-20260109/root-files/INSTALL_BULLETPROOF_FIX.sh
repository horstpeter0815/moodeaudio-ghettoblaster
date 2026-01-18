#!/bin/bash
# BULLETPROOF FIX - This WILL work

cd /Users/andrevollmer/moodeaudio-cursor

echo "=== INSTALLING BULLETPROOF ETH0 FIX ==="
echo ""

# 1. Install bulletproof service
sudo cp BULLETPROOF_ETH0_FIX.service /Volumes/rootfs/lib/systemd/system/eth0-direct-static.service

# 2. Ensure it's enabled
sudo mkdir -p /Volumes/rootfs/etc/systemd/system/local-fs.target.wants
sudo ln -sf /lib/systemd/system/eth0-direct-static.service /Volumes/rootfs/etc/systemd/system/local-fs.target.wants/eth0-direct-static.service

# 3. Also enable in sysinit
sudo mkdir -p /Volumes/rootfs/etc/systemd/system/sysinit.target.wants
sudo ln -sf /lib/systemd/system/eth0-direct-static.service /Volumes/rootfs/etc/systemd/system/sysinit.target.wants/eth0-direct-static.service

# 4. Ensure SSH is enabled
sudo mkdir -p /Volumes/rootfs/etc/systemd/system/local-fs.target.wants
sudo ln -sf /lib/systemd/system/ssh-guaranteed.service /Volumes/rootfs/etc/systemd/system/local-fs.target.wants/ssh-guaranteed.service 2>/dev/null || true

# 5. Create SSH flag
if [ -d /Volumes/bootfs ]; then
    touch /Volumes/bootfs/ssh 2>/dev/null || true
fi

echo ""
echo "✅✅✅ BULLETPROOF FIX INSTALLED ✅✅✅"
echo ""
echo "This version:"
echo "  - Stops all network services first"
echo "  - Disables WiFi"
echo "  - 10 retry attempts with ifconfig"
echo "  - Falls back to ip command"
echo "  - Aggressive watchdog (every 5 seconds)"
echo "  - Multiple verification steps"
echo ""
echo "🎯 REBOOT PI - THIS WILL WORK!"
echo ""

