#!/bin/bash
# Backup Working Configuration
# Backup current working configuration from Pi to local backups/ directory
# Part of: WISSENSBASIS/DEVELOPMENT_WORKFLOW.md tooling

set -e

PI_IP="${1:-192.168.2.3}"
USER="${2:-andre}"
WORKSPACE="/Users/andrevollmer/moodeaudio-cursor"
DATE=$(date +%Y-%m-%d-%H%M)
BACKUP_DIR="$WORKSPACE/backups/working-$DATE"

echo "========================================"
echo "Backup Working Configuration"
echo "Target: $USER@$PI_IP"
echo "Backup to: $BACKUP_DIR"
echo "========================================"
echo ""

# Create backup directory
mkdir -p "$BACKUP_DIR"

echo "=== Backing up boot configs ==="
scp "$USER@$PI_IP:/boot/firmware/cmdline.txt" "$BACKUP_DIR/" || echo "Warning: cmdline.txt not found"
scp "$USER@$PI_IP:/boot/firmware/config.txt" "$BACKUP_DIR/" || echo "Warning: config.txt not found"
echo "✓ Boot configs backed up"
echo ""

echo "=== Backing up display configs ==="
scp "$USER@$PI_IP:/home/$USER/.xinitrc" "$BACKUP_DIR/xinitrc" || echo "Warning: .xinitrc not found"
ssh "$USER@$PI_IP" "cat /usr/local/etc/xinitrc.default" > "$BACKUP_DIR/xinitrc.default" 2>/dev/null || echo "Warning: xinitrc.default not found"
echo "✓ Display configs backed up"
echo ""

echo "=== Backing up audio configs ==="
scp "$USER@$PI_IP:/etc/alsa/conf.d/_audioout.conf" "$BACKUP_DIR/" || echo "Warning: _audioout.conf not found"
scp "$USER@$PI_IP:/etc/mpd.conf" "$BACKUP_DIR/" || echo "Warning: mpd.conf not found"
echo "✓ Audio configs backed up"
echo ""

echo "=== Backing up database ==="
ssh "$USER@$PI_IP" "sqlite3 /var/local/www/db/moode-sqlite3.db .dump" > "$BACKUP_DIR/moode-sqlite3.sql" 2>/dev/null || echo "Warning: Database dump failed"
echo "✓ Database backed up"
echo ""

echo "=== Backing up systemd services ==="
mkdir -p "$BACKUP_DIR/systemd"
scp "$USER@$PI_IP:/lib/systemd/system/localdisplay.service" "$BACKUP_DIR/systemd/" || echo "Warning: localdisplay.service not found"
scp "$USER@$PI_IP:/lib/systemd/system/peppymeter.service" "$BACKUP_DIR/systemd/" || echo "Warning: peppymeter.service not found"
echo "✓ Systemd services backed up"
echo ""

echo "=== Creating backup manifest ==="
cat > "$BACKUP_DIR/MANIFEST.md" <<EOF
# Working Configuration Backup
**Date:** $(date)
**Source:** $USER@$PI_IP
**Backup Location:** $BACKUP_DIR

## Files Backed Up
- cmdline.txt - Boot framebuffer config
- config.txt - Boot hardware config
- xinitrc - User X init script
- xinitrc.default - System default X init
- _audioout.conf - ALSA audio output config
- mpd.conf - MPD configuration
- moode-sqlite3.sql - Complete database dump
- systemd/ - System services

## System State
\`\`\`
$(ssh "$USER@$PI_IP" "uname -a")
\`\`\`

## Display Config
\`\`\`
$(ssh "$USER@$PI_IP" "sqlite3 /var/local/www/db/moode-sqlite3.db \"SELECT param, value FROM cfg_system WHERE param LIKE '%display%' OR param LIKE '%hdmi%'\"" 2>/dev/null)
\`\`\`

## Audio Config
\`\`\`
$(ssh "$USER@$PI_IP" "sqlite3 /var/local/www/db/moode-sqlite3.db \"SELECT param, value FROM cfg_system WHERE param IN ('audioout','cardnum','amixname','volknob')\"" 2>/dev/null)
\`\`\`

## To Restore
\`\`\`bash
# Boot configs
sudo cp cmdline.txt /boot/firmware/
sudo cp config.txt /boot/firmware/

# Display config
cp xinitrc ~/.xinitrc

# Audio config
sudo cp _audioout.conf /etc/alsa/conf.d/
sudo cp mpd.conf /etc/

# Systemd services
sudo cp systemd/*.service /lib/systemd/system/
sudo systemctl daemon-reload

# Reboot
sudo reboot
\`\`\`
EOF

echo "✓ Manifest created"
echo ""

echo "========================================"
echo "Backup complete!"
echo "Location: $BACKUP_DIR"
echo ""
echo "Next steps:"
echo "1. Review backup: ls -la $BACKUP_DIR"
echo "2. Commit to GitHub:"
echo "   git add backups/"
echo "   git commit -m \"Working configuration backup $DATE\""
echo "   git tag v1.0-working-$DATE"
echo "   git push --tags"
echo "========================================"
