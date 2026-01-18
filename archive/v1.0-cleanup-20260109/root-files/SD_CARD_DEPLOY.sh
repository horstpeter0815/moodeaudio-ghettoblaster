#!/bin/bash
# Deploy files to SD card for moOde
# Usage: ./SD_CARD_DEPLOY.sh [SD_CARD_PATH]

SD_CARD_PATH="${1:-/Volumes/boot}"
MOODE_WWW="/var/www/html"

echo "=== SD Card Deployment Script ==="
echo ""

# Check if SD card is mounted
if [ ! -d "$SD_CARD_PATH" ]; then
    echo "SD card not found at: $SD_CARD_PATH"
    echo ""
    echo "Available volumes:"
    ls -1 /Volumes/ 2>/dev/null || echo "No volumes found"
    echo ""
    echo "Please specify the SD card path:"
    echo "  ./SD_CARD_DEPLOY.sh /Volumes/boot"
    echo "  OR"
    echo "  ./SD_CARD_DEPLOY.sh /Volumes/BOOT"
    exit 1
fi

echo "SD card found at: $SD_CARD_PATH"
echo ""

# Create deployment directory structure
DEPLOY_DIR="$SD_CARD_PATH/moode_deploy"
mkdir -p "$DEPLOY_DIR"

echo "Copying files to SD card..."
echo ""

# Copy fix script
cp fix-index-redirect.php "$DEPLOY_DIR/"
echo "✓ fix-index-redirect.php copied"

# Copy wizard files
mkdir -p "$DEPLOY_DIR/test-wizard"
cp test-wizard/index-simple.html "$DEPLOY_DIR/test-wizard/" 2>/dev/null && echo "✓ index-simple.html copied" || echo "⚠ index-simple.html not found"
cp test-wizard/wizard-functions.js "$DEPLOY_DIR/test-wizard/" 2>/dev/null && echo "✓ wizard-functions.js copied" || echo "⚠ wizard-functions.js not found"
cp test-wizard/snd-config.html "$DEPLOY_DIR/test-wizard/" 2>/dev/null && echo "✓ snd-config.html copied" || echo "⚠ snd-config.html not found"

# Copy backend file
mkdir -p "$DEPLOY_DIR/command"
cp moode-source/www/command/room-correction-wizard.php "$DEPLOY_DIR/command/" 2>/dev/null && echo "✓ room-correction-wizard.php copied" || echo "⚠ room-correction-wizard.php not found"

# Create deployment instructions
cat > "$DEPLOY_DIR/DEPLOY_INSTRUCTIONS.txt" << 'EOF'
=== MOODE DEPLOYMENT INSTRUCTIONS ===

After booting moOde, SSH into the system and run:

1. Copy fix script:
   sudo cp /boot/moode_deploy/fix-index-redirect.php /var/www/html/
   sudo chown www-data:www-data /var/www/html/fix-index-redirect.php
   sudo chmod 644 /var/www/html/fix-index-redirect.php

2. Copy wizard files:
   sudo cp -r /boot/moode_deploy/test-wizard/* /var/www/html/test-wizard/
   sudo chown -R www-data:www-data /var/www/html/test-wizard/
   sudo chmod -R 644 /var/www/html/test-wizard/*

3. Copy backend file:
   sudo cp /boot/moode_deploy/command/room-correction-wizard.php /var/www/html/command/
   sudo chown www-data:www-data /var/www/html/command/room-correction-wizard.php
   sudo chmod 644 /var/www/html/command/room-correction-wizard.php

4. Fix redirect issue:
   Open in browser: https://10.10.11.39:8443/fix-index-redirect.php
   Click "Delete index.html" button

OR manually:
   sudo rm /var/www/html/index.html

5. Access:
   Player: https://10.10.11.39:8443/
   Wizard: https://10.10.11.39:8443/index-simple.html

=== ALTERNATIVE: Use Web File Manager ===

If moOde Web File Manager is available:
1. Navigate to /boot/moode_deploy/
2. Copy files to /var/www/html/ using the web interface
3. Set correct permissions (www-data:www-data, 644)

EOF

echo ""
echo "✓ Deployment package created at: $DEPLOY_DIR"
echo ""
echo "Files ready on SD card!"
echo ""
echo "After booting moOde:"
echo "  1. SSH into moOde"
echo "  2. Run commands from: $DEPLOY_DIR/DEPLOY_INSTRUCTIONS.txt"
echo "  3. OR use Web File Manager to copy files"
echo ""
echo "To fix redirect immediately:"
echo "  Open: https://10.10.11.39:8443/fix-index-redirect.php"

