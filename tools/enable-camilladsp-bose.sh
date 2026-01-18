#!/bin/bash
# Enable CamillaDSP with Bose filters for audio
# Run this on the Raspberry Pi: sudo bash enable-camilladsp-bose.sh

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() { echo -e "${GREEN}[INFO]${NC} $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*"; }

if [ ! -d "/proc/asound" ]; then
    error "Not running on Pi"
    exit 1
fi

log "=== Enabling CamillaDSP with Bose Filters ==="
echo ""

# Step 1: Get audio card number
if grep -q "sndrpihifiberry\|HiFiBerry" /proc/asound/cards 2>/dev/null; then
    AMP100_CARD=$(grep -E "sndrpihifiberry|HiFiBerry" /proc/asound/cards | head -1 | awk '{print $1}' || echo "")
    log "✅ HiFiBerry detected as card $AMP100_CARD"
else
    error "HiFiBerry not detected!"
    exit 1
fi
echo ""

# Step 2: Enable CamillaDSP in moOde database
log "Step 1: Enabling CamillaDSP in moOde database..."
MOODE_DB="/var/local/www/db/moode-sqlite3.db"
if [ -f "$MOODE_DB" ]; then
    # Enable CamillaDSP
    CAMILLADSP_MODE=$(sqlite3 "$MOODE_DB" "SELECT value FROM cfg_system WHERE param='camilladsp';" 2>/dev/null || echo "off")
    if [ "$CAMILLADSP_MODE" = "off" ] || [ -z "$CAMILLADSP_MODE" ]; then
        log "Enabling CamillaDSP (was: '$CAMILLADSP_MODE')"
        sqlite3 "$MOODE_DB" "UPDATE cfg_system SET value='on' WHERE param='camilladsp';" 2>/dev/null || true
        log "✅ CamillaDSP enabled"
    else
        log "✅ CamillaDSP already enabled: $CAMILLADSP_MODE"
    fi
    
    # Ensure CamillaDSP playback device fix is enabled
    CDSP_FIX=$(sqlite3 "$MOODE_DB" "SELECT value FROM cfg_system WHERE param='cdsp_fix_playback';" 2>/dev/null || echo "")
    if [ "$CDSP_FIX" != "Yes" ]; then
        log "Enabling CamillaDSP playback device fix"
        sqlite3 "$MOODE_DB" "UPDATE cfg_system SET value='Yes' WHERE param='cdsp_fix_playback';" 2>/dev/null || true
    fi
else
    error "moOde database not found"
    exit 1
fi
echo ""

# Step 3: Fix ALSA _audioout.conf to route through CamillaDSP
log "Step 2: Fixing ALSA routing to use CamillaDSP..."
AUDIOOUT_CONF="/etc/alsa/conf.d/_audioout.conf"
TARGET_DEVICE="camilladsp"

if [ -f "$AUDIOOUT_CONF" ]; then
    CURRENT_DEVICE=$(grep "slave.pcm" "$AUDIOOUT_CONF" 2>/dev/null | sed 's/.*"\(.*\)".*/\1/' || echo "")
    if [ "$CURRENT_DEVICE" != "$TARGET_DEVICE" ]; then
        log "Updating _audioout.conf: '$CURRENT_DEVICE' → '$TARGET_DEVICE'"
        sed -i "s|slave.pcm \".*\"|slave.pcm \"$TARGET_DEVICE\"|" "$AUDIOOUT_CONF"
        log "✅ _audioout.conf updated to route through CamillaDSP"
    else
        log "✅ _audioout.conf already routes through CamillaDSP"
    fi
else
    warn "_audioout.conf not found - creating it"
    cat > "$AUDIOOUT_CONF" <<EOF
#########################################
# This file is managed by moOde
#########################################
pcm._audioout {
type copy
slave.pcm "$TARGET_DEVICE"
}
EOF
    log "✅ Created _audioout.conf routing through CamillaDSP"
fi
echo ""

# Step 4: Check CamillaDSP config file
log "Step 3: Checking CamillaDSP configuration..."
CAMILLA_CONFIG="/usr/share/camilladsp/working_config.yml"
if [ -f "$CAMILLA_CONFIG" ]; then
    log "✅ CamillaDSP config file exists: $CAMILLA_CONFIG"
    
    # Check if it has the correct output device
    if grep -q "device.*sndrpihifiberry\|device.*plughw:$AMP100_CARD" "$CAMILLA_CONFIG" 2>/dev/null; then
        log "✅ CamillaDSP output device configured correctly"
    else
        warn "⚠️  CamillaDSP output device may need update"
        log "   Current output device in config:"
        grep -A 2 "device:" "$CAMILLA_CONFIG" | head -3 || echo "   (not found)"
    fi
    
    # Check for Bose filters
    if grep -qi "bose" "$CAMILLA_CONFIG" 2>/dev/null; then
        log "✅ Bose filters found in CamillaDSP config"
    else
        warn "⚠️  No Bose filters found in CamillaDSP config"
        log "   You may need to apply Bose filters separately"
    fi
else
    warn "⚠️  CamillaDSP config file not found: $CAMILLA_CONFIG"
    log "   It will be created when you apply audio config in moOde Web UI"
fi
echo ""

# Step 5: Check if CamillaDSP service is running
log "Step 4: Checking CamillaDSP service..."
if systemctl is-active --quiet camilladsp.service 2>/dev/null; then
    log "✅ CamillaDSP service is running"
else
    warn "⚠️  CamillaDSP service is not running"
    log "   Starting CamillaDSP service..."
    systemctl start camilladsp.service 2>/dev/null || warn "   Failed to start (may start automatically with MPD)"
fi
echo ""

# Step 6: Regenerate MPD config to pick up CamillaDSP
log "Step 5: Regenerating MPD config..."
if [ -f "/var/www/util/upd-mpdconf.php" ]; then
    php /var/www/util/upd-mpdconf.php >/dev/null 2>&1 && log "✅ MPD config regenerated" || warn "⚠️  MPD config regeneration failed"
else
    warn "⚠️  Cannot regenerate MPD config automatically"
    warn "   Run: moOde Web UI → Audio Config → Apply"
fi
echo ""

# Step 7: Restart MPD
log "Step 6: Restarting MPD..."
if systemctl is-active --quiet mpd.service 2>/dev/null; then
    systemctl restart mpd.service
    sleep 3
    log "✅ MPD restarted"
    
    if command -v mpc >/dev/null 2>&1; then
        sleep 2
        mpc volume 20 >/dev/null 2>&1 || true
        log "✅ MPD volume set to 20%"
    fi
else
    log "MPD not running - it will start automatically"
fi
echo ""

log "=== CamillaDSP Enabled ==="
echo ""
log "Audio chain: MPD → _audioout → camilladsp → HiFiBerry"
echo ""
log "Next steps:"
echo "  1. If Bose filters are not applied, run:"
echo "     sudo bash /usr/local/bin/apply-bose-wave-filters.sh"
echo "     or install via moOde Web UI"
echo ""
echo "  2. Test audio: speaker-test -c 2 -t sine -f 1000 -D plughw:$AMP100_CARD,0"
echo "     (Note: This tests direct output, CamillaDSP is used by MPD)"
echo ""
echo "  3. Play a track in moOde Web UI to test CamillaDSP routing"
echo ""
log "To verify CamillaDSP is working:"
echo "  - Check: systemctl status camilladsp"
echo "  - Check: journalctl -u camilladsp -n 50"
echo "  - Check: cat /usr/share/camilladsp/working_config.yml"
echo ""
