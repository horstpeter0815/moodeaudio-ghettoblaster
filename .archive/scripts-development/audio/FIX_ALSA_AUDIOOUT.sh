#!/bin/bash
################################################################################
#
# Fix ALSA _audioout Configuration
#
# Creates/fixes _audioout.conf and _peppyout.conf
#
################################################################################

set -euo pipefail

log() { echo -e "\033[0;32m[FIX]${NC} $1"; }
error() { echo -e "\033[0;31m[ERROR]${NC} $1" >&2; }

if [ ! -d "/proc/asound" ]; then
    error "Must run on Pi"
    exit 1
fi

echo "=== Fix ALSA _audioout Configuration ==="
echo ""

# Find AMP100
if ! grep -q "sndrpihifiberry\|HiFiBerry AMP100" /proc/asound/cards 2>/dev/null; then
    error "AMP100 not detected!"
    exit 1
fi

AMP100_CARD=$(grep -E "sndrpihifiberry|HiFiBerry AMP100" /proc/asound/cards | head -1 | awk '{print $1}')
log "AMP100: Card $AMP100_CARD"

# Create ALSA config directory
mkdir -p /etc/alsa/conf.d/
log "Created /etc/alsa/conf.d/ directory"

# Create _audioout.conf - routes to peppy
log "Creating _audioout.conf..."
cat > /etc/alsa/conf.d/_audioout.conf << EOF
pcm._audioout {
    type plug
    slave.pcm "peppy"
}
EOF
log "✅ _audioout.conf created (routes to peppy)"

# Create _peppyout.conf - routes to AMP100
log "Creating _peppyout.conf..."
cat > /etc/alsa/conf.d/_peppyout.conf << EOF
pcm._peppyout {
    type hw
    card $AMP100_CARD
    device 0
}
EOF
log "✅ _peppyout.conf created (routes to AMP100 card $AMP100_CARD)"

# Verify files exist
echo ""
echo "Verifying ALSA configs:"
if [ -f /etc/alsa/conf.d/_audioout.conf ]; then
    echo "  ✅ _audioout.conf exists:"
    cat /etc/alsa/conf.d/_audioout.conf | sed 's/^/    /'
else
    error "  ❌ _audioout.conf missing!"
fi

if [ -f /etc/alsa/conf.d/_peppyout.conf ]; then
    echo "  ✅ _peppyout.conf exists:"
    cat /etc/alsa/conf.d/_peppyout.conf | sed 's/^/    /'
else
    error "  ❌ _peppyout.conf missing!"
fi

# NO automatic test - NEVER run audio tests
echo ""
log "⚠️  NO automatic audio test - user will test manually"

# Restart MPD
echo ""
log "Restarting MPD..."
systemctl restart mpd 2>/dev/null && sleep 3 && log "✅ MPD restarted" || warn "Could not restart MPD"

# Check MPD status
echo ""
echo "MPD status:"
systemctl status mpd --no-pager | head -10

echo ""
log "=== Fix Complete ==="
echo ""
echo "Audio chain: MPD → _audioout → peppy → _peppyout → AMP100"
echo ""
echo "⚠️  NO automatic playback - you will test manually"
echo "⚠️  Start with: mpc volume 0 (then increase gradually)"
