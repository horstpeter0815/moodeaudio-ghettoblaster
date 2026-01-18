#!/bin/bash
################################################################################
#
# FIX BLACK SCREEN IMMEDIATELY
#
# Run this script to fix the black screen issue
# Usage: ./fix-black-screen-now.sh [moode-hostname-or-ip]
#
################################################################################

set -e

MOODE_HOST="${1:-moode}"

echo "🔧 FIXING BLACK SCREEN ON $MOODE_HOST"
echo ""

# 1. Check service status
echo "1. Checking service status..."
ssh "$MOODE_HOST" "systemctl status localdisplay.service --no-pager -l | head -20" || echo "⚠️  Could not check service"
echo ""

# 2. Check if Chromium is running
echo "2. Checking Chromium processes..."
ssh "$MOODE_HOST" "ps aux | grep -i chromium | grep -v grep || echo 'No Chromium processes found'" || echo "⚠️  Could not check Chromium"
echo ""

# 3. Check display URL
echo "3. Checking display URL..."
DISPLAY_URL=$(ssh "$MOODE_HOST" 'moodeutl -q "SELECT value FROM cfg_system WHERE param=\"local_display_url\"" 2>/dev/null || echo "http://localhost/"')
echo "   Display URL: $DISPLAY_URL"
echo ""

# 4. Ensure .xinitrc is correct
echo "4. Fixing .xinitrc..."
ssh "$MOODE_HOST" 'sudo bash -c "cat > /home/andre/.xinitrc << \"EOFSCRIPT\"
#!/bin/sh
xset s 600
xset -dpms
export DISPLAY=:0

# Wait for X server
sleep 3

# Get display URL
DISPLAY_URL=\$(moodeutl -q \"SELECT value FROM cfg_system WHERE param=\\\"local_display_url\\\"\" 2>/dev/null || echo \"http://localhost/\")

# Start Chromium
chromium-browser --kiosk --no-sandbox --disable-gpu --window-size=\"1280,400\" --app=\"\$DISPLAY_URL\" &
wait
EOFSCRIPT
chmod +x /home/andre/.xinitrc && chown andre:andre /home/andre/.xinitrc"'
echo "   ✅ .xinitrc updated"
echo ""

# 5. Run fix-display-black.sh
echo "5. Running fix-display-black.sh..."
ssh "$MOODE_HOST" "sudo /usr/local/bin/fix-display-black.sh" || echo "⚠️  fix-display-black.sh completed with warnings"
echo ""

# 6. Restart service
echo "6. Restarting localdisplay.service..."
ssh "$MOODE_HOST" "sudo systemctl restart localdisplay.service"
echo "   ✅ Service restarted"
echo ""

# 7. Wait and check status
echo "7. Waiting for Chromium to start..."
sleep 8

echo ""
echo "8. Final status check..."
ssh "$MOODE_HOST" "ps aux | grep -i chromium | grep -v grep || echo '⚠️  Chromium not running yet'" || echo "⚠️  Could not check Chromium"
echo ""

ssh "$MOODE_HOST" "systemctl status localdisplay.service --no-pager -l | head -25" || echo "⚠️  Could not check service status"
echo ""

echo "✅ Fix complete!"
echo ""
echo "📋 Next steps:"
echo "   - Check the display - it should show Chromium"
echo "   - If still black, check logs: ssh $MOODE_HOST 'sudo journalctl -u localdisplay.service -n 50'"
echo "   - If Chromium not running, try: ssh $MOODE_HOST 'sudo /usr/local/bin/force-restart-chromium.sh'"

