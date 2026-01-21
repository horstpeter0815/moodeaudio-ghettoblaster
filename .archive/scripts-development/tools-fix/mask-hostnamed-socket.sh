#!/bin/bash
# Mask systemd-hostnamed.socket to prevent it from blocking sockets.target

ROOTFS="/Volumes/rootfs"

if [ ! -d "$ROOTFS" ]; then
    echo "❌ SD card not mounted at $ROOTFS"
    exit 1
fi

cd "$ROOTFS/etc/systemd/system" || exit 1

echo "=== Masking systemd-hostnamed.socket ==="
echo ""

# Mask systemd-hostnamed.socket
echo "Masking systemd-hostnamed.socket..."
rm -f systemd-hostnamed.socket
ln -s /dev/null systemd-hostnamed.socket
echo "   ✅ systemd-hostnamed.socket → /dev/null"

echo ""
echo "=== Verification ==="
ls -la systemd-hostnamed.socket 2>/dev/null

echo ""
echo "=== Fix Complete ==="
echo "✅ systemd-hostnamed.socket is now masked"
echo "   This prevents 'Failed to listen on systemd-hostnamed.socket' error"
echo "   and allows sockets.target to complete"
