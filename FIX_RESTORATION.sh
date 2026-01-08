#!/bin/bash
# Fix Restoration - Properly restore working moOde
# Run: sudo ./FIX_RESTORATION.sh

cd ~/moodeaudio-cursor

BACKUP_DIR="$HOME/moodeaudio-cursor/moode-working-backup"
ROOTFS="/Volumes/rootfs"
BOOTFS="/Volumes/bootfs"

echo "=== FIXING RESTORATION ==="
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

# Check what's in backup
echo "=== BACKUP CONTENTS ==="
ls -la "$BACKUP_DIR" | head -10
echo ""

# Restore properly
echo "1. Restoring /etc..."
if [ -d "$BACKUP_DIR/etc" ]; then
    sudo rsync -av --delete "$BACKUP_DIR/etc/" "$ROOTFS/etc/"
    echo "✅ /etc restored"
fi

echo "2. Restoring /var/www/html..."
if [ -d "$BACKUP_DIR/html" ]; then
    sudo mkdir -p "$ROOTFS/var/www/html"
    sudo rsync -av --delete "$BACKUP_DIR/html/" "$ROOTFS/var/www/html/"
    echo "✅ /var/www/html restored"
fi

echo "3. Restoring /var/local/www..."
if [ -d "$BACKUP_DIR/var" ]; then
    sudo mkdir -p "$ROOTFS/var/local"
    sudo rsync -av --delete "$BACKUP_DIR/var/" "$ROOTFS/var/"
    echo "✅ /var/local/www restored"
fi

echo "4. Restoring systemd services..."
if [ -d "$BACKUP_DIR/system" ]; then
    sudo rsync -av --delete "$BACKUP_DIR/system/" "$ROOTFS/lib/systemd/system/"
    echo "✅ Services restored"
fi

echo "5. Restoring boot partition..."
if [ -d "$BACKUP_DIR/bootfs-backup/bootfs" ] && [ -d "$BOOTFS" ]; then
    sudo rsync -av --delete "$BACKUP_DIR/bootfs-backup/bootfs/" "$BOOTFS/"
    echo "✅ Boot partition restored"
fi

echo ""
echo "✅✅✅ RESTORATION FIXED ✅✅✅"
echo ""

