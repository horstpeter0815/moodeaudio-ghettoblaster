#!/bin/bash
# Backup Working moOde Audio - Complete System Backup
# Run: sudo ./BACKUP_WORKING_MOODE.sh

set -e

ROOTFS="/Volumes/rootfs"
BOOTFS="/Volumes/bootfs"
BACKUP_DIR="moode-working-backup"

echo "=== BACKING UP WORKING MOODE AUDIO ==="
echo ""

if [ ! -d "$ROOTFS" ]; then
    echo "❌ SD card rootfs not mounted"
    exit 1
fi

echo "✅ SD card detected"
echo ""

# Create backup directory
mkdir -p "$BACKUP_DIR"
echo "✅ Backup directory: $BACKUP_DIR"
echo ""

# 1. Backup system configuration
echo "1. Backing up system configuration..."
sudo rsync -av --exclude='proc' --exclude='sys' --exclude='dev' --exclude='tmp' --exclude='run' \
    "$ROOTFS/etc" "$BACKUP_DIR/" 2>/dev/null || echo "⚠️  Some files need sudo"

# 2. Backup moOde web files
echo "2. Backing up moOde web files..."
sudo rsync -av "$ROOTFS/var/www/html" "$BACKUP_DIR/" 2>/dev/null || echo "⚠️  Some files need sudo"

# 3. Backup moOde configuration
echo "3. Backing up moOde configuration..."
sudo rsync -av "$ROOTFS/var/local/www/db" "$BACKUP_DIR/" 2>/dev/null || true
sudo rsync -av "$ROOTFS/var/local/www" "$BACKUP_DIR/" 2>/dev/null || true

# 4. Backup systemd services
echo "4. Backing up systemd services..."
sudo rsync -av "$ROOTFS/lib/systemd/system" "$BACKUP_DIR/" 2>/dev/null || true
sudo rsync -av "$ROOTFS/etc/systemd/system" "$BACKUP_DIR/" 2>/dev/null || true

# 5. Backup boot partition
echo "5. Backing up boot partition..."
if [ -d "$BOOTFS" ]; then
    sudo rsync -av "$BOOTFS" "$BACKUP_DIR/bootfs-backup" 2>/dev/null || true
fi

# 6. Create backup manifest
echo "6. Creating backup manifest..."
cat > "$BACKUP_DIR/BACKUP_INFO.txt" << EOF
moOde Audio Working Backup
Date: $(date)
Source: SD Card
Rootfs: $ROOTFS
Bootfs: $BOOTFS

This backup contains:
- System configuration (/etc)
- moOde web files (/var/www/html)
- moOde database/config (/var/local/www)
- systemd services
- Boot partition

Status: WORKING - Touch, Sound, Everything works!
Network: May need reconfiguration

To restore:
1. Mount SD card
2. Copy files back to SD card
3. Reboot Pi
EOF

echo ""
echo "✅✅✅ BACKUP COMPLETE ✅✅✅"
echo ""
echo "Backup location: $BACKUP_DIR"
echo ""
ls -lh "$BACKUP_DIR" | head -10

