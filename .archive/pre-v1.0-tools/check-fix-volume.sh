#!/bin/bash
# Check and fix volume issues
# Run this on the Raspberry Pi: sudo bash check-fix-volume.sh

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

if [ ! -d "/proc/asound" ]; then
    error "Not running on Pi"
    exit 1
fi

echo "================================================"
echo "  Volume Check & Fix"
echo "================================================"
echo ""

# Get audio card
AMP100_CARD=$(grep -E "sndrpihifiberry|HiFiBerry" /proc/asound/cards | head -1 | awk '{print $1}' || echo "")
if [ -z "$AMP100_CARD" ]; then
    error "HiFiBerry not detected!"
    exit 1
fi
log "HiFiBerry detected as card $AMP100_CARD"
echo ""

# Step 1: Check current volume levels
info "Step 1: Checking current volume levels..."

# Check hardware volume
if command -v amixer >/dev/null 2>&1; then
    echo "Hardware volume (amixer):"
    amixer -c "$AMP100_CARD" sget Master 2>/dev/null | grep -E "\[.*%\]|\[on\]|\[off\]" | head -3 || true
    amixer -c "$AMP100_CARD" sget PCM 2>/dev/null | grep -E "\[.*%\]|\[on\]|\[off\]" | head -3 || true
    amixer -c "$AMP100_CARD" sget Digital 2>/dev/null | grep -E "\[.*%\]|\[on\]|\[off\]" | head -3 || true
fi
echo ""

# Check MPD volume
if command -v mpc >/dev/null 2>&1 && systemctl is-active --quiet mpd.service 2>/dev/null; then
    MPD_VOLUME=$(mpc volume 2>/dev/null | grep -oE "[0-9]+%" || echo "")
    if [ -n "$MPD_VOLUME" ]; then
        info "MPD volume: $MPD_VOLUME"
    else
        warn "Could not get MPD volume"
    fi
fi
echo ""

# Check moOde database volume settings
MOODE_DB="/var/local/www/db/moode-sqlite3.db"
if [ -f "$MOODE_DB" ]; then
    VOLUME_MPD=$(sqlite3 "$MOODE_DB" "SELECT value FROM cfg_mpd WHERE param='volume';" 2>/dev/null || echo "")
    VOLUME_TYPE=$(sqlite3 "$MOODE_DB" "SELECT value FROM cfg_system WHERE param='volume_type';" 2>/dev/null || echo "")
    info "moOde MPD volume setting: $VOLUME_MPD"
    info "moOde volume type: $VOLUME_TYPE"
fi
echo ""

# Step 2: Check for mute states
info "Step 2: Checking mute states..."
if command -v amixer >/dev/null 2>&1; then
    MASTER_MUTE=$(amixer -c "$AMP100_CARD" sget Master 2>/dev/null | grep -oE "\[off\]|\[on\]" | head -1 || echo "")
    PCM_MUTE=$(amixer -c "$AMP100_CARD" sget PCM 2>/dev/null | grep -oE "\[off\]|\[on\]" | head -1 || echo "")
    DIGITAL_MUTE=$(amixer -c "$AMP100_CARD" sget Digital 2>/dev/null | grep -oE "\[off\]|\[on\]" | head -1 || echo "")
    
    if [ "$MASTER_MUTE" = "[off]" ]; then
        warn "⚠️  Master is MUTED"
    else
        log "✅ Master is unmuted"
    fi
    
    if [ "$PCM_MUTE" = "[off]" ]; then
        warn "⚠️  PCM is MUTED"
    else
        log "✅ PCM is unmuted"
    fi
    
    if [ "$DIGITAL_MUTE" = "[off]" ]; then
        warn "⚠️  Digital is MUTED"
    else
        log "✅ Digital is unmuted"
    fi
fi
echo ""

