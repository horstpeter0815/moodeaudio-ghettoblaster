#!/bin/bash
# Fix MPD "Failed Player Mode" error
# Checks and fixes audio device chain: MPD → camilladsp → peppy → AMP100

set -euo pipefail

log() { echo -e "\033[0;32m[FIX]\033[0m $1"; }
error() { echo -e "\033[0;31m[ERROR]\033[0m $1" >&2; }
warn() { echo -e "\033[0;33m[WARN]\033[0m $1"; }

if [ ! -d "/proc/asound" ]; then
    error "Must run on Pi"
    exit 1
fi

log "=== Fixing MPD Audio Device Error ==="

# Find AMP100
AMP100_CARD=$(grep -E "sndrpihifiberry|HiFiBerry AMP100" /proc/asound/cards 2>/dev/null | head -1 | awk '{print $1}' || echo "")
if [ -z "$AMP100_CARD" ]; then
    error "AMP100 not detected"
    exit 1
fi
log "AMP100: card $AMP100_CARD"

# Check CamillaDSP status
if ! systemctl is-active --quiet camilladsp 2>/dev/null; then
    warn "CamillaDSP not running, starting..."
    systemctl start camilladsp 2>/dev/null || warn "Could not start CamillaDSP"
    sleep 2
fi

# Check if CamillaDSP ALSA device exists
if ! aplay -l 2>/dev/null | grep -q "camilladsp"; then
    warn "CamillaDSP ALSA device not found"
    # Check if camilladsp service is configured
    if systemctl is-active --quiet camilladsp 2>/dev/null; then
        log "CamillaDSP is running, checking config..."
        # Wait a bit for ALSA device to appear
        sleep 3
    fi
fi

# Verify ALSA chain
log "Checking ALSA chain..."
if [ ! -f /etc/alsa/conf.d/_audioout.conf ]; then
    warn "Missing _audioout.conf, creating..."
    mkdir -p /etc/alsa/conf.d/
    cat > /etc/alsa/conf.d/_audioout.conf << EOF
pcm._audioout {
    type copy
    slave.pcm "camilladsp"
}
EOF
fi

# NO automatic test - NEVER run audio tests
log "⚠️  NO automatic audio test - user will test manually"

# Update MPD config in database
MOODE_DB="/var/local/www/db/moode-sqlite3.db"
if [ -f "$MOODE_DB" ]; then
    log "Updating MPD config..."
    
    # Set device to _audioout
    sqlite3 "$MOODE_DB" "UPDATE cfg_mpd SET value='_audioout' WHERE param='device';" 2>/dev/null
    
    # Ensure audio output mode is correct
    sqlite3 "$MOODE_DB" "UPDATE cfg_system SET value='plughw' WHERE param='alsa_output_mode';" 2>/dev/null
    
    # Set card number
    sqlite3 "$MOODE_DB" "UPDATE cfg_system SET value='$AMP100_CARD' WHERE param='cardnum';" 2>/dev/null
    
    log "Database updated"
fi

# Restart MPD
log "Restarting MPD..."
systemctl restart mpd 2>/dev/null || error "Failed to restart MPD"
sleep 3

# Check MPD status
if systemctl is-active --quiet mpd; then
    log "MPD is running"
    # Check MPD output
    mpc outputs 2>/dev/null | head -5 || warn "Could not check MPD outputs"
else
    error "MPD failed to start"
    systemctl status mpd --no-pager -l | head -20
    exit 1
fi

# NO automatic playback - user must test manually
log "⚠️  NO automatic playback - check volume before testing!"
echo "⚠️  To test: mpc volume 20 && mpc play (set volume FIRST!)"

echo ""
log "=== Fix Complete ==="
echo ""
echo "⚠️  NO automatic playback - you will test manually"
echo "⚠️  Start with: mpc volume 0 (then increase gradually)"
echo ""
echo "If error persists, check:"
echo "  1. CamillaDSP config: /etc/camilladsp/config.yml"
echo "  2. MPD logs: journalctl -u mpd -n 50"
echo "  3. CamillaDSP logs: journalctl -u camilladsp -n 50"
