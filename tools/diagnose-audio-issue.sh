#!/bin/bash
# Diagnose why audio stops working after a moment
# Run this on the Pi: sudo bash diagnose-audio-issue.sh

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${GREEN}[INFO]${NC} $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*"; }
info() { echo -e "${BLUE}[CHECK]${NC} $*"; }

echo "================================================"
echo "  Diagnosing Audio Issue"
echo "================================================"
echo ""

# Get audio card
AMP100_CARD=$(grep -E "sndrpihifiberry|HiFiBerry" /proc/asound/cards | head -1 | awk '{print $1}' || echo "")
log "HiFiBerry card: $AMP100_CARD"
echo ""

# Check 1: CamillaDSP status
info "Check 1: CamillaDSP service status..."
if systemctl is-active --quiet camilladsp.service 2>/dev/null; then
    log "✅ CamillaDSP is running"
else
    error "❌ CamillaDSP is NOT running"
    echo "Recent CamillaDSP logs:"
    journalctl -u camilladsp.service -n 20 --no-pager 2>/dev/null | tail -10 || true
fi
echo ""

# Check 2: CamillaDSP config file
info "Check 2: CamillaDSP config file..."
CAMILLA_CONFIG="/usr/share/camilladsp/working_config.yml"
if [ -f "$CAMILLA_CONFIG" ]; then
    log "✅ Config file exists"
    
    # Check for errors in config
    if grep -q "channel:" "$CAMILLA_CONFIG" 2>/dev/null && ! grep -q "channels:" "$CAMILLA_CONFIG" 2>/dev/null; then
        error "❌ Config has 'channel:' instead of 'channels:' (will crash)"
    fi
    
    # Check output device
    OUTPUT_DEVICE=$(grep -A 1 "^device:" "$CAMILLA_CONFIG" 2>/dev/null | grep -v "^device:" | sed 's/.*"\(.*\)".*/\1/' | head -1 || echo "")
    info "Output device: $OUTPUT_DEVICE"
    
    if [ -z "$OUTPUT_DEVICE" ]; then
        error "❌ No output device configured in CamillaDSP"
    fi
else
    error "❌ CamillaDSP config file missing!"
fi
echo ""

# Check 3: MPD status
info "Check 3: MPD service status..."
if systemctl is-active --quiet mpd.service 2>/dev/null; then
    log "✅ MPD is running"
    
    if command -v mpc >/dev/null 2>&1; then
        echo "MPD status:"
        mpc status 2>/dev/null | head -5 || true
        echo ""
        mpc outputs 2>/dev/null | head -5 || true
    fi
else
    error "❌ MPD is NOT running"
    echo "Recent MPD logs:"
    journalctl -u mpd.service -n 20 --no-pager 2>/dev/null | tail -10 || true
fi
echo ""

# Check 4: ALSA routing
info "Check 4: ALSA routing..."
AUDIOOUT_CONF="/etc/alsa/conf.d/_audioout.conf"
if [ -f "$AUDIOOUT_CONF" ]; then
    CURRENT_DEVICE=$(grep "slave.pcm" "$AUDIOOUT_CONF" 2>/dev/null | sed 's/.*"\(.*\)".*/\1/' || echo "")
    if [ "$CURRENT_DEVICE" = "camilladsp" ]; then
        log "✅ Routes through CamillaDSP"
    else
        warn "⚠️  Routes to: $CURRENT_DEVICE (should be 'camilladsp')"
    fi
else
    error "❌ _audioout.conf missing"
fi
echo ""

# Check 5: Volume state
info "Check 5: Volume state..."
if command -v amixer >/dev/null 2>&1; then
    MASTER_MUTE=$(amixer -c "$AMP100_CARD" sget Master 2>/dev/null | grep -oE "\[off\]|\[on\]" | head -1 || echo "")
    MASTER_VOL=$(amixer -c "$AMP100_CARD" sget Master 2>/dev/null | grep -oE "\[[0-9]+%\]" | head -1 || echo "")
    
    if [ "$MASTER_MUTE" = "[off]" ]; then
        error "❌ Master is MUTED"
    else
        log "✅ Master unmuted, volume: $MASTER_VOL"
    fi
fi
echo ""

# Check 6: Check if moOde is overwriting config
info "Check 6: Checking moOde database for conflicting settings..."
MOODE_DB="/var/local/www/db/moode-sqlite3.db"
if [ -f "$MOODE_DB" ]; then
    VOLUME_TYPE=$(sqlite3 "$MOODE_DB" "SELECT value FROM cfg_system WHERE param='volume_type';" 2>/dev/null || echo "")
    CAMILLADSP_MODE=$(sqlite3 "$MOODE_DB" "SELECT value FROM cfg_system WHERE param='camilladsp';" 2>/dev/null || echo "")
    MPD_DEVICE=$(sqlite3 "$MOODE_DB" "SELECT value FROM cfg_mpd WHERE param='device';" 2>/dev/null || echo "")
    
    info "volume_type: $VOLUME_TYPE"
    info "camilladsp: $CAMILLADSP_MODE"
    info "MPD device: $MPD_DEVICE"
    
    if [ "$VOLUME_TYPE" != "hardware" ]; then
        warn "⚠️  volume_type is '$VOLUME_TYPE' (should be 'hardware')"
    fi
    
    if [ "$MPD_DEVICE" != "_audioout" ]; then
        warn "⚠️  MPD device is '$MPD_DEVICE' (should be '_audioout')"
    fi
fi
echo ""

# Check 7: Check for CamillaDSP process
info "Check 7: Checking CamillaDSP process..."
if pgrep -f camilladsp >/dev/null 2>&1; then
    log "✅ CamillaDSP process is running"
    ps aux | grep camilladsp | grep -v grep | head -2
else
    error "❌ CamillaDSP process is NOT running"
fi
echo ""

# Check 8: Check MPD config
info "Check 8: Checking MPD config..."
MPD_CONF="/etc/mpd.conf"
if [ -f "$MPD_CONF" ]; then
    if grep -q 'device "_audioout"' "$MPD_CONF" 2>/dev/null; then
        log "✅ MPD config uses '_audioout'"
    else
        warn "⚠️  MPD config doesn't use '_audioout'"
        grep "device " "$MPD_CONF" | head -2 || true
    fi
fi
echo ""

log "================================================"
log "  Diagnosis Complete"
log "================================================"
echo ""
