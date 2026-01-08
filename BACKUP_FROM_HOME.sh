#!/bin/bash
# Backup Working moOde Audio - From Home Directory
# Run: sudo ./BACKUP_FROM_HOME.sh

cd ~/moodeaudio-cursor

ROOTFS="/Volumes/rootfs"
BOOTFS="/Volumes/bootfs"
BACKUP_DIR="$HOME/moodeaudio-cursor/moode-working-backup"

echo "=== BACKING UP WORKING MOODE AUDIO ==="
echo "Working from: $(pwd)"
echo "Backup to: $BACKUP_DIR"
echo ""

if [ ! -d "$ROOTFS" ]; then
    echo "❌ SD card rootfs not mounted at $ROOTFS"
    exit 1
fi

echo "✅ SD card detected"
echo ""

# Create backup directory
mkdir -p "$BACKUP_DIR"
echo "✅ Backup directory: $BACKUP_DIR"
echo ""

# Backup critical files
echo "1. Backing up system configuration..."
sudo rsync -av --exclude='proc' --exclude='sys' --exclude='dev' --exclude='tmp' --exclude='run' \
    "$ROOTFS/etc" "$BACKUP_DIR/" 2>/dev/null || echo "⚠️  Some files need sudo"

echo "2. Backing up moOde web files..."
sudo rsync -av "$ROOTFS/var/www/html" "$BACKUP_DIR/" 2>/dev/null || echo "⚠️  Some files need sudo"

echo "3. Backing up moOde configuration..."
sudo rsync -av "$ROOTFS/var/local/www" "$BACKUP_DIR/" 2>/dev/null || true

echo "4. Backing up systemd services..."
sudo rsync -av "$ROOTFS/lib/systemd/system" "$BACKUP_DIR/" 2>/dev/null || true
sudo rsync -av "$ROOTFS/etc/systemd/system" "$BACKUP_DIR/" 2>/dev/null || true

echo "5. Backing up boot partition..."
if [ -d "$BOOTFS" ]; then
    sudo rsync -av "$BOOTFS" "$BACKUP_DIR/bootfs-backup" 2>/dev/null || true
fi

# Create backup info
cat > "$BACKUP_DIR/BACKUP_INFO.txt" << EOF
moOde Audio Working Backup
Date: $(date)
Source: SD Card
Rootfs: $ROOTFS
Bootfs: $BOOTFS
Backup Location: $BACKUP_DIR

Status: WORKING - Touch, Sound, Everything works!
Network: May need reconfiguration

To restore:
1. Mount SD card
2. Copy files back from $BACKUP_DIR
3. Reboot Pi
EOF

echo ""
echo "✅✅✅ BACKUP COMPLETE ✅✅✅"
echo ""
ls -lh "$BACKUP_DIR" | head -10

