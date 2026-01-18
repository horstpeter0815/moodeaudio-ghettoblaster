#!/bin/bash
# Check Pi Status and Verify Fixes

PI_HOST="${PI_HOST:-192.168.10.2}"
PI_USER="${PI_USER:-andre}"
PI_PASS="${PI_PASS:-0815}"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${GREEN}[OK]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
info() { echo -e "${BLUE}[INFO]${NC} $1"; }

echo "=== CHECKING PI STATUS ==="
echo ""

# Check connectivity
info "Checking connectivity..."
if ping -c 1 -W 2 "$PI_HOST" >/dev/null 2>&1; then
    log "Pi is reachable at $PI_HOST"
else
    error "Pi is NOT reachable at $PI_HOST"
    exit 1
fi
echo ""

# Check SSH
info "Checking SSH access..."
if command -v sshpass >/dev/null 2>&1; then
    sshpass -p "$PI_PASS" ssh -o StrictHostKeyChecking=accept-new -o ConnectTimeout=5 "$PI_USER@$PI_HOST" "echo 'SSH OK'" >/dev/null 2>&1 && {
        log "SSH access working"
    } || {
        error "SSH access failed"
        exit 1
    }
else
    warn "sshpass not found - cannot test SSH automatically"
fi
echo ""

# Run checks on Pi
info "Running checks on Pi..."
if command -v sshpass >/dev/null 2>&1; then
    sshpass -p "$PI_PASS" ssh -o StrictHostKeyChecking=accept-new "$PI_USER@$PI_HOST" << 'EOF'
echo "=== PI STATUS CHECK ==="
echo ""

# 1. Check audio device settings
echo "1. Audio Device Settings:"
MOODE_DB="/var/local/www/db/moode-sqlite3.db"
if [ -f "$MOODE_DB" ]; then
    ADEVNAME=$(sqlite3 "$MOODE_DB" "SELECT value FROM cfg_system WHERE param='adevname';" 2>/dev/null || echo "")
    I2SDEVICE=$(sqlite3 "$MOODE_DB" "SELECT value FROM cfg_system WHERE param='i2sdevice';" 2>/dev/null || echo "")
    AUDIOOUT=$(sqlite3 "$MOODE_DB" "SELECT value FROM cfg_system WHERE param='audioout';" 2>/dev/null || echo "")
    MPD_DEVICE=$(sqlite3 "$MOODE_DB" "SELECT value FROM cfg_mpd WHERE param='device';" 2>/dev/null || echo "")
    
    echo "  adevname: $ADEVNAME"
    echo "  i2sdevice: $I2SDEVICE"
    echo "  audioout: $AUDIOOUT"
    echo "  MPD device: $MPD_DEVICE"
    
    if [ "$ADEVNAME" = "HiFiBerry AMP100" ]; then
        echo "  ✅ adevname is correct"
    else
        echo "  ⚠️  adevname is '$ADEVNAME' (should be 'HiFiBerry AMP100')"
    fi
    
    if [ "$MPD_DEVICE" = "_audioout" ]; then
        echo "  ✅ MPD device is _audioout"
    else
        echo "  ⚠️  MPD device is '$MPD_DEVICE' (should be '_audioout')"
    fi
else
    echo "  ❌ Database not found"
fi
echo ""

# 2. Check MPD status
echo "2. MPD Status:"
if systemctl is-active --quiet mpd.service 2>/dev/null; then
    echo "  ✅ MPD is running"
    if command -v mpc >/dev/null 2>&1; then
        if mpc status >/dev/null 2>&1; then
            echo "  ✅ MPD is responding"
            mpc status | head -3
        else
            echo "  ⚠️  MPD is not responding"
        fi
    fi
else
    echo "  ⚠️  MPD is not running"
fi
echo ""

# 3. Check audio hardware
echo "3. Audio Hardware:"
if [ -f /proc/asound/cards ]; then
    if grep -q "sndrpihifiberry\|HiFiBerry AMP100" /proc/asound/cards 2>/dev/null; then
        echo "  ✅ AMP100 detected:"
        grep -E "sndrpihifiberry|HiFiBerry AMP100" /proc/asound/cards
    else
        echo "  ⚠️  AMP100 not detected in /proc/asound/cards"
        echo "  Available cards:"
        cat /proc/asound/cards
    fi
else
    echo "  ⚠️  /proc/asound/cards not found"
fi
echo ""

# 4. Check audio chain service
echo "4. Audio Chain Service:"
if systemctl is-active --quiet fix-audio-chain.service 2>/dev/null; then
    echo "  ✅ fix-audio-chain.service is active"
elif systemctl is-enabled --quiet fix-audio-chain.service 2>/dev/null; then
    echo "  ⚠️  fix-audio-chain.service is enabled but not active"
else
    echo "  ⚠️  fix-audio-chain.service not found or not enabled"
fi
echo ""

# 5. Check display
echo "5. Display Status:"
if [ -f /home/andre/.xinitrc ]; then
    echo "  ✅ .xinitrc exists"
    if grep -q "SCREEN_RES.*1280,400\|xrandr.*rotate left" /home/andre/.xinitrc 2>/dev/null; then
        echo "  ✅ Display rotation configured"
    else
        echo "  ⚠️  Display rotation may not be configured"
    fi
else
    echo "  ⚠️  .xinitrc not found"
fi
echo ""

# 6. Check network
echo "6. Network Status:"
IP=$(hostname -I 2>/dev/null | awk '{print $1}' || echo "")
if [ -n "$IP" ]; then
    echo "  IP address: $IP"
    if [ "$IP" = "192.168.10.2" ]; then
        echo "  ✅ IP is correct (192.168.10.2)"
    else
        echo "  ⚠️  IP is $IP (expected 192.168.10.2)"
    fi
else
    echo "  ⚠️  Could not determine IP"
fi
echo ""

# 7. Check services
echo "7. Key Services:"
for service in mpd nginx php8.4-fpm; do
    if systemctl is-active --quiet ${service}.service 2>/dev/null; then
        echo "  ✅ $service is running"
    else
        echo "  ⚠️  $service is not running"
    fi
done
echo ""

echo "=== CHECK COMPLETE ==="
EOF
else
    warn "Cannot run remote checks - sshpass not available"
    echo ""
    echo "Manual check commands:"
    echo "  ssh $PI_USER@$PI_HOST"
    echo "  sqlite3 /var/local/www/db/moode-sqlite3.db \"SELECT param, value FROM cfg_system WHERE param IN ('adevname', 'i2sdevice', 'audioout');\""
    echo "  sqlite3 /var/local/www/db/moode-sqlite3.db \"SELECT param, value FROM cfg_mpd WHERE param='device';\""
    echo "  systemctl status mpd"
fi
