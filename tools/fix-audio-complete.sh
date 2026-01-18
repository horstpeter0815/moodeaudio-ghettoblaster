#!/bin/bash
# Complete Audio Fix Script for HiFiBerry AMP100
# Run this on the Raspberry Pi: sudo bash fix-audio-complete.sh

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() { echo -e "${GREEN}[INFO]${NC} $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*"; }

if [ ! -d "/proc/asound" ]; then
    error "Not running on Pi - /proc/asound not found"
    exit 1
fi

log "=== Complete Audio Fix for HiFiBerry AMP100 ==="
echo ""

# Step 1: Check audio card detection
log "Step 1: Checking audio card detection..."
echo "Current /proc/asound/cards:"
cat /proc/asound/cards
echo ""

# Check if any HiFiBerry card exists
if grep -q "sndrpihifiberry\|HiFiBerry" /proc/asound/cards 2>/dev/null; then
    AMP100_CARD=$(grep -E "sndrpihifiberry|HiFiBerry" /proc/asound/cards | head -1 | awk '{print $1}' || echo "")
    log "✅ HiFiBerry detected as card $AMP100_CARD"
else
    error "❌ HiFiBerry AMP100 NOT detected!"
    echo ""
    log "Checking device tree overlay..."
    if grep -q "dtoverlay.*hifiberry.*amp" /boot/firmware/config.txt 2>/dev/null; then
        warn "Overlay found in config.txt but card not detected"
        warn "This usually means:"
        warn "  1. Reboot required after overlay change"
        warn "  2. Hardware connection issue"
        warn "  3. Overlay syntax error"
        echo ""
        log "Current dtoverlay line:"
        grep "dtoverlay.*hifiberry\|dtoverlay.*amp" /boot/firmware/config.txt || echo "  Not found"
        echo ""
        error "Cannot proceed without detected audio card"
        error "Please:"
        error "  1. Check hardware connection"
        error "  2. Verify: dtoverlay=hifiberry-amp100 in /boot/firmware/config.txt"
        error "  3. Reboot: sudo reboot"
        exit 1
    else
        error "dtoverlay for HiFiBerry AMP100 not found in config.txt"
        log "Adding dtoverlay=hifiberry-amp100 to config.txt..."
        if ! grep -q "dtoverlay=hifiberry-amp100" /boot/firmware/config.txt 2>/dev/null; then
            echo "dtoverlay=hifiberry-amp100" >> /boot/firmware/config.txt
            log "✅ Added dtoverlay=hifiberry-amp100"
            error "REBOOT REQUIRED: sudo reboot"
            exit 1
        fi
    fi
    exit 1
fi

echo ""

# Step 2: Fix moOde database
log "Step 2: Fixing moOde database..."
MOODE_DB="/var/local/www/db/moode-sqlite3.db"
if [ -f "$MOODE_DB" ]; then
    # Update cardnum
    CURRENT_CARD=$(sqlite3 "$MOODE_DB" "SELECT value FROM cfg_system WHERE param='cardnum';" 2>/dev/null || echo "")
    if [ "$CURRENT_CARD" != "$AMP100_CARD" ]; then
        log "Updating cardnum: $CURRENT_CARD → $AMP100_CARD"
        sqlite3 "$MOODE_DB" "UPDATE cfg_system SET value='$AMP100_CARD' WHERE param='cardnum';" 2>/dev/null || true
    else
        log "✅ cardnum already correct: $AMP100_CARD"
    fi
    
    # CRITICAL: Set MPD device to _audioout
    MPD_DEVICE=$(sqlite3 "$MOODE_DB" "SELECT value FROM cfg_mpd WHERE param='device';" 2>/dev/null || echo "")
    if [ "$MPD_DEVICE" != "_audioout" ]; then
        log "Fixing MPD device: '$MPD_DEVICE' → '_audioout'"
        sqlite3 "$MOODE_DB" "UPDATE cfg_mpd SET value='_audioout' WHERE param='device';" 2>/dev/null || true
    else
        log "✅ MPD device already correct: _audioout"
    fi
    
    # Set I2S device
    I2S_DEVICE=$(sqlite3 "$MOODE_DB" "SELECT value FROM cfg_system WHERE param='i2sdevice';" 2>/dev/null || echo "")
    if [ "$I2S_DEVICE" != "HiFiBerry AMP100" ]; then
        log "Setting i2sdevice: '$I2S_DEVICE' → 'HiFiBerry AMP100'"
        sqlite3 "$MOODE_DB" "UPDATE cfg_system SET value='HiFiBerry AMP100' WHERE param='i2sdevice';" 2>/dev/null || true
    else
        log "✅ i2sdevice already correct: HiFiBerry AMP100"
    fi
    
    # CRITICAL: Set adevname to prevent HDMI fallback
    ADEVNAME=$(sqlite3 "$MOODE_DB" "SELECT value FROM cfg_system WHERE param='adevname';" 2>/dev/null || echo "")
    if [ "$ADEVNAME" != "HiFiBerry AMP100" ]; then
        log "Setting adevname: '$ADEVNAME' → 'HiFiBerry AMP100'"
        sqlite3 "$MOODE_DB" "UPDATE cfg_system SET value='HiFiBerry AMP100' WHERE param='adevname';" 2>/dev/null || true
    else
        log "✅ adevname already correct: HiFiBerry AMP100"
    fi
    
    # Set alsa_output_mode to plughw (not iec958)
    ALSA_MODE=$(sqlite3 "$MOODE_DB" "SELECT value FROM cfg_system WHERE param='alsa_output_mode';" 2>/dev/null || echo "")
    if [ "$ALSA_MODE" != "plughw" ]; then
        log "Setting alsa_output_mode: '$ALSA_MODE' → 'plughw'"
        sqlite3 "$MOODE_DB" "UPDATE cfg_system SET value='plughw' WHERE param='alsa_output_mode';" 2>/dev/null || true
    else
        log "✅ alsa_output_mode already correct: plughw"
    fi
    
    log "✅ Database updated"
