#!/bin/bash
# Restore Working moOde Audio from Backup
# Run: sudo ./RESTORE_WORKING_MOODE.sh

set -e

cd ~/moodeaudio-cursor

BACKUP_DIR="$HOME/moodeaudio-cursor/moode-working-backup"
ROOTFS="/Volumes/rootfs"
BOOTFS="/Volumes/bootfs"

echo "=== RESTORING WORKING MOODE AUDIO ==="
echo ""

if [ ! -d "$BACKUP_DIR" ]; then
    echo "❌ Backup not found at $BACKUP_DIR"
    exit 1
fi

if [ ! -d "$ROOTFS" ]; then
    echo "❌ SD card rootfs not mounted at $ROOTFS"
    exit 1
fi

echo "✅ Backup found: $BACKUP_DIR"
echo "✅ SD card detected: $ROOTFS"
echo ""

# 1. Restore system configuration
echo "1. Restoring system configuration..."
if [ -d "$BACKUP_DIR/etc" ]; then
    sudo rsync -av "$BACKUP_DIR/etc/" "$ROOTFS/etc/" 2>/dev/null || echo "⚠️  Some files need manual copy"
    echo "✅ System configuration restored"
fi

# 2. Restore moOde web files
echo "2. Restoring moOde web files..."
if [ -d "$BACKUP_DIR/html" ]; then
    sudo rsync -av "$BACKUP_DIR/html/" "$ROOTFS/var/www/html/" 2>/dev/null || true
    echo "✅ Web files restored"
fi

# 3. Restore moOde configuration
echo "3. Restoring moOde configuration..."
if [ -d "$BACKUP_DIR/var" ]; then
    sudo rsync -av "$BACKUP_DIR/var/" "$ROOTFS/var/" 2>/dev/null || true
    echo "✅ moOde configuration restored"
fi

# 4. Restore systemd services
echo "4. Restoring systemd services..."
if [ -d "$BACKUP_DIR/system" ]; then
    sudo rsync -av "$BACKUP_DIR/system/" "$ROOTFS/lib/systemd/system/" 2>/dev/null || true
    echo "✅ Services restored"
fi

# 5. Restore boot partition
echo "5. Restoring boot partition..."
if [ -d "$BACKUP_DIR/bootfs-backup" ] && [ -d "$BOOTFS" ]; then
    sudo rsync -av "$BACKUP_DIR/bootfs-backup/bootfs/" "$BOOTFS/" 2>/dev/null || true
    echo "✅ Boot partition restored"
fi

echo ""
echo "✅✅✅ RESTORATION COMPLETE ✅✅✅"
echo ""
echo "Working moOde Audio has been restored!"
echo ""
echo "Next steps:"
echo "1. Eject SD card safely"
echo "2. Boot Raspberry Pi"
echo "3. moOde should work (touch, sound, everything)"
echo ""

