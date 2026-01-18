#!/bin/bash
# Backup v1.0 Working Configuration from Pi
echo "=== BACKING UP V1.0 WORKING CONFIG FROM PI ==="

BACKUP_DIR="./v1.0-working-config"
mkdir -p "$BACKUP_DIR"

echo "1. Database settings..."
sshpass -p '0815' ssh -o StrictHostKeyChecking=no andre@192.168.2.3 \
  "sudo sqlite3 /var/local/www/db/moode-sqlite3.db .dump" > "$BACKUP_DIR/moode-sqlite3.sql"

echo "2. Boot configuration..."
sshpass -p '0815' ssh -o StrictHostKeyChecking=no andre@192.168.2.3 \
  "cat /boot/firmware/cmdline.txt" > "$BACKUP_DIR/cmdline.txt"

sshpass -p '0815' ssh -o StrictHostKeyChecking=no andre@192.168.2.3 \
  "cat /boot/firmware/config.txt" > "$BACKUP_DIR/config.txt"

echo "3. Display configuration..."
sshpass -p '0815' ssh -o StrictHostKeyChecking=no andre@192.168.2.3 \
  "cat /home/andre/.xinitrc" > "$BACKUP_DIR/xinitrc"

echo "4. Disabled services list..."
sshpass -p '0815' ssh -o StrictHostKeyChecking=no andre@192.168.2.3 \
  "systemctl list-unit-files | grep -E 'disabled|masked'" > "$BACKUP_DIR/disabled-services.txt"

echo "5. Boot time analysis..."
sshpass -p '0815' ssh -o StrictHostKeyChecking=no andre@192.168.2.3 \
  "systemd-analyze time" > "$BACKUP_DIR/boot-time.txt"

echo ""
echo "✓ Backup complete in $BACKUP_DIR/"
ls -lh "$BACKUP_DIR/"
