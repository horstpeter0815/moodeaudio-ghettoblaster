#!/bin/bash
################################################################################
#
# Complete Cover Art Fix for moOde
# 
# Fixes missing album covers including mounted drive access
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

log "Complete cover art fix for moOde ($PI_USER@$PI_HOST)"

# Function to run command on Pi
run_on_pi() {
    sshpass -p "$PI_PASS" ssh -o StrictHostKeyChecking=no "$PI_USER@$PI_HOST" "$1"
}

# 1. Check and fix mounted drive permissions
log "1. Checking mounted drive permissions..."
for mount in /mnt/NAS /mnt/NVME /mnt/OSDISK /mnt/SATA; do
    if run_on_pi "test -d $mount" 2>/dev/null; then
        log "  Fixing permissions for $mount..."
        run_on_pi "sudo chown -R mpd:audio $mount 2>/dev/null || true"
        run_on_pi "sudo chmod -R 755 $mount 2>/dev/null || true"
    fi
done

# 2. Ensure web server can access mounted drives
log "2. Ensuring web server can access mounted drives..."
run_on_pi "sudo usermod -a -G audio www-data 2>/dev/null || true"
run_on_pi "sudo usermod -a -G mpd www-data 2>/dev/null || true"

# 3. Fix cover art cache directory
log "3. Fixing cover art cache directory..."
run_on_pi "sudo mkdir -p /var/local/www/imagesw/coverart"
run_on_pi "sudo mkdir -p /var/local/www/imagesw/coverart/cache"
run_on_pi "sudo chown -R www-data:www-data /var/local/www/imagesw/coverart"
run_on_pi "sudo chmod -R 755 /var/local/www/imagesw/coverart"

# 4. Clear all caches
log "4. Clearing all caches..."
run_on_pi "sudo rm -rf /var/local/www/imagesw/coverart/cache/* 2>/dev/null || true"
run_on_pi "sudo rm -rf /var/lib/mpd/music/.mpd/albumart/* 2>/dev/null || true"

# 5. Restart MPD and force full rescan
log "5. Restarting MPD..."
run_on_pi "sudo systemctl restart mpd"
sleep 3

log "6. Forcing full MPD database update (this may take several minutes)..."
run_on_pi "mpc clear"
run_on_pi "mpc update --wait"

# 7. Check if music files are accessible
log "7. Checking music file accessibility..."
music_count=$(run_on_pi "mpc listall | wc -l" || echo "0")
log "  Found $music_count files in MPD database"

if [ "$music_count" -lt 10 ]; then
    warn "  Very few files in database. Checking mounted drives..."
    for mount in /mnt/NAS /mnt/NVME /mnt/OSDISK /mnt/SATA; do
        if run_on_pi "test -d $mount" 2>/dev/null; then
            file_count=$(run_on_pi "find $mount -type f \( -name '*.mp3' -o -name '*.flac' -o -name '*.m4a' \) 2>/dev/null | wc -l" || echo "0")
            if [ "$file_count" -gt 0 ]; then
                log "  Found $file_count music files in $mount"
            fi
        fi
    done
    warn "  If drives are not mounted, mount them and run 'mpc update' again"
fi

# 8. Test cover art extraction
log "8. Testing cover art extraction..."
test_file=$(run_on_pi "mpc listall | head -1" || echo "")
if [ -n "$test_file" ]; then
    log "  Testing with: $test_file"
    # Check if cover art can be accessed
    cover_url=$(run_on_pi "echo '$test_file' | sed 's|^/var/lib/mpd/music/||'")
    log "  Cover art should be accessible at: /coverart.php/$cover_url"
else
    warn "  No music files found to test cover art"
fi

# 9. Restart web server
log "9. Restarting web server..."
run_on_pi "sudo systemctl reload apache2 2>/dev/null || sudo systemctl reload nginx 2>/dev/null || sudo systemctl restart apache2 2>/dev/null || sudo systemctl restart nginx 2>/dev/null || true"

log "✅ Complete cover art fix finished!"
log ""
log "Next steps:"
log "1. Hard refresh the moOde web interface (Ctrl+Shift+R or Ctrl+F5)"
log "2. Wait for MPD to finish scanning (check status in moOde)"
log "3. If covers still don't appear:"
log "   - Verify music files have embedded cover art or cover.jpg/png files"
log "   - Check that mounted drives are accessible"
log "   - Run: mpc update (to rescan library)"
log "   - Check browser console for cover art loading errors"

