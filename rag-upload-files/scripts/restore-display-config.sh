#!/bin/bash
# Restore Display Configuration After Reboot
# Ensures display settings are preserved after reboot

echo "=== RESTORE DISPLAY CONFIGURATION ==="

# Wait for moOde database to be ready
for i in {1..10}; do
    if [ -f /var/local/www/db/moode-sqlite3.db ]; then
        break
    fi
    sleep 1
done

# Restore moOde Display Settings if database exists
if [ -f /var/local/www/db/moode-sqlite3.db ]; then
    echo "✅ moOde database found"
    
    # Get current display orientation from database
    CURRENT_ORIENT=$(moodeutl -q "SELECT value FROM cfg_system WHERE param='hdmi_scn_orient'" 2>/dev/null || echo "")
    
    if [ -z "$CURRENT_ORIENT" ]; then
        echo "⚠️  No display orientation in database - setting to landscape"
        # Set to landscape if not set
        moodeutl -q "UPDATE cfg_system SET value='landscape' WHERE param='hdmi_scn_orient'" 2>/dev/null || true
    else
        echo "✅ Display orientation from database: $CURRENT_ORIENT"
    fi
    
    # Ensure local_display is enabled
    LOCAL_DISPLAY=$(moodeutl -q "SELECT value FROM cfg_system WHERE param='local_display'" 2>/dev/null || echo "")
    if [ "$LOCAL_DISPLAY" != "1" ]; then
        echo "⚠️  Local display not enabled - enabling..."
        moodeutl -q "UPDATE cfg_system SET value='1' WHERE param='local_display'" 2>/dev/null || true
    fi
    
    # Ensure local_display_url is set
    LOCAL_URL=$(moodeutl -q "SELECT value FROM cfg_system WHERE param='local_display_url'" 2>/dev/null || echo "")
    if [ -z "$LOCAL_URL" ] || [ "$LOCAL_URL" != "http://localhost/" ]; then
        echo "⚠️  Local display URL not set - setting to http://localhost/"
        moodeutl -q "UPDATE cfg_system SET value='http://localhost/' WHERE param='local_display_url'" 2>/dev/null || true
    fi
    
    echo "✅ moOde display settings restored"
else
    echo "⚠️  moOde database not found - skipping database restore"
fi

# Restore config.txt display settings if backup exists
if [ -f /boot/firmware/config.txt.working-backup ]; then
    echo "✅ config.txt backup found"
    
    # Check if config.txt has moOde headers (prevents overwrite)
    if ! grep -q "# This file is managed by moOde" /boot/firmware/config.txt; then
        echo "⚠️  config.txt missing moOde headers - restoring from backup"
        cp /boot/firmware/config.txt.working-backup /boot/firmware/config.txt
    else
        echo "✅ config.txt has moOde headers - safe from overwrite"
    fi
else
    echo "⚠️  config.txt backup not found - creating one now"
    cp /boot/firmware/config.txt /boot/firmware/config.txt.working-backup 2>/dev/null || true
fi

# Restore xrandr rotation if X11 is running
if [ -n "$DISPLAY" ] || [ -f /tmp/.X11-unix/X0 ]; then
    echo "✅ X11 detected - restoring display rotation"
    
    # Get orientation from moOde database
    ORIENT=$(moodeutl -q "SELECT value FROM cfg_system WHERE param='hdmi_scn_orient'" 2>/dev/null || echo "landscape")
    
    # Find HDMI output
    HDMI_OUTPUT=$(xrandr --query 2>/dev/null | grep -E "HDMI.*connected" | awk '{print $1}' | head -1)
    
    if [ -n "$HDMI_OUTPUT" ]; then
        if [ "$ORIENT" = "portrait" ]; then
            xrandr --output "$HDMI_OUTPUT" --rotate left 2>/dev/null || true
            echo "✅ Display rotated to portrait (left)"
        else
            xrandr --output "$HDMI_OUTPUT" --rotate normal 2>/dev/null || true
            echo "✅ Display set to landscape (normal)"
        fi
    fi
else
    echo "⚠️  X11 not running yet - rotation will be set by localdisplay.service"
fi

# Restart localdisplay service if it exists
if systemctl is-enabled localdisplay.service >/dev/null 2>&1; then
    echo "✅ Restarting localdisplay.service to apply display settings"
    systemctl restart localdisplay.service 2>/dev/null || true
fi

echo "=== DISPLAY CONFIGURATION RESTORE COMPLETE ==="

