#!/bin/bash
################################################################################
#
# Force Radio View Refresh
# 
# Forces moOde to refresh the radio view by clearing caches and restarting services
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

echo "🔧 Forcing radio view refresh..."

# 1. Clear browser cache files
echo "1. Clearing browser cache..."
run_on_pi "sudo rm -rf /var/local/www/imagesw/radio-logos/cache/* 2>/dev/null || true"
run_on_pi "sudo rm -rf /tmp/moode_* 2>/dev/null || true"

# 2. Restart web server
echo "2. Restarting web server..."
run_on_pi "sudo systemctl restart nginx 2>/dev/null || sudo systemctl restart apache2 2>/dev/null"
sleep 2

# 3. Verify radio stations are accessible
echo "3. Verifying radio stations..."
radio_count=$(run_on_pi "sqlite3 /var/local/www/db/moode-sqlite3.db 'SELECT COUNT(*) FROM cfg_radio WHERE type != \"f\";' 2>/dev/null" || echo "0")
echo "   Found $radio_count radio stations in database"

# 4. Check if Deutschlandfunk stations exist
echo "4. Checking Deutschlandfunk stations..."
deutschlandfunk=$(run_on_pi "sqlite3 /var/local/www/db/moode-sqlite3.db 'SELECT name FROM cfg_radio WHERE name LIKE \"%Deutschlandfunk%\" OR name LIKE \"%FM4%\";' 2>/dev/null" || echo "")
echo "   Stations found:"
echo "$deutschlandfunk" | while read line; do
    [ -n "$line" ] && echo "     - $line"
done

# 5. Update MPD radio folder
echo "5. Updating MPD radio folder..."
run_on_pi "mpc update RADIO" || echo "   Warning: MPD update had issues"

echo ""
echo "✅ Radio refresh complete!"
echo ""
echo "Please:"
echo "1. Hard refresh your browser (Ctrl+Shift+R or Cmd+Shift+R)"
echo "2. Click on 'Radio' button in the Library view"
echo "3. If stations still don't appear, check browser console (F12) for errors"

