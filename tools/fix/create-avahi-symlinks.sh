#!/bin/bash
# Create symlinks to disable avahi-daemon

cd /Volumes/rootfs/etc/systemd/system
rm -f avahi-daemon.socket avahi-daemon.service
ln -sf /dev/null avahi-daemon.socket
ln -sf /dev/null avahi-daemon.service
echo "✅ Created symlinks to disable avahi-daemon"
