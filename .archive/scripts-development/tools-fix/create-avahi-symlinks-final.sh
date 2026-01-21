#!/bin/bash
cd /Volumes/rootfs/etc/systemd/system
rm -f avahi-daemon.socket avahi-daemon.service
ln -s /dev/null avahi-daemon.socket
ln -s /dev/null avahi-daemon.service
echo "✅ avahi-daemon disabled"
