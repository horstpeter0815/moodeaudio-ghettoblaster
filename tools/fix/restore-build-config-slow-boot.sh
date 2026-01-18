#!/bin/bash
# Restore SD card to build-default configuration
# Keep verbose logging for photos

set -e

BOOTFS="/Volumes/bootfs"
ROOTFS="/Volumes/rootfs"

if [ ! -d "$BOOTFS" ]; then
    echo "❌ SD card boot partition not mounted at $BOOTFS"
    echo "   Please insert SD card and wait for it to mount"
    exit 1
fi

CMDLINE="$BOOTFS/cmdline.txt"

echo "=== RESTORING TO BUILD-DEFAULT CONFIGURATION ==="
echo ""
echo "This will:"
echo "  ✅ Restore fsck.repair=yes (build default)"
echo "  ✅ Keep loglevel=7 (verbose - see all messages for photos)"
echo "  ✅ Remove 'quiet' parameter (show all messages)"
echo "  ✅ Remove our custom boot optimizations"
echo ""

# Backup current
BACKUP="$CMDLINE.backup.before-restore-$(date +%Y%m%d_%H%M%S)"
cp "$CMDLINE" "$BACKUP"
echo "📦 Backup saved: $BACKUP"
echo ""

# Restore to build defaults but keep verbose logging for photos
NEW_CMDLINE="console=tty3 root=PARTUUID=be7bb9f2-02 rootfstype=ext4 fsck.repair=yes rootwait loglevel=7 logo.nologo vt.global_cursor_default=0 video=HDMI-A-1:400x1280M@60,rotate=90"
echo "$NEW_CMDLINE" > "$CMDLINE"
echo "✅ Restored cmdline.txt to build defaults (verbose for photos)"
echo ""

# Remove our custom fixes if rootfs is accessible
if [ -d "$ROOTFS" ]; then
    echo "Removing custom boot optimizations..."
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
echo "✅ Configuration restored!"
echo ""
echo "Boot will:"
echo "  - Show all messages (loglevel=7, no quiet)"
echo "  - Run at original build speed (may be slow - good for photos)"
echo "  - Use build-default settings (fsck.repair=yes)"
echo ""
echo "Perfect for taking photos of boot process! 📸"
