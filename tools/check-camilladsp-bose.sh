#!/bin/bash
# Check CamillaDSP and Bose filters configuration
# Run this on the Raspberry Pi

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${GREEN}[OK]${NC} $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*"; }
info() { echo -e "${BLUE}[INFO]${NC} $*"; }

if [ ! -d "/proc/asound" ]; then
    error "Not running on Pi"
    exit 1
fi

echo "================================================"
echo "  CamillaDSP & Bose Filters Configuration Check"
echo "================================================"
echo ""

# Step 1: Check CamillaDSP database setting
info "Step 1: Checking CamillaDSP database setting..."
MOODE_DB="/var/local/www/db/moode-sqlite3.db"
if [ -f "$MOODE_DB" ]; then
    CAMILLADSP_MODE=$(sqlite3 "$MOODE_DB" "SELECT value FROM cfg_system WHERE param='camilladsp';" 2>/dev/null || echo "")
    CAMILLADSP_CONFIG=$(sqlite3 "$MOODE_DB" "SELECT value FROM cfg_system WHERE param='cdsp_config';" 2>/dev/null || echo "")
    
    if [ "$CAMILLADSP_MODE" = "on" ]; then
        log "CamillaDSP is enabled in database"
    else
        warn "CamillaDSP is not enabled in database (current: '$CAMILLADSP_MODE')"
    fi
    
    if [ -n "$CAMILLADSP_CONFIG" ]; then
        info "CamillaDSP config: $CAMILLADSP_CONFIG"
        if echo "$CAMILLADSP_CONFIG" | grep -qi "bose"; then
            log "✅ Bose filters configured: $CAMILLADSP_CONFIG"
        else
            warn "CamillaDSP config doesn't mention Bose: $CAMILLADSP_CONFIG"
        fi
    else
        warn "CamillaDSP config not set in database"
    fi
else
    error "moOde database not found"
fi
echo ""

# Step 2: Check ALSA routing
info "Step 2: Checking ALSA routing..."
AUDIOOUT_CONF="/etc/alsa/conf.d/_audioout.conf"
if [ -f "$AUDIOOUT_CONF" ]; then
    CURRENT_DEVICE=$(grep "slave.pcm" "$AUDIOOUT_CONF" 2>/dev/null | sed 's/.*"\(.*\)".*/\1/' || echo "")
    if [ "$CURRENT_DEVICE" = "camilladsp" ]; then
        log "✅ _audioout.conf routes through CamillaDSP: $CURRENT_DEVICE"
    else
        warn "_audioout.conf routes to: $CURRENT_DEVICE (should be 'camilladsp')"
    fi
else
    error "_audioout.conf not found"
fi
echo ""

# Step 3: Check CamillaDSP config file
info "Step 3: Checking CamillaDSP configuration file..."
CAMILLA_CONFIG="/usr/share/camilladsp/working_config.yml"
if [ -f "$CAMILLA_CONFIG" ]; then
    log "✅ CamillaDSP config file exists: $CAMILLA_CONFIG"
    
    # Check for Bose in config
    if grep -qi "bose" "$CAMILLA_CONFIG" 2>/dev/null; then
        log "✅ Bose mentioned in CamillaDSP config"
        echo "   Bose references:"
        grep -i "bose" "$CAMILLA_CONFIG" | head -5 | sed 's/^/     /'
    else
        warn "⚠️  No Bose reference found in CamillaDSP config"
    fi
    
    # Check output device
    OUTPUT_DEVICE=$(grep -A 1 "^device:" "$CAMILLA_CONFIG" 2>/dev/null | grep -v "^device:" | sed 's/.*"\(.*\)".*/\1/' | head -1 || echo "")
    if [ -n "$OUTPUT_DEVICE" ]; then
        info "Output device: $OUTPUT_DEVICE"
        if echo "$OUTPUT_DEVICE" | grep -q "sndrpihifiberry\|plughw:1"; then
            log "✅ Output device points to HiFiBerry"
        else
            warn "Output device may not be HiFiBerry: $OUTPUT_DEVICE"
        fi
    fi
    
    # Check filters/pipeline
    if grep -q "pipeline:" "$CAMILLA_CONFIG" 2>/dev/null; then
        log "✅ Pipeline section found in config"
        PIPELINE_LINES=$(grep -A 20 "^pipeline:" "$CAMILLA_CONFIG" | wc -l)
        info "Pipeline has $PIPELINE_LINES lines (should have multiple filter stages for Bose)"
    else
        warn "Pipeline section not found"
    fi
