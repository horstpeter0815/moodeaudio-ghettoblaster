#!/bin/bash
################################################################################
#
# FIX RADIO STATIONS AND PLAYBACK
# 
# Fixes common issues with radio stations not loading and play button not working
#
################################################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${GREEN}[FIX]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
info() { echo -e "${BLUE}[INFO]${NC} $1"; }

MOODE_DB="/var/local/www/db/moode-sqlite3.db"

log "=== FIXING RADIO STATIONS AND PLAYBACK ==="
echo ""

# Step 1: Check and restart MPD
log "Step 1: Checking MPD service..."
if systemctl is-active --quiet mpd.service 2>/dev/null; then
    info "MPD is running"
    log "Restarting MPD to ensure clean state..."
    systemctl restart mpd.service
    sleep 2
else
    warn "MPD is not running - starting it..."
    systemctl start mpd.service
    sleep 2
fi

# Verify MPD is responding
if command -v mpc >/dev/null 2>&1; then
    if mpc status >/dev/null 2>&1; then
        log "✅ MPD is responding"
    else
        error "MPD is not responding to mpc commands"
        warn "Checking MPD logs..."
        journalctl -u mpd.service --no-pager -n 20 | tail -10
    fi
else
    warn "mpc command not found - cannot verify MPD"
fi
echo ""

# Step 2: Check audio output configuration
log "Step 2: Checking audio output..."
if [ -f "$MOODE_DB" ]; then
    AUDIO_OUTPUT=$(sqlite3 "$MOODE_DB" "SELECT value FROM cfg_system WHERE param='audioout';" 2>/dev/null || echo "")
    if [ -n "$AUDIO_OUTPUT" ]; then
        info "Audio output: $AUDIO_OUTPUT"
        
        # Check if audio output device exists
        if [ -f "/proc/asound/cards" ]; then
            if grep -q "$AUDIO_OUTPUT" /proc/asound/cards 2>/dev/null || [ "$AUDIO_OUTPUT" = "HDMI" ]; then
                log "✅ Audio output device appears valid"
            else
                warn "Audio output '$AUDIO_OUTPUT' may not be available"
                info "Available audio devices:"
                cat /proc/asound/cards 2>/dev/null | grep -E "^ [0-9]" || echo "  (none found)"
            fi
        fi
    else
        warn "Audio output not configured in database"
    fi
else
    warn "Database not found - cannot check audio output"
fi
echo ""

# Step 3: Check radio stations in database
log "Step 3: Checking radio stations..."
if [ -f "$MOODE_DB" ]; then
    RADIO_COUNT=$(sqlite3 "$MOODE_DB" "SELECT COUNT(*) FROM cfg_radio;" 2>/dev/null || echo "0")
    info "Radio stations in database: $RADIO_COUNT"
    
    if [ "$RADIO_COUNT" -eq 0 ]; then
        warn "⚠️  No radio stations found in database!"
        echo ""
        echo "To add radio stations:"
        echo "  1. Open moOde Web UI: http://192.168.10.2"
        echo "  2. Go to: Radio → Add Station"
        echo "  3. Enter station name and URL"
        echo ""
    else
        log "✅ Found $RADIO_COUNT radio stations"
        info "Sample stations:"
        sqlite3 "$MOODE_DB" "SELECT name, station FROM cfg_radio LIMIT 5;" 2>/dev/null | while IFS='|' read name station; do
            echo "  - $name: $station"
        done
    fi
else
    error "Database not found: $MOODE_DB"
fi
echo ""

# Step 4: Fix radio logos directory permissions
log "Step 4: Fixing radio logos directory..."
RADIO_LOGOS_DIR="/var/local/www/imagesw/radio-logos"
if [ ! -d "$RADIO_LOGOS_DIR" ]; then
    log "Creating radio logos directory..."
    mkdir -p "$RADIO_LOGOS_DIR/thumbs"
fi
chown -R www-data:www-data "$RADIO_LOGOS_DIR" 2>/dev/null || true
chmod -R 755 "$RADIO_LOGOS_DIR" 2>/dev/null || true
log "✅ Radio logos directory permissions fixed"
echo ""

# Step 5: Restart web services
log "Step 5: Restarting web services..."
systemctl restart nginx 2>/dev/null && log "✅ nginx restarted" || warn "Could not restart nginx"
systemctl restart php8.4-fpm 2>/dev/null && log "✅ PHP-FPM restarted" || \
    (systemctl restart php*-fpm 2>/dev/null && log "✅ PHP-FPM restarted" || warn "Could not restart PHP-FPM")
echo ""

# Step 6: Check network connectivity (for radio streams)
log "Step 6: Checking network connectivity..."
if ping -c 1 -W 2 8.8.8.8 >/dev/null 2>&1; then
    log "✅ Internet connectivity OK"
else
    warn "⚠️  No internet connectivity"
    warn "Radio streams may not work without internet"
fi
echo ""

# Step 7: Test MPD playback
log "Step 7: Testing MPD..."
if command -v mpc >/dev/null 2>&1; then
    MPD_STATUS=$(mpc status 2>&1)
    if echo "$MPD_STATUS" | grep -q "error\|failed\|cannot"; then
        error "MPD error detected:"
        echo "$MPD_STATUS"
    else
        info "MPD status:"
        echo "$MPD_STATUS" | head -5
    fi
else
    warn "mpc command not found - cannot test MPD"
fi
echo ""

# Summary
log "=== FIX COMPLETE ==="
echo ""
echo "Next steps:"
echo "  1. Clear browser cache (Ctrl+Shift+Delete)"
echo "  2. Hard refresh moOde web interface (Ctrl+F5)"
echo "  3. Check Radio section in moOde Web UI"
echo "  4. Try playing a radio station"
echo ""
echo "If radio stations still don't load:"
echo "  - Add stations via moOde Web UI → Radio → Add Station"
echo ""
echo "If play button still doesn't work:"
echo "  - Check audio output: System → Audio → Output device"
echo "  - Verify MPD: sudo systemctl status mpd"
echo "  - Check MPD logs: sudo journalctl -u mpd.service -n 50"
echo ""
