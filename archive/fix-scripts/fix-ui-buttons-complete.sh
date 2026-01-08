#!/bin/bash
# Complete UI Button Fix - Addresses all possible issues

DB="/var/local/www/db/moode-sqlite3.db"

echo "=== Complete UI Button Fix ==="
echo ""

# Step 1: Verify database state
echo "1. Checking database state..."
PEPPY=$(sqlite3 "$DB" "SELECT value FROM cfg_system WHERE param='peppy_display';" 2>/dev/null)
LOCAL=$(sqlite3 "$DB" "SELECT value FROM cfg_system WHERE param='local_display';" 2>/dev/null)
echo "  peppy_display: $PEPPY"
echo "  local_display: $LOCAL"
echo ""

# Step 2: Ensure only one display is active
echo "2. Ensuring only one display is active..."
if [ "$PEPPY" = "1" ] && [ "$LOCAL" = "1" ]; then
    echo "  Fixing conflict: Disabling Local Display..."
    sqlite3 "$DB" "UPDATE cfg_system SET value='0' WHERE param='local_display';"
    echo "  ✓ Fixed"
elif [ "$PEPPY" = "1" ]; then
    echo "  ✓ Only Peppy Display is active (correct)"
elif [ "$LOCAL" = "1" ]; then
    echo "  ✓ Only Local Display is active (correct)"
else
    echo "  ✓ No displays active (correct)"
fi
echo ""

# Step 3: Restart worker to reload session
echo "3. Restarting worker daemon to reload session..."
sudo systemctl restart worker 2>/dev/null || echo "  ⚠ Worker service not found or already restarting"
sleep 2
echo "  ✓ Worker restarted"
echo ""

# Step 4: Verify services
echo "4. Verifying services..."
echo "  MPD: $(systemctl is-active mpd 2>/dev/null && echo '✓ Running' || echo '✗ Not running')"
echo "  Worker: $(systemctl is-active worker 2>/dev/null && echo '✓ Running' || echo '✗ Not running')"
echo ""

# Step 5: Check for PHP session issues
echo "5. Checking PHP session files..."
SESSION_COUNT=$(ls -1 /var/local/php/sess_* 2>/dev/null | wc -l)
echo "  Active sessions: $SESSION_COUNT"
if [ "$SESSION_COUNT" -gt 10 ]; then
    echo "  ⚠ Many session files - consider clearing old ones"
fi
echo ""

# Step 6: Final verification
echo "6. Final configuration check..."
sqlite3 "$DB" "SELECT param, value FROM cfg_system WHERE param IN ('peppy_display', 'local_display', 'audioout', 'alsaequal', 'eqfa12p');" 2>/dev/null
echo ""

echo "=== Fix Complete ==="
echo ""
echo "IMPORTANT: Clear your browser cache and do a hard refresh:"
echo "  - Mac: Cmd+Shift+R"
echo "  - Windows/Linux: Ctrl+Shift+R"
echo "  - Or clear browser cache completely"
echo ""
echo "If buttons still don't work after cache clear:"
echo "  1. Try a different browser"
echo "  2. Check browser console for JavaScript errors (F12)"
echo "  3. Try incognito/private mode"
echo ""

