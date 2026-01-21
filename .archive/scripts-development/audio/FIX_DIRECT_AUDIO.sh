#!/bin/bash
################################################################################
#
# Fix Direct Audio Configuration
#
# Complete fix for direct audio (MPD → AMP100)
# Ensures all configuration is correct for direct audio playback
#
################################################################################

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() { echo -e "${GREEN}[FIX]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
info() { echo -e "${BLUE}[INFO]${NC} $1"; }

# Check if running on Pi
if [ ! -d "/proc/asound" ]; then
    error "Not running on Pi - cannot fix audio"
    exit 1
fi

log "=== Fixing Direct Audio Configuration ==="

# Step 1: Find AMP100 card number
log "Step 1: Detecting AMP100..."
if ! grep -q "sndrpihifiberry\|HiFiBerry AMP100" /proc/asound/cards 2>/dev/null; then
    error "AMP100 not detected!"
    error "Check:"
    error "  1. dtoverlay=hifiberry-amp100 in /boot/firmware/config.txt"
    error "  2. Reboot required after overlay changes"
    error "  3. Hardware connection"
    exit 1
fi

AMP100_CARD=$(grep -E "sndrpihifiberry|HiFiBerry AMP100" /proc/asound/cards | head -1 | awk '{print $1}' || echo "")
if [ -z "$AMP100_CARD" ]; then
    error "Could not determine AMP100 card number"
    exit 1
fi

log "✅ AMP100 detected as card $AMP100_CARD"

# Step 2: Update moOde database
log "Step 2: Updating moOde database..."
MOODE_DB="/var/local/www/db/moode-sqlite3.db"

if [ ! -f "$MOODE_DB" ]; then
    error "moOde database not found at $MOODE_DB"
    exit 1
fi

# Update cardnum
CURRENT_CARD=$(sqlite3 "$MOODE_DB" "SELECT value FROM cfg_system WHERE param='cardnum';" 2>/dev/null || echo "")
if [ "$CURRENT_CARD" != "$AMP100_CARD" ]; then
    log "Updating cardnum from $CURRENT_CARD to $AMP100_CARD"
    sqlite3 "$MOODE_DB" "UPDATE cfg_system SET value='$AMP100_CARD' WHERE param='cardnum';" 2>/dev/null || true
else
    log "✅ cardnum already correct ($AMP100_CARD)"
fi

# Update i2sdevice
sqlite3 "$MOODE_DB" "UPDATE cfg_system SET value='HiFiBerry AMP100' WHERE param='i2sdevice';" 2>/dev/null || true
log "✅ i2sdevice set to 'HiFiBerry AMP100'"

# Ensure peppy_display is OFF
sqlite3 "$MOODE_DB" "UPDATE cfg_system SET value='0' WHERE param='peppy_display';" 2>/dev/null || true
log "✅ peppy_display set to OFF (0)"

# Ensure camilladsp is OFF
sqlite3 "$MOODE_DB" "UPDATE cfg_system SET value='off' WHERE param='camilladsp';" 2>/dev/null || true
log "✅ camilladsp set to OFF"

# CRITICAL: MPD device must be "_audioout" (not card number)
MPD_DEVICE=$(sqlite3 "$MOODE_DB" "SELECT value FROM cfg_mpd WHERE param='device';" 2>/dev/null || echo "")
if [ "$MPD_DEVICE" != "_audioout" ]; then
    log "Fixing MPD device: setting to '_audioout' (was '$MPD_DEVICE')"
    sqlite3 "$MOODE_DB" "UPDATE cfg_mpd SET value='_audioout' WHERE param='device';" 2>/dev/null || true
else
    log "✅ MPD device already correct (_audioout)"
fi

# Step 3: Fix _audioout.conf
log "Step 3: Fixing ALSA _audioout.conf..."
sudo mkdir -p /etc/alsa/conf.d/

sudo tee /etc/alsa/conf.d/_audioout.conf > /dev/null << EOF
#########################################
# This file is managed by moOde
# Direct audio: MPD → _audioout → plughw:$AMP100_CARD,0 → AMP100
#########################################
pcm._audioout {
    type copy
    slave.pcm "plughw:$AMP100_CARD,0"
}
EOF

log "✅ _audioout.conf updated to route to plughw:$AMP100_CARD,0"

# Step 4: Restart MPD
log "Step 4: Restarting MPD..."
sudo systemctl restart mpd
sleep 2

if systemctl is-active mpd >/dev/null 2>&1; then
    log "✅ MPD restarted successfully"
else
    warn "MPD may not be running - check: systemctl status mpd"
fi

# Step 5: Unmute and set safe volume
log "Step 5: Setting audio levels..."
# Unmute (if alsamixer available)
if command -v alsamixer >/dev/null 2>&1; then
    # Try to unmute (non-interactive)
    amixer -c "$AMP100_CARD" set Master unmute >/dev/null 2>&1 || true
    amixer -c "$AMP100_CARD" set Master 50% >/dev/null 2>&1 || true
    log "✅ Audio levels set"
else
    warn "alsamixer not available - set volume manually"
fi

echo ""
log "=== Fix Complete ==="
echo ""
info "Configuration:"
echo "  Card number: $AMP100_CARD"
echo "  ALSA device: plughw:$AMP100_CARD,0"
echo "  MPD device: _audioout"
echo "  PeppyMeter: OFF"
echo "  CamillaDSP: OFF"
echo ""
info "Test audio:"
echo "  speaker-test -c 2 -t sine -f 1000 -D _audioout"
echo "  (Press Ctrl+C to stop)"
echo ""
info "Or test with MPD:"
echo "  mpc play"
echo "  mpc volume 50"
echo "  mpc status"
echo ""
info "Run tests:"
echo "  cd ~/moodeaudio-cursor && sudo bash scripts/audio/TEST_DIRECT_AUDIO.sh"
