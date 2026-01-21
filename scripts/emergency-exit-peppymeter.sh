#!/bin/bash
################################################################################
# Emergency Exit from PeppyMeter
# Switches back to moOde UI immediately
################################################################################

echo "==================================="
echo "Emergency Exit from PeppyMeter"
echo "==================================="
echo ""

# Update database to disable PeppyMeter
echo "Setting peppy_display=0 in database..."
sqlite3 /var/local/www/db/moode-sqlite3.db "UPDATE cfg_system SET value='0' WHERE param='peppy_display';"

if [ $? -eq 0 ]; then
    echo "✓ Database updated"
else
    echo "✗ Failed to update database"
    exit 1
fi

# Restart localdisplay to show moOde UI
echo ""
echo "Restarting display service..."
sudo systemctl restart localdisplay

if [ $? -eq 0 ]; then
    echo "✓ Display service restarted"
    echo ""
    echo "You should see moOde UI in a few seconds!"
else
    echo "✗ Failed to restart display service"
    exit 1
fi

echo ""
echo "Done! moOde UI should be showing now."
