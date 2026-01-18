#!/bin/bash
################################################################################
#
# Check Audio Chain Configuration
#
# Verifies audio chain is configured correctly according to V1.0 working config
#
################################################################################

set -euo pipefail

log() { echo -e "\033[0;32m[CHECK]${NC} $1"; }
info() { echo -e "\033[0;34m[INFO]${NC} $1"; }
warn() { echo -e "\033[0;33m[WARN]${NC} $1"; }
error() { echo -e "\033[0;31m[ERROR]${NC} $1" >&2; }

echo "=== Audio Chain Check ==="
echo ""

# 1. Check AMP100 detection
echo "1. AMP100 Detection:"
if [ -d "/proc/asound" ]; then
    if grep -q "sndrpihifiberry\|HiFiBerry AMP100" /proc/asound/cards 2>/dev/null; then
        AMP100_CARD=$(grep -E "sndrpihifiberry|HiFiBerry AMP100" /proc/asound/cards | head -1 | awk '{print $1}')
        AMP100_NAME=$(grep -E "sndrpihifiberry|HiFiBerry AMP100" /proc/asound/cards | head -1 | sed 's/^[0-9]*: //')
        echo "  ✅ AMP100 detected: Card $AMP100_CARD - $AMP100_NAME"
    else
        error "  ❌ AMP100 not detected!"
        echo "  Check hardware connection and config.txt"
    fi
    echo ""
    echo "  All audio cards:"
    cat /proc/asound/cards
else
    error "  ❌ /proc/asound not available (not running on Pi?)"
fi

echo ""

# 2. Check moOde database
echo "2. moOde Database Configuration:"
MOODE_DB="/var/local/www/db/moode-sqlite3.db"
if [ -f "$MOODE_DB" ]; then
    CARDNUM=$(sqlite3 "$MOODE_DB" "SELECT value FROM cfg_system WHERE param='cardnum';" 2>/dev/null || echo "")
    I2SDEVICE=$(sqlite3 "$MOODE_DB" "SELECT value FROM cfg_system WHERE param='i2sdevice';" 2>/dev/null || echo "")
    PEPPY_DISPLAY=$(sqlite3 "$MOODE_DB" "SELECT value FROM cfg_system WHERE param='peppy_display';" 2>/dev/null || echo "")
    VOLUME_CONTROL=$(sqlite3 "$MOODE_DB" "SELECT value FROM cfg_system WHERE param='volume_control';" 2>/dev/null || echo "")
    MPD_DEVICE=$(sqlite3 "$MOODE_DB" "SELECT value FROM cfg_mpd WHERE param='device';" 2>/dev/null || echo "")
    
    echo "  cardnum: $CARDNUM"
    echo "  i2sdevice: $I2SDEVICE"
    echo "  peppy_display: $PEPPY_DISPLAY"
    echo "  volume_control: $VOLUME_CONTROL"
    echo "  mpd device: $MPD_DEVICE"
    
    if [ "$CARDNUM" = "$AMP100_CARD" ] 2>/dev/null; then
        echo "  ✅ Card number matches AMP100"
    else
        warn "  ⚠️  Card number mismatch"
    fi
else
    warn "  ⚠️  Database not found (may not be initialized yet)"
fi

echo ""

# 3. Check ALSA configuration
echo "3. ALSA Configuration:"
if [ -f /etc/alsa/conf.d/_audioout.conf ]; then
    echo "  _audioout.conf:"
    cat /etc/alsa/conf.d/_audioout.conf | sed 's/^/    /'
    echo ""
else
    warn "  ⚠️  _audioout.conf not found"
fi

if [ -f /etc/alsa/conf.d/_peppyout.conf ]; then
    echo "  _peppyout.conf:"
    cat /etc/alsa/conf.d/_peppyout.conf | sed 's/^/    /'
    echo ""
else
    warn "  ⚠️  _peppyout.conf not found"
fi

# 4. Check MPD status
echo "4. MPD Status:"
if systemctl is-active --quiet mpd 2>/dev/null; then
    echo "  ✅ MPD is running"
    if command -v mpc >/dev/null 2>&1; then
        echo "  MPD outputs:"
        mpc outputs 2>/dev/null | sed 's/^/    /' || echo "    (could not check)"
    fi
else
    warn "  ⚠️  MPD is not running"
fi

echo ""

# 5. Check PeppyMeter
echo "5. PeppyMeter Configuration:"
if systemctl is-enabled --quiet peppymeter 2>/dev/null; then
    if systemctl is-active --quiet peppymeter 2>/dev/null; then
        echo "  ⚠️  PeppyMeter service is ENABLED and RUNNING"
        echo "  ⚠️  This may cause white screen if not playing audio!"
    else
        echo "  ✅ PeppyMeter service is enabled but stopped (OK)"
    fi
else
    echo "  ✅ PeppyMeter service is disabled (OK for moOde UI)"
fi

if [ -f /etc/peppymeter/config.txt ]; then
    echo "  Config file exists"
    METER_FOLDER=$(grep "^meter.folder" /etc/peppymeter/config.txt 2>/dev/null | cut -d= -f2 | tr -d ' ' || echo "")
    SCREEN_WIDTH=$(grep "^screen.width" /etc/peppymeter/config.txt 2>/dev/null | cut -d= -f2 | tr -d ' ' || echo "")
    SCREEN_HEIGHT=$(grep "^screen.height" /etc/peppymeter/config.txt 2>/dev/null | cut -d= -f2 | tr -d ' ' || echo "")
    echo "    meter.folder: $METER_FOLDER"
    echo "    screen.width: $SCREEN_WIDTH"
    echo "    screen.height: $SCREEN_HEIGHT"
    if [ "$SCREEN_WIDTH" = "1280" ] && [ "$SCREEN_HEIGHT" = "400" ]; then
        echo "  ✅ Screen size correct (1280x400)"
    else
        warn "  ⚠️  Screen size may be wrong"
    fi
else
    warn "  ⚠️  PeppyMeter config not found"
fi

echo ""

# 6. Audio device check (NO test playback)
echo "6. Audio Device Check:"
if [ -n "${AMP100_CARD:-}" ]; then
    echo "  AMP100 card: $AMP100_CARD"
    echo "  ⚠️  NO automatic test - you will test manually"
    echo "  ⚠️  Start with: mpc volume 0 (then increase gradually)"
fi

echo ""
echo "=== Summary ==="
echo ""
echo "Expected configuration (from V1.0 working config):"
echo "  - AMP100 as card 0 (or detected card)"
echo "  - MPD device: _audioout"
echo "  - ALSA chain: MPD → _audioout → peppy → _peppyout → AMP100"
echo "  - PeppyMeter: Disabled by default (to avoid white screen)"
echo "  - Software volume: Enabled"
echo ""
