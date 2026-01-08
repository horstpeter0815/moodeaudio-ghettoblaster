#!/bin/bash
# ONE command that works - run from project directory

ROOTFS="/Volumes/rootfs"
TEMP="/Users/andrevollmer/moodeaudio-cursor/temp"

if [ ! -d "$ROOTFS" ]; then
    echo "❌ SD card rootfs not mounted at $ROOTFS"
    echo "Mount it first: sudo diskutil mount /dev/diskXsY"
    exit 1
fi

sudo bash << 'SUDO_SCRIPT'
mkdir -p /Volumes/rootfs/lib/systemd/system
mkdir -p /Volumes/rootfs/boot/firmware
mkdir -p /Volumes/rootfs/etc/systemd/system/sysinit.target.wants
mkdir -p /Volumes/rootfs/etc/systemd/system/multi-user.target.wants

cp /Users/andrevollmer/moodeaudio-cursor/temp/ssh-guaranteed.service /Volumes/rootfs/lib/systemd/system/
cp /Users/andrevollmer/moodeaudio-cursor/temp/fix-user-id.service /Volumes/rootfs/lib/systemd/system/
cp /Users/andrevollmer/moodeaudio-cursor/temp/ssh-activate.sh /Volumes/rootfs/boot/firmware/
chmod +x /Volumes/rootfs/boot/firmware/ssh-activate.sh

ln -sf /lib/systemd/system/ssh-guaranteed.service /Volumes/rootfs/etc/systemd/system/sysinit.target.wants/ssh-guaranteed.service
ln -sf /lib/systemd/system/fix-user-id.service /Volumes/rootfs/etc/systemd/system/multi-user.target.wants/fix-user-id.service

echo "✅ Done"
SUDO_SCRIPT
