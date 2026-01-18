#!/bin/bash
# Manual deployment script - copies files locally, then you can manually transfer
# Usage: ./deploy-manual.sh

echo "[INFO] Creating deployment package..."
echo ""

# Create temp directory
TEMP_DIR="/tmp/moode-wizard-deploy-$$"
mkdir -p "$TEMP_DIR"

# Copy files
echo "[COPY] Copying files to $TEMP_DIR..."
cp test-wizard/index-simple.html "$TEMP_DIR/"
cp test-wizard/wizard-functions.js "$TEMP_DIR/"
cp test-wizard/snd-config.html "$TEMP_DIR/"
cp moode-source/www/command/room-correction-wizard.php "$TEMP_DIR/"

# Create deployment instructions
cat > "$TEMP_DIR/DEPLOY_INSTRUCTIONS.txt" << 'EOF'
MANUAL DEPLOYMENT INSTRUCTIONS
==============================

Option 1: Use USB Stick or Network Share
------------------------------------------
1. Copy all files from this directory to moOde system
2. SSH to moOde: ssh andre@10.10.11.39
3. Run these commands (with correct password):

   sudo mkdir -p /var/www/html/test-wizard
   sudo cp index-simple.html /var/www/html/
   sudo cp wizard-functions.js /var/www/html/test-wizard/
   sudo cp snd-config.html /var/www/html/test-wizard/
   sudo cp room-correction-wizard.php /var/www/html/command/
   sudo chown -R www-data:www-data /var/www/html/index-simple.html /var/www/html/test-wizard /var/www/html/command/room-correction-wizard.php
   sudo chmod 644 /var/www/html/index-simple.html /var/www/html/test-wizard/* /var/www/html/command/room-correction-wizard.php

Option 2: Use SCP manually (one file at a time)
------------------------------------------------
scp index-simple.html andre@10.10.11.39:/tmp/
scp wizard-functions.js andre@10.10.11.39:/tmp/
scp snd-config.html andre@10.10.11.39:/tmp/
scp room-correction-wizard.php andre@10.10.11.39:/tmp/

Then SSH and move files:
ssh andre@10.10.11.39
sudo mv /tmp/index-simple.html /var/www/html/
sudo mkdir -p /var/www/html/test-wizard
sudo mv /tmp/wizard-functions.js /var/www/html/test-wizard/
sudo mv /tmp/snd-config.html /var/www/html/test-wizard/
sudo mv /tmp/room-correction-wizard.php /var/www/html/command/
sudo chown -R www-data:www-data /var/www/html/index-simple.html /var/www/html/test-wizard /var/www/html/command/room-correction-wizard.php
sudo chmod 644 /var/www/html/index-simple.html /var/www/html/test-wizard/* /var/www/html/command/room-correction-wizard.php

Files in this directory:
- index-simple.html
- wizard-functions.js
- snd-config.html
- room-correction-wizard.php
EOF

echo "[OK] Files copied to: $TEMP_DIR"
echo ""
echo "Files ready for deployment:"
ls -lh "$TEMP_DIR"
echo ""
echo "See DEPLOY_INSTRUCTIONS.txt in that directory for manual deployment steps"
echo ""
echo "Or try to find the correct password for andre@10.10.11.39"

