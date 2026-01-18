#!/bin/bash
# Final step: Create symlinks to disable avahi-daemon

ROOTFS="/Volumes/rootfs"

cd "$ROOTFS/etc/systemd/system"
rm -rf avahi-daemon.socket.d
rm -f avahi-daemon.socket avahi-daemon.service
ln -sf /dev/null avahi-daemon.socket
ln -sf /dev/null avahi-daemon.service

echo "✅ avahi-daemon disabled"
