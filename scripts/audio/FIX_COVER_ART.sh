#!/bin/bash
################################################################################
#
# Fix Missing Cover Art in moOde
# 
# Fixes missing album covers and cover art loading issues
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

# Check if Pi is reachable
PI_HOST="${1:-172.24.1.1}"
PI_USER="${2:-andre}"
PI_PASS="${3:-0815}"

log "Fixing cover art issues on moOde ($PI_USER@$PI_HOST)"

# Wait for Pi to be reachable
log "Checking Pi connection..."
if ! sshpass -p "$PI_PASS" ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 "$PI_USER@$PI_HOST" "echo 'OK'" >/dev/null 2>&1; then
    error "Pi not reachable. Please check connection."
    exit 1
fi

log "Pi is reachable!"

# Function to run command on Pi
run_on_pi() {
    sshpass -p "$PI_PASS" ssh -o StrictHostKeyChecking=no "$PI_USER@$PI_HOST" "$1"
}

# 1. Check MPD status
log "1. Checking MPD status..."
mpd_status=$(run_on_pi "systemctl is-active mpd 2>&1")
if [ "$mpd_status" != "active" ]; then
    warn "MPD is not active. Starting MPD..."
    run_on_pi "sudo systemctl start mpd"
    sleep 2
fi

# 2. Update MPD database (rescan library)
log "2. Updating MPD database (this may take a while)..."
run_on_pi "mpc update --wait" || warn "MPC update had issues, continuing..."

# 3. Check cover art directories and permissions
log "3. Checking cover art directories..."
run_on_pi "sudo mkdir -p /var/lib/mpd/music/.mpd/albumart"
run_on_pi "sudo chown -R mpd:audio /var/lib/mpd/music/.mpd"
run_on_pi "sudo chmod -R 755 /var/lib/mpd/music/.mpd"

# 4. Check web server cover art directory
log "4. Checking web server cover art directory..."
run_on_pi "sudo mkdir -p /var/local/www/imagesw/coverart"
run_on_pi "sudo mkdir -p /var/local/www/imagesw/coverart/thumbs"
run_on_pi "sudo chown -R www-data:www-data /var/local/www/imagesw/coverart"
run_on_pi "sudo chmod -R 755 /var/local/www/imagesw/coverart"

# 5. Clear web server cache
log "5. Clearing web server cache..."
run_on_pi "sudo rm -rf /var/local/www/imagesw/coverart/cache/* 2>/dev/null || true"
run_on_pi "sudo systemctl reload apache2 2>/dev/null || sudo systemctl reload nginx 2>/dev/null || true"

# 6. Restart MPD to refresh database
log "6. Restarting MPD to refresh database..."
run_on_pi "sudo systemctl restart mpd"
sleep 3

# 7. Force MPD to rescan
log "7. Forcing MPD to rescan library..."
run_on_pi "mpc rescan" || warn "MPC rescan had issues"

# 8. Check if cover art files exist in music directory
log "8. Checking for cover art files in music directory..."
cover_count=$(run_on_pi "find /var/lib/mpd/music -type f \( -name '*.jpg' -o -name '*.png' -o -name 'cover.*' -o -name 'folder.*' \) 2>/dev/null | wc -l" || echo "0")
log "Found $cover_count potential cover art files"

# 9. Verify MPD can access music directory
log "9. Verifying MPD access to music directory..."
music_dir=$(run_on_pi "grep 'music_directory' /etc/mpd.conf | head -1 | awk '{print \$2}' | tr -d '\"'")
if [ -n "$music_dir" ]; then
    log "Music directory: $music_dir"
    run_on_pi "sudo chown -R mpd:audio \"$music_dir\" 2>/dev/null || true"
    run_on_pi "sudo chmod -R 755 \"$music_dir\" 2>/dev/null || true"
fi

# 10. Check MPD log for errors
log "10. Checking MPD log for errors..."
mpd_errors=$(run_on_pi "tail -20 /var/log/mpd/mpd.log 2>/dev/null | grep -i error || echo 'No errors found'")
if echo "$mpd_errors" | grep -qi "error"; then
    warn "MPD log shows errors:"
    echo "$mpd_errors"
fi

log "✅ Cover art fix complete!"
log ""
log "Next steps:"
log "1. Refresh the moOde web interface (Ctrl+F5 or hard refresh)"
log "2. Wait a few minutes for MPD to finish scanning"
log "3. Check if covers appear now"
log ""
log "If covers still don't appear:"
log "- Check that your music files have embedded cover art or cover.jpg/png files"
log "- Verify music files are in the correct directory"
log "- Check MPD log: tail -f /var/log/mpd/mpd.log"

