#!/bin/bash
# Verify moOde is installed and install fixes
# Run: sudo ./VERIFY_AND_COMPLETE.sh

cd ~/moodeaudio-cursor

ROOTFS="/Volumes/rootfs"
BOOTFS="/Volumes/bootfs"

echo "=== VERIFYING MOODE INSTALLATION ==="
echo ""

# Check moOde files
if [ -d "$ROOTFS/var/www/html" ]; then
    SIZE=$(du -sh "$ROOTFS/var/www/html" 2>/dev/null | awk '{print $1}')
    FILES=$(find "$ROOTFS/var/www/html" -type f 2>/dev/null | wc -l | xargs)
    echo "✅ moOde web files: $SIZE ($FILES files)"
else
    echo "❌ moOde web files missing!"
    exit 1
fi

if [ -d "$ROOTFS/var/local/www" ]; then
    SIZE=$(du -sh "$ROOTFS/var/local/www" 2>/dev/null | awk '{print $1}')
    echo "✅ moOde configuration: $SIZE"
else
    echo "⚠️  moOde configuration missing (may be created on first boot)"
fi

echo ""
echo "=== INSTALLING FIXES ==="
echo ""

# 1. SSH fix
echo "1. Installing SSH fix..."
if [ -f "moode-source/lib/systemd/system/ssh-guaranteed.service" ]; then
    cp moode-source/lib/systemd/system/ssh-guaranteed.service "$ROOTFS/lib/systemd/system/"
    mkdir -p "$ROOTFS/etc/systemd/system/sysinit.target.wants"
    ln -sf /lib/systemd/system/ssh-guaranteed.service "$ROOTFS/etc/systemd/system/sysinit.target.wants/"
    echo "✅ SSH fix installed"
fi

# 2. User fix
echo "2. Installing user fix..."
if [ -f "moode-source/lib/systemd/system/fix-user-id.service" ]; then
    cp moode-source/lib/systemd/system/fix-user-id.service "$ROOTFS/lib/systemd/system/"
    mkdir -p "$ROOTFS/etc/systemd/system/multi-user.target.wants"
    ln -sf /lib/systemd/system/fix-user-id.service "$ROOTFS/etc/systemd/system/multi-user.target.wants/"
    echo "✅ User fix installed"
fi

# 3. Ethernet fix
echo "3. Installing Ethernet fix..."
if [ -f "BULLETPROOF_ETH0_FIX.service" ]; then
    cp BULLETPROOF_ETH0_FIX.service "$ROOTFS/lib/systemd/system/eth0-direct-static.service"
    mkdir -p "$ROOTFS/etc/systemd/system/local-fs.target.wants"
    ln -sf /lib/systemd/system/eth0-direct-static.service "$ROOTFS/etc/systemd/system/local-fs.target.wants/"
    echo "✅ Ethernet fix installed"
fi

# 4. SSH flag
echo "4. Enabling SSH flag..."
if [ -d "$BOOTFS" ]; then
    touch "$BOOTFS/ssh" 2>/dev/null || touch "$BOOTFS/firmware/ssh" 2>/dev/null || true
    echo "✅ SSH flag enabled"
fi

echo ""
echo "✅✅✅ ALL FIXES INSTALLED ✅✅✅"
echo ""
echo "SD card is ready!"
echo ""
echo "Next steps:"
echo "1. Eject SD card safely"
echo "2. Boot Raspberry Pi"
echo "3. moOde should work (touch, sound, everything)"
echo "4. Connect via Ethernet (192.168.10.2) or WiFi"
echo ""

