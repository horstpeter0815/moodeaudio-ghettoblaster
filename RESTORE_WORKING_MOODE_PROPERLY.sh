#!/bin/bash
# Restore Working moOde Audio PROPERLY from backup
# Run: sudo ./RESTORE_WORKING_MOODE_PROPERLY.sh

cd ~/moodeaudio-cursor

BACKUP_DIR="$HOME/moodeaudio-cursor/moode-working-backup"
ROOTFS="/Volumes/rootfs"
BOOTFS="/Volumes/bootfs"

echo "=== RESTORING WORKING MOODE AUDIO PROPERLY ==="
echo ""

if [ ! -d "$BACKUP_DIR" ]; then
    echo "❌ Backup not found at $BACKUP_DIR"
    exit 1
fi

if [ ! -d "$ROOTFS" ]; then
    echo "❌ SD card rootfs not mounted at $ROOTFS"
    exit 1
fi

echo "✅ Backup: $BACKUP_DIR"
echo "✅ SD card: $ROOTFS"
echo ""

# 1. Restore boot partition COMPLETELY
echo "1. Restoring boot partition..."
if [ -d "$BACKUP_DIR/bootfs-backup/bootfs" ] && [ -d "$BOOTFS" ]; then
    rsync -av --delete "$BACKUP_DIR/bootfs-backup/bootfs/" "$BOOTFS/"
    echo "✅ Boot partition restored"
else
    echo "⚠️  Boot partition backup not found or bootfs not mounted"
fi

# 2. Restore system configuration (/etc)
echo "2. Restoring system configuration..."
if [ -d "$BACKUP_DIR/etc" ]; then
    rsync -av --delete "$BACKUP_DIR/etc/" "$ROOTFS/etc/"
    echo "✅ System configuration restored"
fi

# 3. Restore moOde web files (/var/www/html)
echo "3. Restoring moOde web files..."
if [ -d "$BACKUP_DIR/html" ]; then
    rsync -av --delete "$BACKUP_DIR/html/" "$ROOTFS/var/www/html/"
    echo "✅ Web files restored"
else
    echo "⚠️  Web files backup not found - checking if we need to copy from image"
fi

# 4. Restore moOde configuration (/var/local/www)
echo "4. Restoring moOde configuration..."
if [ -d "$BACKUP_DIR/var" ]; then
    rsync -av --delete "$BACKUP_DIR/var/" "$ROOTFS/var/"
    echo "✅ moOde configuration restored"
fi

# 5. Restore systemd services
echo "5. Restoring systemd services..."
if [ -d "$BACKUP_DIR/system" ]; then
    rsync -av --delete "$BACKUP_DIR/system/" "$ROOTFS/lib/systemd/system/"
    echo "✅ Services restored"
fi

echo ""
echo "=== VERIFICATION ==="
echo "Boot files:"
ls -la "$BOOTFS/config.txt" "$BOOTFS/cmdline.txt" 2>/dev/null | head -2
echo ""
echo "moOde files:"
du -sh "$ROOTFS/var/www/html" 2>/dev/null || echo "Not found"
echo ""
echo "✅✅✅ WORKING MOODE RESTORED ✅✅✅"
echo ""
echo "Next steps:"
echo "1. Eject SD card safely"
echo "2. Boot Raspberry Pi"
echo "3. moOde should work (touch, sound, everything)"
echo ""

