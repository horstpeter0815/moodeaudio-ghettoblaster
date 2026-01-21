#!/bin/bash
# RESTORE v1.0 WORKING CONFIGURATION
# This restores the system to the last known working state from GitHub

set -e

PI_IP="192.168.2.3"
PI_USER="andre"
PI_PASS="0815"

echo "========================================="
echo "RESTORING v1.0 WORKING CONFIGURATION"
echo "========================================="
echo ""
echo "This will:"
echo "1. Restore boot configuration (cmdline.txt, config.txt)"
echo "2. Reset database to working state"
echo "3. Remove all PeppyMeter customizations"
echo "4. Restart services"
echo ""
read -p "Continue? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 1
fi

cd "$(dirname "$0")/.."

echo ""
echo "==> Extracting v1.0 working config from GitHub..."
git show b211a0c:v1.0-working-config/cmdline.txt > /tmp/cmdline.txt.restore
git show b211a0c:v1.0-working-config/config.txt > /tmp/config.txt.restore

echo "✅ Files extracted"
echo ""

echo "==> Copying to Pi..."
sshpass -p "$PI_PASS" scp -o StrictHostKeyChecking=no \
    /tmp/cmdline.txt.restore "$PI_USER@$PI_IP:/tmp/cmdline.txt" || exit 1
sshpass -p "$PI_PASS" scp -o StrictHostKeyChecking=no \
    /tmp/config.txt.restore "$PI_USER@$PI_IP:/tmp/config.txt" || exit 1

echo "✅ Files copied"
echo ""

echo "==> Applying configuration on Pi..."
sshpass -p "$PI_PASS" ssh -o StrictHostKeyChecking=no "$PI_USER@$PI_IP" << 'ENDSSH'
set -e

echo "Backing up current config..."
sudo cp /boot/firmware/cmdline.txt /boot/firmware/cmdline.txt.backup || true
sudo cp /boot/firmware/config.txt /boot/firmware/config.txt.backup || true

echo "Installing working config..."
sudo cp /tmp/cmdline.txt /boot/firmware/cmdline.txt
sudo cp /tmp/config.txt /boot/firmware/config.txt

echo "Resetting database display settings..."
sqlite3 /var/local/www/db/moode-sqlite3.db << 'ENDSQL'
UPDATE cfg_system SET value='1' WHERE param='local_display';
UPDATE cfg_system SET value='0' WHERE param='peppy_display';
UPDATE cfg_system SET value='landscape' WHERE param='hdmi_scn_orient';
ENDSQL

echo "Removing PeppyMeter customizations..."
sudo rm -f /var/www/css/fix-peppymeter-button.css
sudo rm -f /var/www/css/fix-peppymeter-button.css.backup

echo "Restoring original templates if backup exists..."
if [ -f /var/www/templates/indextpl.min.html.backup ]; then
    sudo cp /var/www/templates/indextpl.min.html.backup /var/www/templates/indextpl.min.html
fi

echo "Clearing browser cache..."
/var/www/util/sysutil.sh clearbrcache 2>/dev/null || true

echo "Restarting services..."
sudo systemctl restart localdisplay

echo ""
echo "✅ Configuration restored"
echo ""
echo "REBOOT REQUIRED for boot config changes to take effect!"
echo "Run: sudo reboot"

ENDSSH

echo ""
echo "========================================="
echo "✅ RESTORE COMPLETE"
echo "========================================="
echo ""
echo "Next step: SSH to Pi and run: sudo reboot"
echo ""
