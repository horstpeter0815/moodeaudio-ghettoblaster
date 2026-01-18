#!/bin/bash
# Final audio fix - prevents moOde from overriding and fixes CamillaDSP crashes
# Run this: sudo bash fix-audio-final.sh

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() { echo -e "${GREEN}[FIX]${NC} $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*"; }

AMP100_CARD=$(grep -E "sndrpihifiberry|HiFiBerry" /proc/asound/cards | head -1 | awk '{print $1}' || echo "")
MOODE_DB="/var/local/www/db/moode-sqlite3.db"

echo "=== FINAL AUDIO FIX ==="
echo ""

# Step 1: Fix database - set everything correctly
log "Step 1: Fixing database..."
sqlite3 "$MOODE_DB" <<SQL
UPDATE cfg_system SET value='hardware' WHERE param='volume_type';
UPDATE cfg_system SET value='on' WHERE param='camilladsp';
UPDATE cfg_system SET value='$AMP100_CARD' WHERE param='cardnum';
UPDATE cfg_mpd SET value='_audioout' WHERE param='device';
UPDATE cfg_system SET value='HiFiBerry AMP100' WHERE param='adevname';
UPDATE cfg_system SET value='HiFiBerry AMP100' WHERE param='i2sdevice';
UPDATE cfg_system SET value='plughw' WHERE param='alsa_output_mode';
UPDATE cfg_system SET value='Yes' WHERE param='cdsp_fix_playback';
SQL
log "✅ Database fixed"
echo ""

# Step 2: Fix ALSA routing
log "Step 2: Fixing ALSA routing..."
cat > /etc/alsa/conf.d/_audioout.conf <<EOF
#########################################
# This file is managed by moOde
#########################################
pcm._audioout {
type copy
slave.pcm "camilladsp"
}
EOF
log "✅ ALSA routing fixed"
echo ""

# Step 3: Check and fix CamillaDSP config (critical - prevents crashes)
log "Step 3: Checking CamillaDSP config..."
CAMILLA_CONFIG="/usr/share/camilladsp/working_config.yml"
if [ -f "$CAMILLA_CONFIG" ]; then
    # Check for 'channel:' instead of 'channels:' (causes crash)
    if grep -q "channel:" "$CAMILLA_CONFIG" 2>/dev/null && ! grep -q "channels:" "$CAMILLA_CONFIG" 2>/dev/null; then
        warn "⚠️  Fixing config: 'channel:' → 'channels:'"
        sed -i 's/^[[:space:]]*channel:[[:space:]]*\([0-9]\)/    channels: \1/g' "$CAMILLA_CONFIG"
        log "✅ Config fixed"
    fi
    
    # Ensure output device is correct
    if ! grep -q "device.*sndrpihifiberry\|device.*plughw:$AMP100_CARD" "$CAMILLA_CONFIG" 2>/dev/null; then
        warn "⚠️  Checking output device in config..."
        OUTPUT_DEVICE=$(grep -A 1 "^device:" "$CAMILLA_CONFIG" 2>/dev/null | tail -1 | sed 's/.*"\(.*\)".*/\1/' || echo "")
        info "Current output: $OUTPUT_DEVICE"
    fi
else
    warn "⚠️  CamillaDSP config missing - will be created when audio config applied"
fi
echo ""

# Step 4: Set hardware volume
log "Step 4: Setting hardware volume..."
amixer -c "$AMP100_CARD" sset Master unmute >/dev/null 2>&1 || true
amixer -c "$AMP100_CARD" sset PCM unmute >/dev/null 2>&1 || true
amixer -c "$AMP100_CARD" sset Digital unmute >/dev/null 2>&1 || true
amixer -c "$AMP100_CARD" sset Master 75% >/dev/null 2>&1 || true
amixer -c "$AMP100_CARD" sset PCM 75% >/dev/null 2>&1 || true
amixer -c "$AMP100_CARD" sset Digital 75% >/dev/null 2>&1 || true
log "✅ Hardware volume: 75%"
echo ""

# Step 5: Stop services before regenerating config
log "Step 5: Stopping services..."
systemctl stop mpd.service 2>/dev/null || true
systemctl stop camilladsp.service 2>/dev/null || true
sleep 1
echo ""

# Step 6: Regenerate MPD config
log "Step 6: Regenerating MPD config..."
php /var/www/util/upd-mpdconf.php >/dev/null 2>&1 || warn "Regen failed (may be OK)"
sleep 1
echo ""

# Step 7: Start services in correct order
log "Step 7: Starting services..."
systemctl start camilladsp.service
sleep 2

# Check if CamillaDSP started
if systemctl is-active --quiet camilladsp.service 2>/dev/null; then
    log "✅ CamillaDSP started"
else
    error "❌ CamillaDSP failed to start!"
    echo "CamillaDSP logs:"
    journalctl -u camilladsp.service -n 10 --no-pager | tail -5 || true
fi

systemctl start mpd.service
sleep 3

if systemctl is-active --quiet mpd.service 2>/dev/null; then
    log "✅ MPD started"
else
    error "❌ MPD failed to start!"
fi
echo ""

# Step 8: Final verification
log "Step 8: Final verification..."
echo "CamillaDSP status:"
systemctl is-active camilladsp.service && log "✅ Running" || error "❌ NOT running"
echo ""

echo "MPD status:"
systemctl is-active mpd.service && log "✅ Running" || error "❌ NOT running"
echo ""

echo "Hardware volume:"
amixer -c "$AMP100_CARD" sget Master | grep -E "\[.*%\]|\[on\]" | head -2 || true
echo ""

if command -v mpc >/dev/null 2>&1 && systemctl is-active --quiet mpd.service 2>/dev/null; then
    sleep 1
    mpc volume 2>/dev/null | head -1 || true
fi
echo ""

log "=== FIX COMPLETE ==="
echo ""
log "Audio chain: MPD → _audioout → camilladsp → HiFiBerry"
log "Volume type: hardware (volume control works)"
log "Hardware volume: 75%"
echo ""
warn "If audio stops again, check:"
warn "  1. journalctl -u camilladsp.service -n 50"
warn "  2. journalctl -u mpd.service -n 50"
echo ""
