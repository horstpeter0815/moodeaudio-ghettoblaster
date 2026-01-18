#!/bin/bash
# Validate Audio Chain for HiFiBerry AMP100
# Quick diagnostic script to check if audio is configured correctly

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[OK]${NC} $*"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $*"
}

error() {
    echo -e "${RED}[ERROR]${NC} $*"
}

info() {
    echo -e "${BLUE}[INFO]${NC} $*"
}

echo "================================================"
echo "  Audio Chain Validation for HiFiBerry AMP100"
echo "================================================"
echo ""

# Check if running on Pi
if [ ! -d "/proc/asound" ]; then
    error "Not running on Pi - /proc/asound not found"
    exit 1
fi

# Step 1: Check AMP100 detection
info "Step 1: Checking AMP100 detection..."
if grep -q "sndrpihifiberry\|HiFiBerry AMP100" /proc/asound/cards 2>/dev/null; then
    AMP100_CARD=$(grep -E "sndrpihifiberry|HiFiBerry AMP100" /proc/asound/cards | head -1 | awk '{print $1}' || echo "")
    log "AMP100 detected as card $AMP100_CARD"
    cat /proc/asound/cards | grep -E "sndrpihifiberry|HiFiBerry AMP100" | sed 's/^/  /'
else
    error "AMP100 not detected!"
    echo "  Check:"
    echo "    - dtoverlay=hifiberry-amp100 in /boot/firmware/config.txt"
    echo "    - Reboot required after overlay changes"
    echo "    - Hardware connection"
    exit 1
fi

echo ""

# Step 2: Check aplay
info "Step 2: Checking aplay -l..."
if command -v aplay >/dev/null 2>&1; then
    if aplay -l 2>/dev/null | grep -q "card $AMP100_CARD.*sndrpihifiberry\|HiFiBerry AMP100"; then
        log "AMP100 found in aplay -l"
        aplay -l 2>/dev/null | grep -E "card $AMP100_CARD|sndrpihifiberry|HiFiBerry AMP100" | sed 's/^/  /'
    else
        warn "AMP100 not found in aplay -l"
    fi
else
    warn "aplay command not found"
fi

echo ""

# Step 3: Check moOde database
info "Step 3: Checking moOde database configuration..."
MOODE_DB="/var/local/www/db/moode-sqlite3.db"
if [ -f "$MOODE_DB" ]; then
    DB_CARD=$(sqlite3 "$MOODE_DB" "SELECT value FROM cfg_system WHERE param='cardnum';" 2>/dev/null || echo "")
    DB_I2S=$(sqlite3 "$MOODE_DB" "SELECT value FROM cfg_system WHERE param='i2sdevice';" 2>/dev/null || echo "")
    MPD_DEVICE=$(sqlite3 "$MOODE_DB" "SELECT value FROM cfg_mpd WHERE param='device';" 2>/dev/null || echo "")
    
    if [ "$DB_CARD" = "$AMP100_CARD" ]; then
        log "Database cardnum matches: $DB_CARD"
    else
        warn "Database cardnum mismatch: DB=$DB_CARD, Actual=$AMP100_CARD"
    fi
    
    if [ "$MPD_DEVICE" = "$AMP100_CARD" ]; then
        log "MPD device matches: $MPD_DEVICE"
    else
        warn "MPD device mismatch: DB=$MPD_DEVICE, Actual=$AMP100_CARD"
    fi
    
    if [ "$DB_I2S" = "HiFiBerry AMP100" ]; then
        log "I2S device configured: $DB_I2S"
    else
        warn "I2S device not set correctly: $DB_I2S"
    fi
else
    warn "moOde database not found"
fi

echo ""

# Step 4: Check ALSA _audioout.conf
info "Step 4: Checking ALSA _audioout.conf..."
AUDIOOUT_CONF="/etc/alsa/conf.d/_audioout.conf"
if [ -f "$AUDIOOUT_CONF" ]; then
    CURRENT_DEVICE=$(grep "slave.pcm" "$AUDIOOUT_CONF" | sed 's/.*"\(.*\)".*/\1/' || echo "")
    EXPECTED_DEVICE="plughw:$AMP100_CARD,0"
    
    if [ "$CURRENT_DEVICE" = "$EXPECTED_DEVICE" ]; then
        log "_audioout.conf correctly configured: $CURRENT_DEVICE"
    else
        warn "_audioout.conf mismatch: Current=$CURRENT_DEVICE, Expected=$EXPECTED_DEVICE"
    fi
else
    error "_audioout.conf not found!"
fi

echo ""

# Step 5: Check MPD status
info "Step 5: Checking MPD status..."
if systemctl is-active --quiet mpd.service 2>/dev/null; then
    log "MPD is running"
    
    if command -v mpc >/dev/null 2>&1; then
        MPD_VOLUME=$(mpc volume 2>/dev/null | grep -oE "[0-9]+%" || echo "")
        if [ -n "$MPD_VOLUME" ]; then
            log "MPD volume: $MPD_VOLUME"
        else
            warn "Could not get MPD volume"
        fi
        
        MPD_OUTPUTS=$(mpc outputs 2>/dev/null | grep -A 1 "ALSA Default" | grep -q "enabled" && echo "enabled" || echo "disabled")
        if [ "$MPD_OUTPUTS" = "enabled" ]; then
            log "MPD ALSA Default output: enabled"
        else
            warn "MPD ALSA Default output: disabled"
        fi
    else
        warn "mpc command not found"
    fi
else
    error "MPD is not running!"
    echo "  Start with: sudo systemctl start mpd"
fi

echo ""

# Step 6: Check volume/mute state
info "Step 6: Checking volume/mute state..."
if command -v amixer >/dev/null 2>&1; then
    MASTER_MUTE=$(amixer -c "$AMP100_CARD" sget Master 2>/dev/null | grep -oE "\[off\]|\[on\]" | head -1 || echo "")
    PCM_MUTE=$(amixer -c "$AMP100_CARD" sget PCM 2>/dev/null | grep -oE "\[off\]|\[on\]" | head -1 || echo "")
    
    if [ "$MASTER_MUTE" = "[on]" ]; then
        log "Master: unmuted"
    else
        warn "Master: muted ($MASTER_MUTE)"
    fi
    
    if [ "$PCM_MUTE" = "[on]" ]; then
        log "PCM: unmuted"
    else
        warn "PCM: muted ($PCM_MUTE)"
    fi
else
    warn "amixer command not found"
fi

echo ""

# Step 7: Test audio device
info "Step 7: Testing audio device..."
if command -v speaker-test >/dev/null 2>&1; then
    echo "  Run this command to test audio:"
    echo "    speaker-test -c 2 -t sine -f 1000 -D plughw:$AMP100_CARD,0"
    echo "  (Press Ctrl+C to stop)"
else
    warn "speaker-test command not found"
fi

echo ""
echo "================================================"
echo "  Validation Complete"
echo "================================================"
echo ""
echo "If issues found, run:"
echo "  cd ~/moodeaudio-cursor && ./tools/fix.sh --audio"
echo "  or"
echo "  sudo /usr/local/bin/fix-audio-chain.sh"
