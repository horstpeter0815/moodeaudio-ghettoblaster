#!/bin/bash
# Auto-Deployment Script
# This script will be executed automatically to deploy files

DEPLOY_DIR="/boot/moode_deploy"
WEB_ROOT="/var/www/html"

# Wait for system to be ready
sleep 10

# Copy deploy-now.php to web root so it can be accessed via browser
if [ -f "$DEPLOY_DIR/deploy-now.php" ]; then
    cp "$DEPLOY_DIR/deploy-now.php" "$WEB_ROOT/deploy-now.php"
    chmod 644 "$WEB_ROOT/deploy-now.php"
    chown www-data:www-data "$WEB_ROOT/deploy-now.php"
fi

# Auto-deploy files (optional - comment out if you want manual control)
# Uncomment the lines below to auto-deploy on boot:

# Delete index.html if exists
# rm -f "$WEB_ROOT/index.html"

# Copy test-wizard files
# mkdir -p "$WEB_ROOT/test-wizard"
# cp -r "$DEPLOY_DIR/test-wizard"/* "$WEB_ROOT/test-wizard/"
# chown -R www-data:www-data "$WEB_ROOT/test-wizard"
# chmod -R 644 "$WEB_ROOT/test-wizard"/*

# Copy room-correction-wizard.php
# mkdir -p "$WEB_ROOT/command"
# cp "$DEPLOY_DIR/command/room-correction-wizard.php" "$WEB_ROOT/command/"
# chown www-data:www-data "$WEB_ROOT/command/room-correction-wizard.php"
# chmod 644 "$WEB_ROOT/command/room-correction-wizard.php"

