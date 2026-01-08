#!/bin/bash
# Fix mpd2cdspvolume service - ensure it's active when CamillaDSP is configured

DB="/var/local/www/db/moode-sqlite3.db"

echo "=== Fixing mpd2cdspvolume Service ==="
echo ""

CAMILLADSP=$(sqlite3 "$DB" "SELECT value FROM cfg_system WHERE param='camilladsp';" 2>/dev/null)
MIXER_TYPE=$(sqlite3 "$DB" "SELECT value FROM cfg_mpd WHERE param='mixer_type';" 2>/dev/null)
VOL_SYNC=$(sqlite3 "$DB" "SELECT value FROM cfg_system WHERE param='camilladsp_volume_sync';" 2>/dev/null)

echo "Current settings:"
echo "  CamillaDSP config: $CAMILLADSP"
echo "  MPD mixer_type: $MIXER_TYPE"
echo "  Volume sync: $VOL_SYNC"
echo ""

if [ "$CAMILLADSP" != "off" ] && [ "$CAMILLADSP" != "" ] && [ "$MIXER_TYPE" = "null" ]; then
    echo "CamillaDSP is active and mixer_type is 'null' - mpd2cdspvolume should be active"
    echo ""
    
    if systemctl is-active --quiet mpd2cdspvolume; then
        echo "✓ Service is already active"
    else
        echo "Starting mpd2cdspvolume service..."
        sudo systemctl start mpd2cdspvolume
        sleep 1
        
        if systemctl is-active --quiet mpd2cdspvolume; then
            echo "✓ Service started successfully"
        else
            echo "⚠ Service failed to start - checking status:"
            sudo systemctl status mpd2cdspvolume --no-pager -l | head -10
        fi
    fi
    
    # Also ensure volume_sync is set correctly
    if [ "$VOL_SYNC" != "on" ]; then
        echo ""
        echo "Setting camilladsp_volume_sync to 'on'..."
        sqlite3 "$DB" "UPDATE cfg_system SET value='on' WHERE param='camilladsp_volume_sync';"
        echo "✓ Updated"
    fi
else
    echo "⚠ CamillaDSP is not active or mixer_type is not 'null'"
    echo "  Service should be inactive in this case"
fi

echo ""
echo "Final status:"
systemctl is-active mpd2cdspvolume 2>/dev/null && echo "  ✓ mpd2cdspvolume: Active" || echo "  ✗ mpd2cdspvolume: Inactive"
echo ""

