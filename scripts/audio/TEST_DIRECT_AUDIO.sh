#!/bin/bash
################################################################################
#
# Test Direct Audio Configuration
#
# Tests each step of the direct audio chain (MPD → AMP100)
# Stops at first failure with clear error message
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

log() { echo -e "${GREEN}[TEST]${NC} $1"; }
error() { echo -e "${RED}[FAIL]${NC} $1" >&2; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
info() { echo -e "${BLUE}[INFO]${NC} $1"; }

# Check if running on Pi
if [ ! -d "/proc/asound" ]; then
    error "Not running on Pi - cannot test audio"
    exit 1
fi

FAILED=0

test_step() {
    local step_num=$1
    local step_name=$2
    local test_cmd=$3
    
    echo ""
    log "Step $step_num: $step_name"
    if eval "$test_cmd" >/dev/null 2>&1; then
        log "✅ Step $step_num PASSED"
        return 0
    else
        error "❌ Step $step_num FAILED: $step_name"
        return 1
    fi
}

echo "=========================================="
log "Testing Direct Audio Configuration"
echo "=========================================="

# Step 1: Boot Configuration
test_step 1 "Boot config (hifiberry-amp100)" \
    "grep -q 'hifiberry-amp100' /boot/firmware/config.txt" || FAILED=1

test_step 1 "Boot config (i2s=on)" \
    "grep -q 'i2s=on' /boot/firmware/config.txt" || FAILED=1

test_step 1 "Boot config (audio=off)" \
    "grep -q 'audio=off' /boot/firmware/config.txt" || FAILED=1

# Step 2: Hardware Detection
if test_step 2 "AMP100 hardware detection" \
    "grep -qi 'hifiberry\|sndrpihifiberry' /proc/asound/cards"; then
    AMP100_CARD=$(grep -E "sndrpihifiberry|HiFiBerry AMP100" /proc/asound/cards | head -1 | awk '{print $1}' || echo "")
    if [ -n "$AMP100_CARD" ]; then
        info "AMP100 detected as card $AMP100_CARD"
    fi
else
    FAILED=1
fi

# Step 3: ALSA Device
test_step 3 "ALSA device listing" \
    "aplay -l 2>/dev/null | grep -qi hifiberry" || FAILED=1

# Step 4: Database Configuration
test_step 4 "Database cardnum" \
    "[ \"\$(sqlite3 /var/local/www/db/moode-sqlite3.db \"SELECT value FROM cfg_system WHERE param='cardnum';\" 2>/dev/null)\" != \"\" ]" || FAILED=1

test_step 4 "Database i2sdevice" \
    "sqlite3 /var/local/www/db/moode-sqlite3.db \"SELECT value FROM cfg_system WHERE param='i2sdevice';\" 2>/dev/null | grep -qi 'hifiberry\|amp100'" || FAILED=1

test_step 4 "Database peppy_display OFF" \
    "[ \"\$(sqlite3 /var/local/www/db/moode-sqlite3.db \"SELECT value FROM cfg_system WHERE param='peppy_display';\" 2>/dev/null)\" = \"0\" ]" || FAILED=1

test_step 4 "Database camilladsp OFF" \
    "[ \"\$(sqlite3 /var/local/www/db/moode-sqlite3.db \"SELECT value FROM cfg_system WHERE param='camilladsp';\" 2>/dev/null)\" = \"off\" ]" || FAILED=1

test_step 4 "Database MPD device" \
    "[ \"\$(sqlite3 /var/local/www/db/moode-sqlite3.db \"SELECT value FROM cfg_mpd WHERE param='device';\" 2>/dev/null)\" = \"_audioout\" ]" || FAILED=1

# Step 5: ALSA Configuration
test_step 5 "_audioout.conf exists" \
    "[ -f /etc/alsa/conf.d/_audioout.conf ]" || FAILED=1

test_step 5 "_audioout.conf routes to plughw" \
    "grep -q 'slave.pcm.*plughw' /etc/alsa/conf.d/_audioout.conf" || FAILED=1

# Step 6: MPD Status
test_step 6 "MPD service running" \
    "systemctl is-active mpd >/dev/null 2>&1" || FAILED=1

# Step 7: Audio Output Test (non-blocking)
if [ "$FAILED" -eq 0 ]; then
    echo ""
    info "All configuration tests passed!"
    info "To test audio output, run:"
    echo "  speaker-test -c 2 -t sine -f 1000 -D _audioout"
    echo "  (Press Ctrl+C to stop)"
    echo ""
    info "Or test with MPD:"
    echo "  mpc play"
    echo "  mpc status"
else
    echo ""
    error "Some tests failed. Fix issues before proceeding."
    echo ""
    info "Run fix script:"
    echo "  cd ~/moodeaudio-cursor && sudo bash scripts/audio/FIX_DIRECT_AUDIO.sh"
    exit 1
fi

exit 0
