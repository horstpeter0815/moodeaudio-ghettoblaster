#!/bin/bash
# Deploy wizard files to SD card - RUN WITH SUDO

echo "=== Deploying Wizard Files ==="

# Create directories
sudo mkdir -p /Volumes/rootfs/var/www/html/test-wizard
sudo mkdir -p /Volumes/rootfs/var/www/html/command

# Copy wizard files
sudo cp test-wizard/wizard-functions.js /Volumes/rootfs/var/www/html/test-wizard/wizard-functions.js
sudo chmod 644 /Volumes/rootfs/var/www/html/test-wizard/wizard-functions.js

sudo cp moode-source/www/command/room-correction-wizard.php /Volumes/rootfs/var/www/html/command/room-correction-wizard.php
sudo chmod 644 /Volumes/rootfs/var/www/html/command/room-correction-wizard.php

echo "✅ Deployment complete!"
echo ""
ls -la /Volumes/rootfs/var/www/html/test-wizard/wizard-functions.js
ls -la /Volumes/rootfs/var/www/html/command/room-correction-wizard.php

