#!/bin/bash
################################################################################
#
# Fix moOde Web Interface - Complete Fix
# 
# Fixes web interface, radio stations, cover art, and database issues
#
################################################################################

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
cd "$PROJECT_ROOT"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[FIX]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

PI_HOST="${1:-172.24.1.1}"
PI_USER="${2:-andre}"
PI_PASS="${3:-0815}"

log "Fixing moOde web interface completely..."

# Function to run command on Pi
run_on_pi() {
    sshpass -p "$PI_PASS" ssh -o StrictHostKeyChecking=no "$PI_USER@$PI_HOST" "$1"
}

# 1. Fix database permissions
log "1. Fixing database permissions..."
run_on_pi "sudo chown www-data:www-data /var/local/www/db/moode-sqlite3.db"
run_on_pi "sudo chmod 664 /var/local/www/db/moode-sqlite3.db"
run_on_pi "sudo chown -R www-data:www-data /var/local/www/db/"
run_on_pi "sudo chmod -R 755 /var/local/www/db/"

# 2. Fix web server files permissions
log "2. Fixing web server files permissions..."
run_on_pi "sudo chown -R www-data:www-data /var/www/"
run_on_pi "sudo chmod -R 755 /var/www/"

# 3. Restart web server
log "3. Restarting web server..."
if run_on_pi "systemctl is-active apache2 >/dev/null 2>&1"; then
    run_on_pi "sudo systemctl restart apache2"
    sleep 2
    log "  Apache restarted"
elif run_on_pi "systemctl is-active nginx >/dev/null 2>&1"; then
    run_on_pi "sudo systemctl restart nginx"
    sleep 2
    log "  Nginx restarted"
else
    warn "  No web server found, starting Apache..."
    run_on_pi "sudo systemctl start apache2 || sudo systemctl start nginx"
    sleep 2
fi

# 4. Fix MPD and update database
log "4. Fixing MPD..."
run_on_pi "sudo systemctl restart mpd"
sleep 3
run_on_pi "mpc update" || warn "MPC update had issues"

# 5. Add radio stations directly to database
log "5. Adding radio stations to database..."

# Radio stations
declare -a stations=(
    "FM4|https://orf-live.ors-shoutcast.at/fm4-q2a|Austria|Various"
    "Deutschlandfunk|https://st01.sslstream.dlf.de/dlf/01/128/mp3/stream.mp3|Germany|News"
    "Deutschlandfunk Nova|https://st01.sslstream.dlf.de/dlf/02/128/mp3/stream.mp3|Germany|Alternative"
    "Deutschlandfunk Kultur|https://st01.sslstream.dlf.de/dlf/03/128/mp3/stream.mp3|Germany|Culture"
)

for station in "${stations[@]}"; do
    IFS='|' read -r name url country genre <<< "$station"
    log "  Adding: $name"
    
    # Escape single quotes for SQL
    name_escaped=$(echo "$name" | sed "s/'/''/g")
    url_escaped=$(echo "$url" | sed "s/'/''/g")
    
    # Get next available ID (stations with id > 499 are user-added)
    next_id=$(run_on_pi "sqlite3 /var/local/www/db/moode-sqlite3.db \"SELECT COALESCE(MAX(id), 499) + 1 FROM cfg_radio WHERE id > 499;\" 2>/dev/null" || echo "500")
    
    # Check if station already exists
    exists=$(run_on_pi "sqlite3 /var/local/www/db/moode-sqlite3.db \"SELECT COUNT(*) FROM cfg_radio WHERE name='$name_escaped' OR station='$url_escaped';\" 2>/dev/null" || echo "0")
    
    if [ "$exists" = "0" ]; then
        # Insert station
        run_on_pi "sqlite3 /var/local/www/db/moode-sqlite3.db \"INSERT INTO cfg_radio (id, station, name, type, logo, genre, broadcaster, language, country, region, bitrate, format, geo_fenced, home_page, monitor) VALUES ($next_id, '$url_escaped', '$name_escaped', 'r', 'local', '$genre', '$(echo $name_escaped | cut -d' ' -f1)', 'German', '$country', 'Europe', '128', 'MP3', 'No', '', 'No');\" 2>/dev/null" && log "    ✅ Added" || warn "    ❌ Failed"
        
        # Create .pls file
        pls_file="/var/lib/mpd/music/RADIO/${name_escaped}.pls"
        pls_content="[playlist]
File1=$url_escaped
Title1=$name_escaped
Length1=-1
NumberOfEntries=1
Version=2
"
        run_on_pi "echo '$pls_content' | sudo tee '$pls_file' > /dev/null"
        run_on_pi "sudo chmod 777 '$pls_file'"
        run_on_pi "sudo chown root:root '$pls_file'"
    else
        log "    ⏭️  Already exists"
    fi
done

# 6. Update MPD radio folder
log "6. Updating MPD radio folder..."
run_on_pi "mpc update RADIO" || warn "MPC update RADIO had issues"

# 7. Fix cover art directories
log "7. Fixing cover art directories..."
run_on_pi "sudo mkdir -p /var/local/www/imagesw/coverart/cache"
run_on_pi "sudo chown -R www-data:www-data /var/local/www/imagesw/"
run_on_pi "sudo chmod -R 755 /var/local/www/imagesw/"

# 8. Clear all caches
log "8. Clearing all caches..."
run_on_pi "sudo rm -rf /var/local/www/imagesw/coverart/cache/* 2>/dev/null || true"
run_on_pi "sudo rm -rf /tmp/moode_* 2>/dev/null || true"

# 9. Verify web interface
log "9. Verifying web interface..."
http_code=$(run_on_pi "curl -s -o /dev/null -w '%{http_code}' http://localhost/" || echo "000")
if [ "$http_code" = "200" ]; then
    log "  ✅ Web interface responding (HTTP $http_code)"
else
    error "  ❌ Web interface not responding (HTTP $http_code)"
fi

# 10. Verify radio stations
log "10. Verifying radio stations..."
radio_count=$(run_on_pi "sqlite3 /var/local/www/db/moode-sqlite3.db 'SELECT COUNT(*) FROM cfg_radio WHERE type != \"f\";' 2>/dev/null" || echo "0")
log "  Found $radio_count radio stations in database"

log ""
log "✅ Complete fix finished!"
log ""
log "Please:"
log "1. Hard refresh your browser (Ctrl+Shift+R or Ctrl+F5)"
log "2. Clear browser cache if needed"
log "3. Check Radio section - you should see the stations now"
log "4. Check Library section - cover art should load"