else
    error "moOde database not found at $MOODE_DB"
fi
echo ""

# Step 3: Fix ALSA _audioout.conf
log "Step 3: Fixing ALSA _audioout.conf..."
AUDIOOUT_CONF="/etc/alsa/conf.d/_audioout.conf"

# Check if PeppyMeter or CamillaDSP is enabled
CAMILLADSP_MODE="off"
PEPPY_DISPLAY="0"
if [ -f "$MOODE_DB" ]; then
    CAMILLADSP_MODE=$(sqlite3 "$MOODE_DB" "SELECT value FROM cfg_system WHERE param='camilladsp';" 2>/dev/null || echo "off")
    PEPPY_DISPLAY=$(sqlite3 "$MOODE_DB" "SELECT value FROM cfg_system WHERE param='peppy_display';" 2>/dev/null || echo "0")
fi

# Determine routing
if [ "$CAMILLADSP_MODE" != "off" ] && [ -n "$CAMILLADSP_MODE" ]; then
    TARGET_DEVICE="camilladsp"
    log "Routing: MPD → _audioout → camilladsp → HiFiBerry"
elif [ "$PEPPY_DISPLAY" = "1" ]; then
    TARGET_DEVICE="peppy"
    log "Routing: MPD → _audioout → peppy → _peppyout → HiFiBerry"
else
    TARGET_DEVICE="plughw:$AMP100_CARD,0"
    log "Routing: MPD → _audioout → plughw:$AMP100_CARD,0 (direct)"
fi

if [ -f "$AUDIOOUT_CONF" ]; then
    CURRENT_DEVICE=$(grep "slave.pcm" "$AUDIOOUT_CONF" 2>/dev/null | sed 's/.*"\(.*\)".*/\1/' || echo "")
    if [ "$CURRENT_DEVICE" != "$TARGET_DEVICE" ]; then
        log "Updating _audioout.conf: '$CURRENT_DEVICE' → '$TARGET_DEVICE'"
        sed -i "s|slave.pcm \".*\"|slave.pcm \"$TARGET_DEVICE\"|" "$AUDIOOUT_CONF"
        log "✅ _audioout.conf updated"
    else
        log "✅ _audioout.conf already correct: $TARGET_DEVICE"
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
    log "✅ Created _audioout.conf"
fi
echo ""

# Step 4: Fix _peppyout.conf if PeppyMeter is enabled
if [ "$PEPPY_DISPLAY" = "1" ]; then
    log "Step 4: Fixing _peppyout.conf..."
    PEPPYOUT_CONF="/etc/alsa/conf.d/_peppyout.conf"
    
    if [ "$CAMILLADSP_MODE" != "off" ] && [ -n "$CAMILLADSP_MODE" ]; then
        PEPPY_TARGET="camilladsp"
        log "Routing: _peppyout → camilladsp → HiFiBerry"
    else
        PEPPY_TARGET="plughw:$AMP100_CARD,0"
        log "Routing: _peppyout → plughw:$AMP100_CARD,0 (direct)"
    fi
    
    if [ -f "$PEPPYOUT_CONF" ]; then
        CURRENT_PEPPY=$(grep "slave.pcm" "$PEPPYOUT_CONF" 2>/dev/null | sed 's/.*"\(.*\)".*/\1/' || echo "")
        if [ "$CURRENT_PEPPY" != "$PEPPY_TARGET" ]; then
            log "Updating _peppyout.conf: '$CURRENT_PEPPY' → '$PEPPY_TARGET'"
            sed -i "s|slave.pcm \".*\"|slave.pcm \"$PEPPY_TARGET\"|" "$PEPPYOUT_CONF"
            log "✅ _peppyout.conf updated"
        else
            log "✅ _peppyout.conf already correct: $PEPPY_TARGET"
        fi
    else
        warn "_peppyout.conf not found - creating it"
        cat > "$PEPPYOUT_CONF" <<EOF
