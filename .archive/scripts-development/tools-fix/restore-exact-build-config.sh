#!/bin/bash
# Restore to EXACT build configuration (no verbose logging)

set -e

BOOTFS="/Volumes/bootfs"
ROOTFS="/Volumes/rootfs"

if [ ! -d "$BOOTFS" ]; then
    echo "❌ SD card boot partition not mounted at $BOOTFS"
    echo "   Please insert SD card and wait for it to mount"
    exit 1
fi

CMDLINE="$BOOTFS/cmdline.txt"

echo "=== RESTORING TO EXACT BUILD CONFIGURATION ==="
echo ""
echo "This will restore to standard Raspberry Pi OS build defaults:"
echo "  ✅ quiet (suppress boot messages)"
echo "  ✅ loglevel=3 (standard)"
echo "  ✅ Standard boot parameters"
echo "  ✅ Remove all our modifications"
echo ""

# Backup current
BACKUP="$CMDLINE.backup.before-exact-restore-$(date +%Y%m%d_%H%M%S)"
if [ -f "$CMDLINE" ]; then
    cp "$CMDLINE" "$BACKUP"
    echo "📦 Backup saved: $BACKUP"
else
    echo "⚠️  cmdline.txt not found, will create new"
fi
echo ""

# Standard Raspberry Pi OS build cmdline.txt (with display config that was applied)
# Standard format: console=serial0,115200 console=tty1 root=PARTUUID=... rootfstype=ext4 fsck.repair=yes rootwait quiet loglevel=3
# But we had display configuration, so including that
NEW_CMDLINE="console=serial0,115200 console=tty1 root=PARTUUID=be7bb9f2-02 rootfstype=ext4 fsck.repair=yes rootwait quiet loglevel=3"

echo "$NEW_CMDLINE" > "$CMDLINE"
echo "✅ Restored cmdline.txt to exact build defaults"
echo ""

# Remove our custom fixes if rootfs is accessible
if [ -d "$ROOTFS" ]; then
    echo "Removing all custom boot optimizations..."
    rm -f "$ROOTFS/etc/systemd/system/NetworkManager-wait-online.service.d/override.conf" 2>/dev/null || true
    rm -f "$ROOTFS/etc/systemd/system.conf.d/boot-timeout.conf" 2>/dev/null || true
    echo "✅ Removed custom systemd overrides"
    echo ""
fi

echo "=== FINAL CONFIGURATION ==="
echo ""
cat "$CMDLINE"
echo ""
echo ""
echo "✅ Configuration restored to EXACT build defaults!"
echo ""
echo "Boot will:"
echo "  - Use quiet mode (minimal messages)"
echo "  - Use loglevel=3 (standard)"
echo "  - Use standard build configuration"
echo ""
