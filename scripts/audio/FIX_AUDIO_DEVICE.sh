#!/bin/bash
################################################################################
#
# Fix Audio Device - Ensure AMP100 is Used
#
# Fixes IEC958/HDMI audio issue - ensures AMP100 is selected
#
################################################################################

set -euo pipefail

log() { echo -e "\033[0;32m[FIX]${NC} $1"; }
error() { echo -e "\033[0;31m[ERROR]${NC} $1" >&2; }
warn() { echo -e "\033[0;33m[WARN]${NC} $1"; }

echo "=== Fix Audio Device (AMP100 Only) ==="
echo ""

# Find AMP100
if [ ! -d "/proc/asound" ]; then
    error "Must run on Pi"
    exit 1
fi

if ! grep -q "sndrpihifiberry\|HiFiBerry AMP100" /proc/asound/cards 2>/dev/null; then
    error "AMP100 not detected!"
    exit 1
fi

AMP100_CARD=$(grep -E "sndrpihifiberry|HiFiBerry AMP100" /proc/asound/cards | head -1 | awk '{print $1}')
log "AMP100 detected: Card $AMP100_CARD"

# Check for other audio devices
echo ""
echo "All audio cards:"
cat /proc/asound/cards
echo ""

# Update moOde database
MOODE_DB="/var/local/www/db/moode-sqlite3.db"
if [ -f "$MOODE_DB" ]; then
    log "Updating moOde database..."
    
    # Set AMP100 as card
    sqlite3 "$MOODE_DB" "UPDATE cfg_system SET value='$AMP100_CARD' WHERE param='cardnum';" 2>/dev/null || true
    sqlite3 "$MOODE_DB" "UPDATE cfg_system SET value='HiFiBerry AMP100' WHERE param='i2sdevice';" 2>/dev/null || true
    sqlite3 "$MOODE_DB" "UPDATE cfg_system SET value='HiFiBerry AMP100' WHERE param='adevname';" 2>/dev/null || true
    
    # Set MPD device to _audioout
    sqlite3 "$MOODE_DB" "UPDATE cfg_mpd SET value='_audioout' WHERE param='device';" 2>/dev/null || true
    
    # Software volume
    sqlite3 "$MOODE_DB" "UPDATE cfg_system SET value='Software' WHERE param='volume_control';" 2>/dev/null || true
    
    # ALSA mode
    sqlite3 "$MOODE_DB" "UPDATE cfg_system SET value='plughw' WHERE param='alsa_output_mode';" 2>/dev/null || true
    
    log "✅ Database updated"
else
    warn "Database not found - will be created on first boot"
fi

# Fix ALSA routing - ensure _audioout points to peppy (not HDMI/IEC)
log "Configuring ALSA routing..."
mkdir -p /etc/alsa/conf.d/

# _audioout.conf - routes to peppy (PeppyMeter chain)
cat > /etc/alsa/conf.d/_audioout.conf << EOF
pcm._audioout {
    type plug
    slave.pcm "peppy"
}
EOF

# _peppyout.conf - routes to AMP100
cat > /etc/alsa/conf.d/_peppyout.conf << EOF
pcm._peppyout {
    type hw
    card $AMP100_CARD
    device 0
}
EOF

log "✅ ALSA routing configured: MPD → _audioout → peppy → _peppyout → AMP100"

# Disable HDMI audio in config.txt if possible
if [ -f /boot/firmware/config.txt ]; then
    if ! grep -q "dtoverlay=vc4-kms-v3d.*noaudio" /boot/firmware/config.txt 2>/dev/null; then
        warn "HDMI audio may still be enabled in config.txt"
        warn "Add 'noaudio' to dtoverlay: dtoverlay=vc4-kms-v3d-pi5,noaudio"
    fi
fi

# Restart MPD
log "Restarting MPD..."
systemctl restart mpd 2>/dev/null && sleep 2 && log "✅ MPD restarted" || warn "Could not restart MPD"

# Set volume to SAFE level (NEVER 100%!)
amixer -c "$AMP100_CARD" set Master unmute >/dev/null 2>&1 || true
amixer -c "$AMP100_CARD" set Master 30% >/dev/null 2>&1 || true
mpc volume 20 >/dev/null 2>&1 || true

echo ""
log "=== Fix Complete ==="
echo ""
echo "Audio chain: MPD → _audioout → peppy → _peppyout → AMP100 (card $AMP100_CARD)"
echo ""
echo "⚠️  Volume set to SAFE level (30% hardware, 20% software)"
echo "⚠️  Check volume before testing: mpc volume"
