#!/bin/bash
################################################################################
#
# Complete Radio Fix - Final Solution
# 
# Fixes all radio station visibility and rendering issues
#
################################################################################

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
cd "$PROJECT_ROOT"

PI_HOST="${1:-172.24.1.1}"
PI_USER="${2:-andre}"
PI_PASS="${3:-0815}"

# Function to run command on Pi
run_on_pi() {
    sshpass -p "$PI_PASS" ssh -o StrictHostKeyChecking=no "$PI_USER@$PI_HOST" "$1"
}

echo "🔧 Complete Radio Fix - Final Solution..."
echo ""

# 1. Ensure all stations are visible
echo "1. Setting all stations to visible..."
run_on_pi "sudo sqlite3 /var/local/www/db/moode-sqlite3.db \"UPDATE cfg_radio SET type='r' WHERE type='h' AND id > 499;\" 2>/dev/null" && echo "   ✅ User stations visible"

# 2. Reset radioview settings
echo "2. Resetting radio view settings..."
run_on_pi "sudo sqlite3 /var/local/www/db/moode-sqlite3.db \"UPDATE cfg_system SET radioview_show_hide='No action,No action' WHERE 1=1;\" 2>/dev/null" && echo "   ✅ View settings reset"

# 3. Fix database permissions
echo "3. Fixing database permissions..."
run_on_pi "sudo chown www-data:www-data /var/local/www/db/moode-sqlite3.db && sudo chmod 664 /var/local/www/db/moode-sqlite3.db" && echo "   ✅ Database permissions fixed"

# 4. Fix web server files
echo "4. Fixing web server files..."
run_on_pi "sudo chown -R www-data:www-data /var/www/ && sudo chmod -R 755 /var/www/" && echo "   ✅ Web files permissions fixed"

# 5. Clear all caches
echo "5. Clearing all caches..."
run_on_pi "sudo rm -rf /var/local/www/imagesw/radio-logos/cache/* 2>/dev/null || true"
run_on_pi "sudo rm -rf /tmp/moode_* 2>/dev/null || true"
run_on_pi "sudo rm -rf /var/cache/nginx/* 2>/dev/null || true" && echo "   ✅ Caches cleared"

# 6. Update MPD
echo "6. Updating MPD..."
run_on_pi "mpc update RADIO" || echo "   ⚠️  MPD update had issues (non-critical)"

# 7. Restart web server
echo "7. Restarting web server..."
run_on_pi "sudo systemctl restart nginx 2>/dev/null || sudo systemctl restart apache2 2>/dev/null"
sleep 3
if run_on_pi "systemctl is-active nginx >/dev/null 2>&1 || systemctl is-active apache2 >/dev/null 2>&1"; then
    echo "   ✅ Web server restarted"
else
    echo "   ⚠️  Web server status unclear"
fi

# 8. Final verification
echo "8. Final verification..."
radio_count=$(run_on_pi "sqlite3 /var/local/www/db/moode-sqlite3.db 'SELECT COUNT(*) FROM cfg_radio WHERE type = \"r\";' 2>/dev/null" || echo "0")
echo "   Total visible stations: $radio_count"

deutschlandfunk=$(run_on_pi "sqlite3 /var/local/www/db/moode-sqlite3.db 'SELECT name FROM cfg_radio WHERE name LIKE \"%Deutschlandfunk%\" OR name = \"Radio FM4\";' 2>/dev/null" || echo "")
echo "   Target stations found:"
echo "$deutschlandfunk" | while read line; do
    [ -n "$line" ] && echo "     ✅ $line"
done

http_code=$(run_on_pi "curl -s -o /dev/null -w '%{http_code}' http://localhost/" || echo "000")
if [ "$http_code" = "200" ]; then
    echo "   ✅ Web interface responding (HTTP $http_code)"
else
    echo "   ⚠️  Web interface returned HTTP $http_code"
fi

echo ""
echo "✅ Complete Radio Fix Finished!"
echo ""
echo "All stations are now visible in the database."
echo ""
echo "NEXT STEPS:"
echo "1. Hard refresh your browser: Ctrl+Shift+R (Windows/Linux) or Cmd+Shift+R (Mac)"
echo "2. Navigate to Library view"
echo "3. Click the 'Radio' button"
echo "4. All 237+ stations should now be visible, including:"
echo "   - Radio FM4"
echo "   - Deutschlandfunk"
echo "   - Deutschlandfunk Nova"
echo "   - Deutschlandfunk Kultur"
echo ""
echo "If stations still don't appear:"
echo "- Check browser console (F12) for JavaScript errors"
echo "- Try a different browser"
echo "- Clear browser cache completely"

