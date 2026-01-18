#!/bin/bash
# Remove all systemd overrides that are breaking v1.0 boot
# This script requires your Mac password for sudo

ROOT_MOUNT="/Volumes/rootfs"

if [ ! -d "$ROOT_MOUNT" ]; then
    echo "❌ SD card not mounted at $ROOT_MOUNT"
    exit 1
fi

echo "=== REMOVING SYSTEMD OVERRIDES THAT BREAK BOOT ==="
echo ""
echo "These are from our previous fixes and are preventing v1.0 from booting..."
echo ""

echo "Removing masked services..."
sudo rm -f "$ROOT_MOUNT/etc/systemd/system/systemd-networkd.service"
sudo rm -f "$ROOT_MOUNT/etc/systemd/system/systemd-networkd.socket"
sudo rm -f "$ROOT_MOUNT/etc/systemd/system/systemd-resolved.service"
sudo rm -f "$ROOT_MOUNT/etc/systemd/system/systemd-resolved.socket"
sudo rm -f "$ROOT_MOUNT/etc/systemd/system/systemd-networkd-wait-online.service"
sudo rm -f "$ROOT_MOUNT/etc/systemd/system/networkd-wait-online.service"
echo "✅ Masked services removed"

echo ""
echo "Removing override directories..."
sudo rm -rf "$ROOT_MOUNT/etc/systemd/system/systemd-networkd.service.d"
sudo rm -rf "$ROOT_MOUNT/etc/systemd/system/systemd-resolved.service.d"
sudo rm -rf "$ROOT_MOUNT/etc/systemd/system/systemd-networkd-wait-online.service.d"
sudo rm -rf "$ROOT_MOUNT/etc/systemd/system/networkd-wait-online.service.d"
sudo rm -rf "$ROOT_MOUNT/etc/systemd/system/network-online.target.d"
echo "✅ Override directories removed"

echo ""
echo "=== VERIFICATION ==="
REMAINING=$(find "$ROOT_MOUNT/etc/systemd/system" -name "*systemd-networkd*" -o -name "*systemd-resolved*" -o -name "*networkd-wait-online*" 2>/dev/null | wc -l | tr -d ' ')
if [ "$REMAINING" -eq 0 ]; then
    echo "✅ All systemd overrides removed"
else
    echo "⚠️  Still found $REMAINING files (may be normal system files)"
fi

echo ""
echo "✅ SD card is now clean of our previous fixes"
echo "v1.0 should now boot properly"
