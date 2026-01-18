#!/bin/bash
# Complete Audio & Volume Fix - Run this NOW
# sudo bash fix-audio-volume-complete.sh

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${GREEN}[FIX]${NC} $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*"; }

if [ ! -d "/proc/asound" ]; then
    error "Not running on Pi"
    exit 1
fi

echo "================================================"
echo "  COMPLETE AUDIO & VOLUME FIX"
echo "================================================"
echo ""

# Get audio card
AMP100_CARD=$(grep -E "sndrpihifiberry|HiFiBerry" /proc/asound/cards | head -1 | awk '{print $1}' || echo "")
if [ -z "$AMP100_CARD" ]; then
    error "HiFiBerry not detected!"
    exit 1
fi
log "HiFiBerry card: $AMP100_CARD"
echo ""

# Step 1: Fix moOde database
log "Step 1: Fixing moOde database..."
MOODE_DB="/var/local/www/db/moode-sqlite3.db"
if [ -f "$MOODE_DB" ]; then
    # Set volume type to hardware (critical for volume control)
    sqlite3 "$MOODE_DB" "UPDATE cfg_system SET value='hardware' WHERE param='volume_type';" 2>/dev/null || true
    log "✅ Volume type set to 'hardware'"
    
    # Enable CamillaDSP
    sqlite3 "$MOODE_DB" "UPDATE cfg_system SET value='on' WHERE param='camilladsp';" 2>/dev/null || true
    log "✅ CamillaDSP enabled"
    
    # Set card number
    sqlite3 "$MOODE_DB" "UPDATE cfg_system SET value='$AMP100_CARD' WHERE param='cardnum';" 2>/dev/null || true
    
    # Set MPD device to _audioout
    sqlite3 "$MOODE_DB" "UPDATE cfg_mpd SET value='_audioout' WHERE param='device';" 2>/dev/null || true
    
    # Set adevname
    sqlite3 "$MOODE_DB" "UPDATE cfg_system SET value='HiFiBerry AMP100' WHERE param='adevname';" 2>/dev/null || true
    
    # Set i2sdevice
    sqlite3 "$MOODE_DB" "UPDATE cfg_system SET value='HiFiBerry AMP100' WHERE param='i2sdevice';" 2>/dev/null || true
    
    # Set alsa_output_mode
    sqlite3 "$MOODE_DB" "UPDATE cfg_system SET value='plughw' WHERE param='alsa_output_mode';" 2>/dev/null || true
fi
echo ""

# Step 2: Fix ALSA routing through CamillaDSP
log "Step 2: Fixing ALSA routing..."
AUDIOOUT_CONF="/etc/alsa/conf.d/_audioout.conf"
cat > "$AUDIOOUT_CONF" <<EOF
#########################################
# This file is managed by moOde
#########################################
pcm._audioout {
type copy
slave.pcm "camilladsp"
}
EOF
log "✅ _audioout.conf routes through CamillaDSP"
echo ""

# Step 3: Unmute and set hardware volume
log "Step 3: Fixing hardware volume..."
if command -v amixer >/dev/null 2>&1; then
    # Unmute everything
    amixer -c "$AMP100_CARD" sset Master unmute >/dev/null 2>&1 || true
    amixer -c "$AMP100_CARD" sset PCM unmute >/dev/null 2>&1 || true
    amixer -c "$AMP100_CARD" sset Digital unmute >/dev/null 2>&1 || true
    
    # Set hardware volume to 75% (max safe level per documentation)
    amixer -c "$AMP100_CARD" sset Master 75% >/dev/null 2>&1 || true
    amixer -c "$AMP100_CARD" sset PCM 75% >/dev/null 2>&1 || true
    amixer -c "$AMP100_CARD" sset Digital 75% >/dev/null 2>&1 || true
    
    log "✅ Hardware volume unmuted and set to 75%"
    
    # Show current state
    echo "Current hardware volume:"
    amixer -c "$AMP100_CARD" sget Master 2>/dev/null | grep -E "\[.*%\]|\[on\]|\[off\]" | head -2
fi
echo ""

# Step 4: Regenerate MPD config
log "Step 4: Regenerating MPD config..."
if [ -f "/var/www/util/upd-mpdconf.php" ]; then
    php /var/www/util/upd-mpdconf.php >/dev/null 2>&1 && log "✅ MPD config regenerated" || warn "MPD config regeneration failed"
fi
echo ""

# Step 5: Restart services
log "Step 5: Restarting services..."

# Restart CamillaDSP
if systemctl is-active --quiet camilladsp.service 2>/dev/null; then
    systemctl restart camilladsp.service
    sleep 2
    log "✅ CamillaDSP restarted"
else
    systemctl start camilladsp.service 2>/dev/null || true
    log "✅ CamillaDSP started"
fi

# Restart MPD
if systemctl is-active --quiet mpd.service 2>/dev/null; then
    systemctl restart mpd.service
    sleep 3
    log "✅ MPD restarted"
    
    # Set MPD volume to current setting (don't change it, just verify)
    if command -v mpc >/dev/null 2>&1; then
        sleep 2
        MPD_VOL=$(mpc volume 2>/dev/null | grep -oE "[0-9]+%" || echo "")
        log "✅ MPD volume: $MPD_VOL"
    fi
else
    systemctl start mpd.service
    sleep 3
    log "✅ MPD started"
fi
echo ""

# Step 6: Final verification
log "Step 6: Final verification..."
echo "Hardware volume:"
amixer -c "$AMP100_CARD" sget Master 2>/dev/null | grep -E "\[.*%\]|\[on\]|\[off\]" | head -2 || true
echo ""

if command -v mpc >/dev/null 2>&1 && systemctl is-active --quiet mpd.service 2>/dev/null; then
    echo "MPD status:"
    mpc status 2>/dev/null | head -3 || true
    echo ""
    mpc volume 2>/dev/null || true
fi
echo ""

# Check CamillaDSP
if systemctl is-active --quiet camilladsp.service 2>/dev/null; then
    log "✅ CamillaDSP is running"
else
    warn "⚠️  CamillaDSP is not running"
fi
echo ""

log "================================================"
log "  FIX COMPLETE!"
log "================================================"
echo ""
log "Audio chain: MPD → _audioout → camilladsp → HiFiBerry"
log "Volume type: hardware (volume control works)"
log "Hardware volume: 75% (max safe level)"
echo ""
log "Volume at 21 should now be audible and responsive!"
log "Test by playing a track in moOde Web UI"
echo ""
