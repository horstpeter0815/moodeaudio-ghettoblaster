#!/bin/bash
#
# Restore working display configuration
# This restores the landscape 1280x400 display configuration
#

set -e

echo "=== RESTORING WORKING DISPLAY CONFIGURATION ==="
echo ""

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Restore config.txt
echo "1. Restoring config.txt..."
sudo cp "$SCRIPT_DIR/config.txt" /boot/firmware/config.txt
echo "   ✓ config.txt restored"

# Restore cmdline.txt
echo "2. Restoring cmdline.txt..."
sudo cp "$SCRIPT_DIR/cmdline.txt" /boot/firmware/cmdline.txt
echo "   ✓ cmdline.txt restored"

# Restore .xinitrc
echo "3. Restoring .xinitrc..."
sudo cp "$SCRIPT_DIR/.xinitrc" /home/andre/.xinitrc
sudo chown andre:andre /home/andre/.xinitrc
echo "   ✓ .xinitrc restored"

# Set database orientation
echo "4. Setting database orientation to 'portrait'..."
sqlite3 /var/local/www/db/moode-sqlite3.db "UPDATE cfg_system SET value='portrait' WHERE param='hdmi_scn_orient';" 2>/dev/null
echo "   ✓ Database updated"

echo ""
echo "=== RESTORE COMPLETE ==="
echo ""
echo "Configuration restored. Reboot to apply:"
echo "  sudo reboot"
echo ""
echo "After reboot, display should show landscape (1280x400)"
echo ""
