#!/bin/bash
################################################################################
#
# Complete Audio Setup V1.0
# - HDMI audio completely disabled
# - AMP100 as card 0
# - PeppyMeter enabled
# - Software volume enabled
# - Radio stations ready
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

log() { echo -e "${GREEN}[AUDIO]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
info() { echo -e "${BLUE}[INFO]${NC} $1"; }

# Check if running on Pi
if [ ! -d "/proc/asound" ]; then
    error "Must run on Pi"
    exit 1
fi

log "=== Complete Audio Setup V1.0 ==="
echo ""

# Step 1: Verify HDMI audio is disabled
log "Step 1: Verifying HDMI audio disabled..."
if grep -q "dtoverlay=vc4-kms-v3d-pi5,noaudio" /boot/firmware/config.txt 2>/dev/null && \
   grep -q "dtparam=audio=off" /boot/firmware/config.txt 2>/dev/null; then
    log "✅ HDMI audio disabled in config.txt"
else
    warn "HDMI audio may not be fully disabled - check /boot/firmware/config.txt"
    warn "Required: dtoverlay=vc4-kms-v3d-pi5,noaudio and dtparam=audio=off"
fi

# Step 2: Find AMP100 card number
log "Step 2: Detecting AMP100..."
if ! grep -q "sndrpihifiberry\|HiFiBerry AMP100" /proc/asound/cards 2>/dev/null; then
    error "AMP100 not detected!"
    error "Check hardware connection and reboot if config.txt was changed"
    exit 1
fi

AMP100_CARD=$(grep -E "sndrpihifiberry|HiFiBerry AMP100" /proc/asound/cards | head -1 | awk '{print $1}' || echo "")
if [ -z "$AMP100_CARD" ]; then
    error "Could not determine AMP100 card number"
    exit 1
fi

log "✅ AMP100 detected as card $AMP100_CARD"

if [ "$AMP100_CARD" != "0" ]; then
    warn "AMP100 is card $AMP100_CARD, not card 0"
    warn "This may be because HDMI audio is still enabled"
    warn "Ensure HDMI audio is completely disabled and reboot"
fi

# Step 3: Update moOde database
log "Step 3: Configuring moOde database..."
MOODE_DB="/var/local/www/db/moode-sqlite3.db"

if [ ! -f "$MOODE_DB" ]; then
    error "moOde database not found"
    exit 1
fi

# Audio device settings
sqlite3 "$MOODE_DB" "UPDATE cfg_system SET value='$AMP100_CARD' WHERE param='cardnum';" 2>/dev/null || true
sqlite3 "$MOODE_DB" "UPDATE cfg_system SET value='HiFiBerry AMP100' WHERE param='i2sdevice';" 2>/dev/null || true
sqlite3 "$MOODE_DB" "UPDATE cfg_system SET value='HiFiBerry AMP100' WHERE param='adevname';" 2>/dev/null || true
log "✅ Audio device: card $AMP100_CARD (HiFiBerry AMP100)"

# PeppyMeter settings
sqlite3 "$MOODE_DB" "UPDATE cfg_system SET value='1' WHERE param='peppy_display';" 2>/dev/null || true
sqlite3 "$MOODE_DB" "UPDATE cfg_system SET value='meter' WHERE param='peppy_display_type';" 2>/dev/null || true
log "✅ PeppyMeter: Enabled (meter mode)"

# CamillaDSP OFF (direct audio)
sqlite3 "$MOODE_DB" "UPDATE cfg_system SET value='off' WHERE param='camilladsp';" 2>/dev/null || true
log "✅ CamillaDSP: OFF (direct audio)"

# Software volume
sqlite3 "$MOODE_DB" "UPDATE cfg_system SET value='Software' WHERE param='volume_control';" 2>/dev/null || true
sqlite3 "$MOODE_DB" "UPDATE cfg_system SET value='100' WHERE param='volume_db_range';" 2>/dev/null || true
log "✅ Software volume: Enabled"

# MPD device
sqlite3 "$MOODE_DB" "UPDATE cfg_mpd SET value='_audioout' WHERE param='device';" 2>/dev/null || true
log "✅ MPD device: _audioout"

# ALSA output mode
sqlite3 "$MOODE_DB" "UPDATE cfg_system SET value='plughw' WHERE param='alsa_output_mode';" 2>/dev/null || true
log "✅ ALSA output mode: plughw"

# Step 4: Configure ALSA routing
log "Step 4: Configuring ALSA routing..."
mkdir -p /etc/alsa/conf.d/

# _audioout.conf - routes to peppy (PeppyMeter ON)
cat > /etc/alsa/conf.d/_audioout.conf << EOF
#########################################
# This file is managed by moOde
# Audio chain: MPD → _audioout → peppy → _peppyout → AMP100
#########################################
pcm._audioout {
    type copy
    slave.pcm "peppy"
}
EOF

# _peppyout.conf - routes to AMP100
cat > /etc/alsa/conf.d/_peppyout.conf << EOF
#########################################
# This file is managed by moOde
# PeppyMeter output → AMP100
#########################################
pcm._peppyout {
    type copy
    slave.pcm "plughw:$AMP100_CARD,0"
}
EOF

log "✅ ALSA routing configured: MPD → peppy → AMP100"

# Step 5: Configure PeppyMeter
log "Step 5: Configuring PeppyMeter..."
PEPPY_CONF="/etc/peppymeter/config.txt"

if [ -f "$PEPPY_CONF" ]; then
    # Backup
    cp "$PEPPY_CONF" "${PEPPY_CONF}.backup.$(date +%Y%m%d_%H%M%S)" 2>/dev/null || true
    
    # Update config
    sed -i 's/^meter = .*/meter = blue/' "$PEPPY_CONF" 2>/dev/null || true
    sed -i 's/^random.meter.interval = .*/random.meter.interval = 0/' "$PEPPY_CONF" 2>/dev/null || true
    sed -i 's/^meter.folder = .*/meter.folder = 1280x400/' "$PEPPY_CONF" 2>/dev/null || true
    sed -i 's/^screen.width = .*/screen.width = 1280/' "$PEPPY_CONF" 2>/dev/null || true
    sed -i 's/^screen.height = .*/screen.height = 400/' "$PEPPY_CONF" 2>/dev/null || true
    
    log "✅ PeppyMeter configured: blue skin, 1280x400"
else
    warn "PeppyMeter config not found at $PEPPY_CONF"
fi

# Step 6: Restart services
log "Step 6: Restarting services..."
systemctl restart mpd 2>/dev/null || true
sleep 2
systemctl restart peppymeter 2>/dev/null || true
sleep 1
log "✅ Services restarted"

# Step 7: Set volume
log "Step 7: Setting audio levels..."
if command -v alsamixer >/dev/null 2>&1; then
    amixer -c "$AMP100_CARD" set Master unmute >/dev/null 2>&1 || true
    amixer -c "$AMP100_CARD" set Master 100% >/dev/null 2>&1 || true
    log "✅ Hardware volume: 100%"
fi

# Set MPD volume
if command -v mpc >/dev/null 2>&1; then
    mpc volume 80 >/dev/null 2>&1 || true
    log "✅ Software volume: 80%"
fi

echo ""
log "=== Setup Complete ==="
echo ""
info "Configuration:"
echo "  Audio device: Card $AMP100_CARD (HiFiBerry AMP100)"
echo "  PeppyMeter: ✅ Enabled (blue skin, 1280x400)"
echo "  Software volume: ✅ Enabled"
echo "  Audio chain: MPD → peppy → AMP100"
echo ""
info "Radio stations:"
echo "  Add stations via moOde web UI: http://$(hostname -I | awk '{print $1}')/"
echo ""
info "To verify:"
echo "  mpc play"
echo "  systemctl status peppymeter"
echo "  cat /proc/asound/cards"