# Step 3: Check CamillaDSP volume/gain
info "Step 3: Checking CamillaDSP for volume/gain settings..."
CAMILLA_CONFIG="/usr/share/camilladsp/working_config.yml"
if [ -f "$CAMILLA_CONFIG" ]; then
    # Check for gain reduction in pipeline
    if grep -q "gain\|volume" "$CAMILLA_CONFIG" 2>/dev/null; then
        warn "⚠️  CamillaDSP may have gain/volume settings:"
        grep -i "gain\|volume" "$CAMILLA_CONFIG" | head -5 | sed 's/^/     /'
    fi
    
    # Check for negative gain values
    if grep -q "gain.*-[0-9]" "$CAMILLA_CONFIG" 2>/dev/null; then
        warn "⚠️  CamillaDSP has negative gain (reducing volume):"
        grep "gain.*-[0-9]" "$CAMILLA_CONFIG" | head -3 | sed 's/^/     /'
    fi
fi
echo ""

# Step 4: Fix volume issues
info "Step 4: Fixing volume issues..."

# Unmute everything
if command -v amixer >/dev/null 2>&1; then
    log "Unmuting all controls..."
    amixer -c "$AMP100_CARD" sset Master unmute >/dev/null 2>&1 || true
    amixer -c "$AMP100_CARD" sset PCM unmute >/dev/null 2>&1 || true
    amixer -c "$AMP100_CARD" sset Digital unmute >/dev/null 2>&1 || true
    log "✅ All controls unmuted"
fi
echo ""

# Set hardware volume to a reasonable level (50% for testing)
if command -v amixer >/dev/null 2>&1; then
    log "Setting hardware volume to 50% (for testing)..."
    amixer -c "$AMP100_CARD" sset Master 50% >/dev/null 2>&1 || true
    amixer -c "$AMP100_CARD" sset PCM 50% >/dev/null 2>&1 || true
    amixer -c "$AMP100_CARD" sset Digital 50% >/dev/null 2>&1 || true
    log "✅ Hardware volume set to 50%"
fi
echo ""

# Check MPD volume control type
if [ -f "$MOODE_DB" ]; then
    VOLUME_TYPE=$(sqlite3 "$MOODE_DB" "SELECT value FROM cfg_system WHERE param='volume_type';" 2>/dev/null || echo "")
    info "Current volume_type: $VOLUME_TYPE"
    
    # For HiFiBerry AMP100, should use "hardware" or "software" volume control
    # If using CamillaDSP, might need software volume
    if [ -z "$VOLUME_TYPE" ] || [ "$VOLUME_TYPE" = "none" ]; then
        warn "⚠️  Volume type is '$VOLUME_TYPE' - may need to be 'hardware' or 'software'"
    fi
fi
echo ""

# Step 5: Set MPD volume if MPD is running
if command -v mpc >/dev/null 2>&1 && systemctl is-active --quiet mpd.service 2>/dev/null; then
    log "Setting MPD volume to 50% (for testing)..."
    mpc volume 50 >/dev/null 2>&1 || warn "Failed to set MPD volume"
    sleep 1
    MPD_VOLUME=$(mpc volume 2>/dev/null | grep -oE "[0-9]+%" || echo "")
    if [ -n "$MPD_VOLUME" ]; then
        log "✅ MPD volume set to $MPD_VOLUME"
    fi
fi
echo ""

# Step 6: Show final volume state
info "Step 5: Final volume state..."
echo "Hardware volume:"
amixer -c "$AMP100_CARD" sget Master 2>/dev/null | grep -E "\[.*%\]|\[on\]|\[off\]" | head -2 || true
echo ""

if command -v mpc >/dev/null 2>&1 && systemctl is-active --quiet mpd.service 2>/dev/null; then
    MPD_VOLUME=$(mpc volume 2>/dev/null | grep -oE "[0-9]+%" || echo "")
    echo "MPD volume: $MPD_VOLUME"
fi
echo ""

log "=== Volume Check Complete ==="
echo ""
warn "IMPORTANT: Volume is now set to 50% for testing"
warn "If volume at 21 should be loud, there may be:"
warn "  1. Volume type mismatch (hardware vs software)"
warn "  2. CamillaDSP gain reduction"
warn "  3. Multiple volume controls not synchronized"
echo ""
info "To test: Play a track and adjust volume in moOde Web UI"
info "Check: moOde Web UI → Audio Config → Volume control type"
echo ""
