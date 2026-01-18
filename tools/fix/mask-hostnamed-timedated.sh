#!/bin/bash
# Mask systemd-hostnamed.service and systemd-timedated.service

ROOTFS="/Volumes/rootfs"

if [ ! -d "$ROOTFS" ]; then
    echo "❌ SD card not mounted at $ROOTFS"
    exit 1
fi

cd "$ROOTFS/etc/systemd/system" || exit 1

echo "=== Masking Services Blocking After basic.target ==="
echo ""

# Mask systemd-hostnamed.service
echo "1. Masking systemd-hostnamed.service..."
rm -f systemd-hostnamed.service
ln -s /dev/null systemd-hostnamed.service
echo "   ✅ systemd-hostnamed.service → /dev/null"

# Mask systemd-timedated.service  
echo ""
echo "2. Masking systemd-timedated.service..."
rm -f systemd-timedated.service
ln -s /dev/null systemd-timedated.service
echo "   ✅ systemd-timedated.service → /dev/null"

echo ""
echo "=== Verification ==="
ls -la systemd-hostnamed.service systemd-timedated.service 2>/dev/null

echo ""
echo "=== Fix Complete ==="
echo "✅ Both services are now masked and won't block boot"
