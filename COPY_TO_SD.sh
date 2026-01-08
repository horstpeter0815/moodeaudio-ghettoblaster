#!/bin/bash
# Copy files to SD card with sudo

sudo mkdir -p /Volumes/rootfs/lib/systemd/system
sudo cp temp/ssh-guaranteed.service /Volumes/rootfs/lib/systemd/system/
sudo cp temp/fix-user-id.service /Volumes/rootfs/lib/systemd/system/

sudo mkdir -p /Volumes/rootfs/boot/firmware
sudo cp temp/ssh-activate.sh /Volumes/rootfs/boot/firmware/
sudo chmod +x /Volumes/rootfs/boot/firmware/ssh-activate.sh

sudo mkdir -p /Volumes/rootfs/etc/systemd/system/sysinit.target.wants
sudo ln -sf /lib/systemd/system/ssh-guaranteed.service /Volumes/rootfs/etc/systemd/system/sysinit.target.wants/ssh-guaranteed.service

sudo mkdir -p /Volumes/rootfs/etc/systemd/system/multi-user.target.wants
sudo ln -sf /lib/systemd/system/fix-user-id.service /Volumes/rootfs/etc/systemd/system/multi-user.target.wants/fix-user-id.service

echo "✅ All files copied and services enabled!"
