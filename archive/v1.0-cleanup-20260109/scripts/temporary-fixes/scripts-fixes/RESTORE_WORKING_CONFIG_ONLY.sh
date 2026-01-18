#!/bin/bash
# Restore ONLY working configuration from backup (keep moOde files)
# Run: sudo ./RESTORE_WORKING_CONFIG_ONLY.sh

cd ~/moodeaudio-cursor

BACKUP_DIR="$HOME/moodeaudio-cursor/moode-working-backup"
ROOTFS="/Volumes/rootfs"
BOOTFS="/Volumes/bootfs"

echo "=== RESTORING WORKING CONFIGURATION ==="
echo ""
echo "This restores WORKING config from backup"
echo "Keeps moOde files already on SD card"
echo ""

if [ ! -d "$BACKUP_DIR" ]; then
    echo "❌ Backup not found"
    exit 1
fi

if [ ! -d "$ROOTFS" ]; then
    echo "❌ SD card not mounted"
    exit 1
fi

echo "✅ Backup: $BACKUP_DIR"
echo "✅ SD card: $ROOTFS"
echo ""

# 1. Restore boot partition (WORKING config.txt, cmdline.txt)
echo "1. Restoring boot partition (working config)..."
if [ -d "$BACKUP_DIR/bootfs-backup/bootfs" ] && [ -d "$BOOTFS" ]; then
    rsync -av "$BACKUP_DIR/bootfs-backup/bootfs/" "$BOOTFS/"
    echo "✅ Boot partition restored"
fi

# 2. Restore systemd services (WORKING services)
echo "2. Restoring systemd services (working services)..."
if [ -d "$BACKUP_DIR/system" ]; then
    rsync -av "$BACKUP_DIR/system/" "$ROOTFS/lib/systemd/system/"
    echo "✅ Services restored"
fi

# 3. Restore system config (/etc) if exists
echo "3. Restoring system configuration..."
if [ -d "$BACKUP_DIR/etc" ]; then
    rsync -av "$BACKUP_DIR/etc/" "$ROOTFS/etc/"
    echo "✅ System config restored"
fi

# 4. Restore moOde database/config if exists
echo "4. Restoring moOde configuration..."
if [ -d "$BACKUP_DIR/var" ]; then
    rsync -av "$BACKUP_DIR/var/" "$ROOTFS/var/"
    echo "✅ moOde config restored"
fi

# NOTE: We KEEP moOde web files already on SD card (from image)

echo ""
echo "=== VERIFICATION ==="
echo "Boot files:"
ls -la "$BOOTFS/config.txt" "$BOOTFS/cmdline.txt" 2>/dev/null
echo ""
echo "moOde files (kept from image):"
du -sh "$ROOTFS/var/www/html" 2>/dev/null
echo ""
echo "✅✅✅ WORKING CONFIG RESTORED ✅✅✅"
echo ""
echo "Restored:"
echo "  ✅ Boot partition (working config.txt, cmdline.txt)"
echo "  ✅ Systemd services (working services)"
echo "  ✅ System config"
echo ""
echo "Kept:"
echo "  ✅ moOde web files (from image)"
echo ""
echo "Next: Eject SD card and boot Pi"
echo ""