#########################################
# This file is managed by moOde
#########################################
pcm._peppyout {
type copy
slave.pcm "$PEPPY_TARGET"
}
EOF
        log "✅ Created _peppyout.conf"
    fi
    echo ""
fi

# Step 5: Unmute and set safe volume
log "Step 5: Unmuting and setting volume..."
if command -v amixer >/dev/null 2>&1; then
    # Unmute all controls
    amixer -c "$AMP100_CARD" sset Master unmute >/dev/null 2>&1 || true
    amixer -c "$AMP100_CARD" sset PCM unmute >/dev/null 2>&1 || true
    amixer -c "$AMP100_CARD" sset Digital unmute >/dev/null 2>&1 || true
    
    # Set safe volume (30% hardware)
    amixer -c "$AMP100_CARD" sset Master 30% >/dev/null 2>&1 || true
    amixer -c "$AMP100_CARD" sset PCM 30% >/dev/null 2>&1 || true
    amixer -c "$AMP100_CARD" sset Digital 30% >/dev/null 2>&1 || true
    
    log "✅ Volume unmuted and set to 30% (safe level)"
    
    # Show current volume
    echo "Current volume levels:"
    amixer -c "$AMP100_CARD" sget Master 2>/dev/null | grep -E "\[.*%\]|\[on\]|\[off\]" | head -2 || true
else
    warn "amixer not found"
fi
echo ""

# Step 6: Regenerate MPD config
log "Step 6: Regenerating MPD config..."
if [ -f "/var/www/util/upd-mpdconf.php" ]; then
    php /var/www/util/upd-mpdconf.php >/dev/null 2>&1 && log "✅ MPD config regenerated" || warn "⚠️  MPD config regeneration failed"
elif [ -f "/var/www/inc/mpd.php" ]; then
    php -r "require '/var/www/inc/mpd.php'; require '/var/www/inc/session.php'; session_id(phpSession('get_sessionid')); phpSession('open'); updMpdConf(); phpSession('close');" >/dev/null 2>&1 && log "✅ MPD config regenerated" || warn "⚠️  MPD config regeneration failed"
else
    warn "⚠️  Cannot regenerate MPD config automatically"
    warn "   Run: moOde Web UI → Audio Config → Apply"
fi

# Verify MPD config has _audioout
MPD_CONF="/etc/mpd.conf"
if [ -f "$MPD_CONF" ]; then
    if grep -q 'device "_audioout"' "$MPD_CONF" 2>/dev/null; then
        log "✅ MPD config has device \"_audioout\""
    else
        warn "⚠️  MPD config doesn't have device \"_audioout\""
        warn "   Run: moOde Web UI → Audio Config → Apply"
    fi
fi
echo ""

# Step 7: Restart MPD
log "Step 7: Restarting MPD..."
if systemctl is-active --quiet mpd.service 2>/dev/null; then
    systemctl restart mpd.service
    sleep 3
    log "✅ MPD restarted"
    
    # Set MPD volume to safe level
    if command -v mpc >/dev/null 2>&1; then
        sleep 2
        mpc volume 20 >/dev/null 2>&1 || true
        log "✅ MPD volume set to 20%"
    fi
else
    log "MPD not running - starting it..."
    systemctl start mpd.service
    sleep 3
    if command -v mpc >/dev/null 2>&1; then
        sleep 2
        mpc volume 20 >/dev/null 2>&1 || true
    fi
    log "✅ MPD started"
fi
echo ""

log "=== Audio Fix Complete ==="
echo ""
log "Next steps:"
echo "  1. Test audio: speaker-test -c 2 -t sine -f 1000 -D plughw:$AMP100_CARD,0"
echo "  2. Check MPD status: mpc status"
echo "  3. Play a test track in moOde Web UI"
echo ""
log "If audio still doesn't work:"
echo "  - Check: cat /proc/asound/cards"
echo "  - Check: aplay -l"
echo "  - Check: systemctl status mpd"
echo "  - Check: journalctl -u mpd -n 50"
echo ""
