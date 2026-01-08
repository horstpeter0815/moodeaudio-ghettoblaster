#!/bin/bash
# Install our fixes after flashing moOde image
# Run: sudo ./INSTALL_FIXES_AFTER_FLASH.sh

cd ~/moodeaudio-cursor

ROOTFS="/Volumes/rootfs"
BOOTFS="/Volumes/bootfs"

echo "=== INSTALLING FIXES AFTER MOODE FLASH ==="
echo ""

if [ ! -d "$ROOTFS" ]; then
    echo "❌ SD card not mounted at $ROOTFS"
    exit 1
fi

echo "✅ SD card: $ROOTFS"
echo ""

# 1. Install SSH fix
echo "1. Installing SSH fix..."
if [ -f "moode-source/lib/systemd/system/ssh-guaranteed.service" ]; then
    sudo cp moode-source/lib/systemd/system/ssh-guaranteed.service "$ROOTFS/lib/systemd/system/"
    sudo mkdir -p "$ROOTFS/etc/systemd/system/sysinit.target.wants"
    sudo ln -sf /lib/systemd/system/ssh-guaranteed.service "$ROOTFS/etc/systemd/system/sysinit.target.wants/"
    echo "✅ SSH fix installed"
fi

# 2. Install user fix
echo "2. Installing user fix..."
if [ -f "moode-source/lib/systemd/system/fix-user-id.service" ]; then
    sudo cp moode-source/lib/systemd/system/fix-user-id.service "$ROOTFS/lib/systemd/system/"
    sudo mkdir -p "$ROOTFS/etc/systemd/system/multi-user.target.wants"
    sudo ln -sf /lib/systemd/system/fix-user-id.service "$ROOTFS/etc/systemd/system/multi-user.target.wants/"
    echo "✅ User fix installed"
fi

# 3. Install Ethernet fix
echo "3. Installing Ethernet fix..."
if [ -f "moode-source/lib/systemd/system/02-eth0-configure.service" ]; then
    sudo cp moode-source/lib/systemd/system/02-eth0-configure.service "$ROOTFS/lib/systemd/system/"
    sudo mkdir -p "$ROOTFS/etc/systemd/system/local-fs.target.wants" "$ROOTFS/etc/systemd/system/sysinit.target.wants"
    sudo ln -sf /lib/systemd/system/02-eth0-configure.service "$ROOTFS/etc/systemd/system/local-fs.target.wants/"
    sudo ln -sf /lib/systemd/system/02-eth0-configure.service "$ROOTFS/etc/systemd/system/sysinit.target.wants/"
    echo "✅ Ethernet fix installed (safe mgmt link: 192.168.10.2/24, never default route)"
else
    echo "⚠️  02-eth0-configure.service not found (skipping)"
fi

# 4. Enable SSH flag
echo "4. Enabling SSH flag..."
if [ -d "$BOOTFS" ]; then
    sudo touch "$BOOTFS/ssh" 2>/dev/null || sudo touch "$BOOTFS/firmware/ssh" 2>/dev/null || true
    echo "✅ SSH flag enabled"
fi

# 5. Install iPhone USB tether service (Personal Hotspot)
echo "5. Installing iPhone USB tether service..."
if [ -f "moode-source/lib/systemd/system/iphone-usb-tether.service" ] && [ -f "moode-source/usr/local/bin/iphone-usb-tether.sh" ]; then
    sudo cp moode-source/lib/systemd/system/iphone-usb-tether.service "$ROOTFS/lib/systemd/system/"
    sudo cp moode-source/usr/local/bin/iphone-usb-tether.sh "$ROOTFS/usr/local/bin/"
    sudo chmod +x "$ROOTFS/usr/local/bin/iphone-usb-tether.sh" 2>/dev/null || true
    sudo mkdir -p "$ROOTFS/etc/systemd/system/multi-user.target.wants"
    sudo ln -sf /lib/systemd/system/iphone-usb-tether.service "$ROOTFS/etc/systemd/system/multi-user.target.wants/"
    echo "✅ iPhone USB tether service installed"
else
    echo "⚠️  iphone-usb-tether files not found in repo (skipping)"
fi

# 6. Set moOde Hotspot password default + clean old WiFi profiles
echo "6. Installing Hotspot password + WiFi cleanup (optional)..."
if [ -f "moode-source/lib/systemd/system/hotspot-set-password.service" ] && [ -f "moode-source/usr/local/bin/hotspot-set-password.sh" ]; then
    sudo cp moode-source/lib/systemd/system/hotspot-set-password.service "$ROOTFS/lib/systemd/system/"
    sudo cp moode-source/usr/local/bin/hotspot-set-password.sh "$ROOTFS/usr/local/bin/"
    sudo chmod +x "$ROOTFS/usr/local/bin/hotspot-set-password.sh" 2>/dev/null || true
    sudo mkdir -p "$ROOTFS/etc/systemd/system/multi-user.target.wants"
    sudo ln -sf /lib/systemd/system/hotspot-set-password.service "$ROOTFS/etc/systemd/system/multi-user.target.wants/"
    echo "✅ Hotspot password service installed (default PSK: 08150815)"
else
    echo "⚠️  hotspot-set-password files not found (skipping)"
fi

if [ -f "moode-source/lib/systemd/system/network-cleanup-profiles.service" ] && [ -f "moode-source/usr/local/bin/network-cleanup-profiles.sh" ]; then
    sudo cp moode-source/lib/systemd/system/network-cleanup-profiles.service "$ROOTFS/lib/systemd/system/"
    sudo cp moode-source/usr/local/bin/network-cleanup-profiles.sh "$ROOTFS/usr/local/bin/"
    sudo chmod +x "$ROOTFS/usr/local/bin/network-cleanup-profiles.sh" 2>/dev/null || true
    sudo mkdir -p "$ROOTFS/etc/systemd/system/multi-user.target.wants"
    sudo ln -sf /lib/systemd/system/network-cleanup-profiles.service "$ROOTFS/etc/systemd/system/multi-user.target.wants/"
    echo "✅ WiFi cleanup service installed (removes only: Ghettoblaster / Ghetto LAN)"
else
    echo "⚠️  network-cleanup-profiles files not found (skipping)"
fi

echo ""
echo "✅✅✅ FIXES INSTALLED ✅✅✅"
echo ""
echo "Next: Eject SD card and boot Pi"
echo ""

