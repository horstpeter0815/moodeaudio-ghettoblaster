#!/bin/bash
################################################################################
#
# Fix Radio Station Visibility
# 
# Ensures all radio stations (including user-added ones) are visible
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

echo "🔧 Fixing radio station visibility..."

# 1. Reset radioview_show_hide to show all stations
echo "1. Resetting radio view settings..."
run_on_pi "sudo sqlite3 /var/local/www/db/moode-sqlite3.db \"UPDATE cfg_system SET radioview_show_hide='No action,No action' WHERE 1=1;\" 2>/dev/null" && echo "   ✅ Reset radioview_show_hide"

# 2. Ensure all user-added stations (id > 499) are type 'r' (regular, not hidden)
echo "2. Ensuring user stations are visible..."
run_on_pi "sudo sqlite3 /var/local/www/db/moode-sqlite3.db \"UPDATE cfg_radio SET type='r' WHERE id > 499 AND type != 'f';\" 2>/dev/null" && echo "   ✅ User stations set to visible"

# 3. Verify stations
echo "3. Verifying stations..."
radio_count=$(run_on_pi "sqlite3 /var/local/www/db/moode-sqlite3.db 'SELECT COUNT(*) FROM cfg_radio WHERE type = \"r\";' 2>/dev/null" || echo "0")
echo "   Found $radio_count visible radio stations (type=r)"

deutschlandfunk=$(run_on_pi "sqlite3 /var/local/www/db/moode-sqlite3.db 'SELECT name FROM cfg_radio WHERE name LIKE \"%Deutschlandfunk%\" OR name = \"Radio FM4\";' 2>/dev/null" || echo "")
echo "   Target stations:"
echo "$deutschlandfunk" | while read line; do
    [ -n "$line" ] && echo "     - $line"
done

# 4. Restart web server
echo "4. Restarting web server..."
run_on_pi "sudo systemctl restart nginx 2>/dev/null || sudo systemctl restart apache2 2>/dev/null"
sleep 2

echo ""
echo "✅ Radio visibility fixed!"
echo ""
echo "Please:"
echo "1. Hard refresh your browser (Ctrl+Shift+R or Cmd+Shift+R)"
echo "2. Click on 'Radio' button in Library view"
echo "3. All stations including Deutschlandfunk should now be visible"

