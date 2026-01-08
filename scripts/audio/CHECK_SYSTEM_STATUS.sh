#!/bin/bash
################################################################################
#
# Check System Status - Complete Status Check
# 
# Verifies web server, database, radio stations, and network connectivity
#
################################################################################

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$PROJECT_ROOT"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[✓]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[!]${NC} $1"
}

error() {
    echo -e "${RED}[✗]${NC} $1"
}

info() {
    echo -e "${BLUE}[i]${NC} $1"
}

PI_HOST="${1:-172.24.1.1}"
PI_USER="${2:-andre}"
PI_PASS="${3:-0815}"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  moOde Audio System Status Check"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Function to run command on Pi
run_on_pi() {
    sshpass -p "$PI_PASS" ssh -o StrictHostKeyChecking=no "$PI_USER@$PI_HOST" "$1" 2>/dev/null
}

# 1. Network Connectivity
info "1. Checking network connectivity..."
if ping -c 1 "$PI_HOST" > /dev/null 2>&1; then
    log "Pi is reachable at $PI_HOST"
else
    error "Cannot reach Pi at $PI_HOST"
    exit 1
fi

# 2. SSH Access
info "2. Checking SSH access..."
if run_on_pi "echo 'SSH OK'" | grep -q "SSH OK"; then
    log "SSH access working"
else
    error "SSH access failed"
    exit 1
fi

# 3. Web Server
info "3. Checking web server..."
WEB_STATUS=$(run_on_pi "systemctl is-active nginx")
if [ "$WEB_STATUS" = "active" ]; then
    log "Nginx is running"
else
    error "Nginx is not running: $WEB_STATUS"
fi

# Check HTTP access
HTTP_CODE=$(run_on_pi "curl -s -o /dev/null -w '%{http_code}' http://localhost/")
if [ "$HTTP_CODE" = "200" ]; then
    log "HTTP access working (200 OK)"
else
    warn "HTTP returned: $HTTP_CODE"
fi

# Check for HTTPS redirect
REDIRECT=$(run_on_pi "curl -s -o /dev/null -w '%{redirect_url}' http://localhost/")
if [ -z "$REDIRECT" ]; then
    log "No HTTPS redirect (HTTP works directly)"
else
    warn "HTTPS redirect detected: $REDIRECT"
fi

# 4. MPD
info "4. Checking MPD..."
MPD_STATUS=$(run_on_pi "systemctl is-active mpd")
if [ "$MPD_STATUS" = "active" ]; then
    log "MPD is running"
else
    warn "MPD is not running: $MPD_STATUS"
fi

# 5. Database
info "5. Checking database..."
DB_EXISTS=$(run_on_pi "test -f /var/local/www/db/moode-sqlite3.db && echo 'yes' || echo 'no'")
if [ "$DB_EXISTS" = "yes" ]; then
    log "Database file exists"
    
    # Check database permissions
    DB_PERMS=$(run_on_pi "ls -la /var/local/www/db/moode-sqlite3.db | awk '{print \$1, \$3, \$4}'")
    info "   Database permissions: $DB_PERMS"
    
    # Check station count
    STATION_COUNT=$(run_on_pi "sqlite3 /var/local/www/db/moode-sqlite3.db 'SELECT COUNT(*) FROM cfg_radio WHERE type=\"r\";' 2>/dev/null")
    if [ -n "$STATION_COUNT" ]; then
        log "Radio stations (visible): $STATION_COUNT"
    else
        error "Cannot read radio stations from database"
    fi
    
    # Check for our specific stations
    DLF_COUNT=$(run_on_pi "sqlite3 /var/local/www/db/moode-sqlite3.db 'SELECT COUNT(*) FROM cfg_radio WHERE name LIKE \"%Deutschlandfunk%\";' 2>/dev/null")
    if [ "$DLF_COUNT" -gt 0 ]; then
        log "Deutschlandfunk stations found: $DLF_COUNT"
    else
        warn "Deutschlandfunk stations not found"
    fi
    
    FM4_COUNT=$(run_on_pi "sqlite3 /var/local/www/db/moode-sqlite3.db 'SELECT COUNT(*) FROM cfg_radio WHERE name LIKE \"%FM4%\";' 2>/dev/null")
    if [ "$FM4_COUNT" -gt 0 ]; then
        log "FM4 station found"
    else
        warn "FM4 station not found"
    fi
else
    error "Database file not found"
fi

# 6. Radio API
info "6. Checking Radio API..."
API_RESPONSE=$(run_on_pi "curl -s 'http://localhost/command/radio.php?cmd=get_stations' | head -100")
if echo "$API_RESPONSE" | grep -q '\[{'; then
    log "Radio API responding (JSON)"
    API_COUNT=$(echo "$API_RESPONSE" | run_on_pi "python3 -c 'import sys, json; data = json.load(sys.stdin); print(len(data))' 2>/dev/null" || echo "0")
    info "   API returned $API_COUNT stations"
else
    error "Radio API not responding or not returning JSON"
fi

# 7. JavaScript Files
info "7. Checking JavaScript files..."
PLAYERLIB_EXISTS=$(run_on_pi "test -f /var/www/js/playerlib.js && echo 'yes' || echo 'no'")
SCRIPTS_PANELS_EXISTS=$(run_on_pi "test -f /var/www/js/scripts-panels.js && echo 'yes' || echo 'no'")

if [ "$PLAYERLIB_EXISTS" = "yes" ]; then
    log "playerlib.js exists"
    PLAYERLIB_SIZE=$(run_on_pi "wc -c /var/www/js/playerlib.js | awk '{print \$1}'")
    info "   Size: $PLAYERLIB_SIZE bytes"
else
    error "playerlib.js not found"
fi

if [ "$SCRIPTS_PANELS_EXISTS" = "yes" ]; then
    log "scripts-panels.js exists"
    SCRIPTS_SIZE=$(run_on_pi "wc -c /var/www/js/scripts-panels.js | awk '{print \$1}'")
    info "   Size: $SCRIPTS_SIZE bytes"
else
    error "scripts-panels.js not found"
fi

# Check if instrumentation is present
INSTRUMENTATION=$(run_on_pi "grep -c 'agent log' /var/www/js/playerlib.js 2>/dev/null || echo '0'")
if [ "$INSTRUMENTATION" -gt 0 ]; then
    warn "Debug instrumentation found ($INSTRUMENTATION instances)"
else
    log "No debug instrumentation (clean files)"
fi

# 8. Display
info "8. Checking display configuration..."
DISPLAY_ACTIVE=$(run_on_pi "ps aux | grep -v grep | grep -c 'xinit\|Xorg' || echo '0'")
if [ "$DISPLAY_ACTIVE" -gt 0 ]; then
    log "Display server running"
else
    warn "Display server not running"
fi

# 9. Audio
info "9. Checking audio configuration..."
CDSP_STATUS=$(run_on_pi "systemctl is-active camilladsp 2>/dev/null || echo 'inactive'")
if [ "$CDSP_STATUS" = "active" ]; then
    log "CamillaDSP is running"
else
    warn "CamillaDSP is not running: $CDSP_STATUS"
fi

# Check audio device
AUDIO_DEVICES=$(run_on_pi "aplay -l 2>/dev/null | grep -c 'card' || echo '0'")
if [ "$AUDIO_DEVICES" -gt 0 ]; then
    log "Audio devices found: $AUDIO_DEVICES"
else
    warn "No audio devices found"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Status Check Complete"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

