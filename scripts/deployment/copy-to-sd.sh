#!/bin/bash
# Simple script to copy files to SD card

echo "=== Copy Files to SD Card ==="
echo ""

# Find SD card (usually /Volumes/boot or /Volumes/BOOT)
SD_CARD=""
for vol in /Volumes/boot /Volumes/BOOT /Volumes/*; do
    if [ -d "$vol" ] && [ -w "$vol" ]; then
        # Check if it looks like a Raspberry Pi boot partition
        if [ -f "$vol/config.txt" ] || [ -f "$vol/cmdline.txt" ]; then
            SD_CARD="$vol"
            break
        fi
    fi
done

if [ -z "$SD_CARD" ]; then
    echo "SD card not found automatically."
    echo ""
    echo "Available volumes:"
    ls -1 /Volumes/ 2>/dev/null
    echo ""
    read -p "Enter SD card path (e.g., /Volumes/boot): " SD_CARD
fi

if [ ! -d "$SD_CARD" ]; then
    echo "Error: SD card path not found: $SD_CARD"
    exit 1
fi

echo "SD card found: $SD_CARD"
echo ""

# Create moode_deploy directory
DEPLOY_DIR="$SD_CARD/moode_deploy"
mkdir -p "$DEPLOY_DIR"

echo "Copying files..."

# Copy fix script
cp fix-index-redirect.php "$DEPLOY_DIR/" && echo "✓ fix-index-redirect.php"

# Copy wizard files
mkdir -p "$DEPLOY_DIR/test-wizard"
[ -f test-wizard/index-simple.html ] && cp test-wizard/index-simple.html "$DEPLOY_DIR/test-wizard/" && echo "✓ index-simple.html"
[ -f test-wizard/wizard-functions.js ] && cp test-wizard/wizard-functions.js "$DEPLOY_DIR/test-wizard/" && echo "✓ wizard-functions.js"
[ -f test-wizard/snd-config.html ] && cp test-wizard/snd-config.html "$DEPLOY_DIR/test-wizard/" && echo "✓ snd-config.html"

# Copy backend
mkdir -p "$DEPLOY_DIR/command"
[ -f moode-source/www/command/room-correction-wizard.php ] && cp moode-source/www/command/room-correction-wizard.php "$DEPLOY_DIR/command/" && echo "✓ room-correction-wizard.php"

# Create instructions
cat > "$DEPLOY_DIR/INSTALL.txt" << 'INSTALL'
=== INSTALLATION ===

After booting moOde, run these commands via SSH:

sudo cp /boot/moode_deploy/fix-index-redirect.php /var/www/html/
sudo chown www-data:www-data /var/www/html/fix-index-redirect.php
sudo chmod 644 /var/www/html/fix-index-redirect.php

sudo cp -r /boot/moode_deploy/test-wizard /var/www/html/
sudo chown -R www-data:www-data /var/www/html/test-wizard
sudo chmod -R 644 /var/www/html/test-wizard/*

sudo cp /boot/moode_deploy/command/room-correction-wizard.php /var/www/html/command/
sudo chown www-data:www-data /var/www/html/command/room-correction-wizard.php
sudo chmod 644 /var/www/html/command/room-correction-wizard.php

# Fix redirect
sudo rm /var/www/html/index.html

# OR use web fix:
# Open: https://10.10.11.39:8443/fix-index-redirect.php

INSTALL

echo ""
echo "✅ Files copied to: $DEPLOY_DIR"
echo ""
echo "Next steps:"
echo "  1. Eject SD card"
echo "  2. Insert into Raspberry Pi"
echo "  3. Boot moOde"
echo "  4. SSH into moOde"
echo "  5. Run commands from: /boot/moode_deploy/INSTALL.txt"
echo ""