else
    warn "⚠️  CamillaDSP config file not found: $CAMILLA_CONFIG"
fi
echo ""

# Step 4: Check CamillaDSP service
info "Step 4: Checking CamillaDSP service..."
if systemctl is-active --quiet camilladsp.service 2>/dev/null; then
    log "✅ CamillaDSP service is running"
    
    # Check service status
    if systemctl status camilladsp.service --no-pager -l 2>/dev/null | grep -q "Active: active"; then
        log "✅ CamillaDSP service is active"
    fi
else
    warn "⚠️  CamillaDSP service is NOT running"
    info "   Starting CamillaDSP service..."
    systemctl start camilladsp.service 2>/dev/null && log "✅ Started" || warn "   Failed to start"
fi
echo ""

# Step 5: Check MPD configuration
info "Step 5: Checking MPD configuration..."
MPD_CONF="/etc/mpd.conf"
if [ -f "$MPD_CONF" ]; then
    if grep -q 'device "_audioout"' "$MPD_CONF" 2>/dev/null; then
        log "✅ MPD config uses device \"_audioout\" (routes through CamillaDSP)"
    else
        MPD_DEVICE=$(grep "device " "$MPD_CONF" 2>/dev/null | head -1 || echo "")
        warn "MPD device: $MPD_DEVICE (should be '_audioout')"
    fi
else
    warn "MPD config file not found"
fi

# Check MPD status
if systemctl is-active --quiet mpd.service 2>/dev/null; then
    log "✅ MPD service is running"
else
    warn "⚠️  MPD service is NOT running"
fi
echo ""

# Step 6: Check audio card
info "Step 6: Checking audio hardware..."
if grep -q "sndrpihifiberry\|HiFiBerry" /proc/asound/cards 2>/dev/null; then
    AMP100_CARD=$(grep -E "sndrpihifiberry|HiFiBerry" /proc/asound/cards | head -1 | awk '{print $1}' || echo "")
    log "✅ HiFiBerry detected as card $AMP100_CARD"
else
    error "HiFiBerry not detected!"
fi
echo ""

# Step 7: Check for Bose filter files
info "Step 7: Checking for Bose filter files..."
BOSE_CONFIGS=$(find /usr/share/camilladsp/configs -name "*bose*" -type f 2>/dev/null || echo "")
if [ -n "$BOSE_CONFIGS" ]; then
    log "✅ Bose filter config files found:"
    echo "$BOSE_CONFIGS" | sed 's/^/     /'
else
    warn "⚠️  No Bose filter config files found in /usr/share/camilladsp/configs/"
fi
echo ""

# Summary
echo "================================================"
echo "  Summary"
echo "================================================"
echo ""

# Check if everything is configured correctly
ALL_GOOD=true

if [ "$CAMILLADSP_MODE" != "on" ]; then
    warn "❌ CamillaDSP not enabled in database"
    ALL_GOOD=false
fi

if [ "$CURRENT_DEVICE" != "camilladsp" ]; then
    warn "❌ ALSA not routing through CamillaDSP"
    ALL_GOOD=false
fi

if [ ! -f "$CAMILLA_CONFIG" ]; then
    warn "❌ CamillaDSP config file missing"
    ALL_GOOD=false
fi

if ! systemctl is-active --quiet camilladsp.service 2>/dev/null; then
    warn "❌ CamillaDSP service not running"
    ALL_GOOD=false
fi

if ! systemctl is-active --quiet mpd.service 2>/dev/null; then
    warn "❌ MPD service not running"
    ALL_GOOD=false
fi

if [ "$ALL_GOOD" = true ]; then
    log "✅ All checks passed! Audio should be working with CamillaDSP"
    if echo "$CAMILLADSP_CONFIG" | grep -qi "bose"; then
        log "✅ Bose filters are configured"
    else
        warn "⚠️  Bose filters may not be applied (check config file)"
    fi
    echo ""
    info "Audio chain: MPD → _audioout → camilladsp → HiFiBerry"
    echo ""
    info "To test audio, play a track in moOde Web UI"
else
    warn "⚠️  Some issues found - please review above"
fi
echo ""
