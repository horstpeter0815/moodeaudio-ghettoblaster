#!/bin/bash
# Comprehensive diagnostic for volume and filter issues
# Run this on the moOde system

DB="/var/local/www/db/moode-sqlite3.db"
CONFIG="/usr/share/camilladsp/configs/bose_wave_filters.yml"

echo "=== Volume & Filter Diagnostic ==="
echo ""

# 1. Current state
echo "1. Current Configuration"
echo "--------------------------------------------"
CURRENT_CDSP=$(sqlite3 "$DB" "SELECT value FROM cfg_system WHERE param = 'camilladsp';" 2>/dev/null)
MIXER_TYPE=$(sqlite3 "$DB" "SELECT value FROM cfg_mpd WHERE param = 'mixer_type';" 2>/dev/null)
ALSA_VOLUME=$(sqlite3 "$DB" "SELECT value FROM cfg_system WHERE param = 'alsavolume';" 2>/dev/null)
VOLUME_SYNC=$(sqlite3 "$DB" "SELECT value FROM cfg_system WHERE param = 'camilladsp_volume_sync';" 2>/dev/null)

echo "CamillaDSP config: ${CURRENT_CDSP:-<none>}"
echo "MPD mixer type: ${MIXER_TYPE:-<none>}"
echo "ALSA volume: ${ALSA_VOLUME:-<none>}"
echo "CDSP volume sync: ${VOLUME_SYNC:-<none>}"
echo ""

# 2. Volume levels
echo "2. Current Volume Levels"
echo "--------------------------------------------"
if [ "$MIXER_TYPE" = "null" ] || [ "$MIXER_TYPE" = "camilladsp" ]; then
    echo "CamillaDSP volume:"
    if [ -f "/var/lib/cdsp/statefile.yml" ]; then
        CDSP_VOL=$(grep "volume" /var/lib/cdsp/statefile.yml | grep -v "^#" | head -1 | awk '{print $2}')
        echo "  CDSP volume: ${CDSP_VOL:-<not set>}"
    else
        echo "  CDSP statefile not found"
    fi
    echo "  MPD volume: $(mpc volume 2>/dev/null | awk '{print $2}')"
else
    echo "Hardware/Software volume:"
    echo "  MPD volume: $(mpc volume 2>/dev/null | awk '{print $2}')"
    if [ -n "$ALSA_VOLUME" ] && [ "$ALSA_VOLUME" != "none" ]; then
        ALSA_VOL=$(amixer -c $(sqlite3 "$DB" "SELECT value FROM cfg_system WHERE param = 'cardnum';") get "$ALSA_VOLUME" 2>/dev/null | grep -oP '\d+%' | head -1)
        echo "  ALSA volume: ${ALSA_VOL:-<cannot read>}"
    fi
fi
echo ""

# 3. CamillaDSP status
echo "3. CamillaDSP Status"
echo "--------------------------------------------"
if pgrep camilladsp > /dev/null; then
    CDSP_PID=$(pgrep camilladsp)
    echo "✓ Running (PID: $CDSP_PID)"
    
    # Check if it's actually processing
    echo "Process info:"
    ps aux | grep camilladsp | grep -v grep | head -1 | sed 's/^/  /'
    
    # Check config file being used
    CONFIG_IN_USE=$(ps aux | grep camilladsp | grep -oP '\-c\s+\S+' | awk '{print $2}' | head -1)
    echo "Config file: ${CONFIG_IN_USE:-<not found in process>}"
    
    # Check recent logs
    echo ""
    echo "Recent logs:"
    journalctl _PID=$CDSP_PID -n 10 --no-pager 2>&1 | tail -5 | sed 's/^/  /' || echo "  (no logs)"
else
    echo "✗ NOT running"
fi
echo ""

# 4. Filter configuration
echo "4. Filter Configuration"
echo "--------------------------------------------"
if [ -f "$CONFIG" ]; then
    echo "Config file: $CONFIG"
    
    # Count filters
    FILTER_COUNT=$(grep -c "^  band_" "$CONFIG" 2>/dev/null || echo "0")
    echo "Number of filter bands: $FILTER_COUNT"
    
    # Check pipeline
    echo ""
    echo "Pipeline structure:"
    grep -A 2 "^pipeline:" "$CONFIG" | head -10 | sed 's/^/  /'
    
    # Validate config
    echo ""
    echo "Config validation:"
    camilladsp -c "$CONFIG" 2>&1 | head -3 | sed 's/^/  /'
else
    echo "✗ Config file not found"
fi
echo ""

# 5. MPD configuration
echo "5. MPD Configuration"
echo "--------------------------------------------"
MPD_CONF="/var/lib/mpd/mpd.conf"
if [ -f "$MPD_CONF" ]; then
    echo "Audio output:"
    awk '/^audio_output/,/^}/' "$MPD_CONF" | grep -E "type|name|device|mixer" | sed 's/^/  /'
    
    MPD_MIXER=$(grep -A 5 "^audio_output" "$MPD_CONF" | grep "mixer_control" | awk '{print $2}' | tr -d '"')
    echo ""
    echo "MPD mixer control: ${MPD_MIXER:-<not set>}"
else
    echo "✗ MPD config not found"
fi
echo ""

# 6. Volume sync service
echo "6. Volume Sync Service"
echo "--------------------------------------------"
if systemctl is-active mpd2cdspvolume > /dev/null 2>&1; then
    echo "✓ mpd2cdspvolume is active"
    systemctl status mpd2cdspvolume --no-pager -l | head -5 | sed 's/^/  /'
else
    echo "✗ mpd2cdspvolume is NOT active"
    if [ "$MIXER_TYPE" = "null" ]; then
        echo "  ⚠ Should be active when mixer_type is 'null'"
    fi
fi
echo ""

# 7. Recommendations
echo "7. Analysis & Recommendations"
echo "--------------------------------------------"
ISSUES=0

if [ "$CURRENT_CDSP" != "off" ] && [ "$MIXER_TYPE" != "null" ]; then
    echo "⚠ CamillaDSP is ON but mixer_type is '$MIXER_TYPE' (should be 'null')"
    echo "  → Mixer needs to be switched to CamillaDSP volume"
    ISSUES=$((ISSUES + 1))
fi

if [ "$CURRENT_CDSP" != "off" ] && ! pgrep camilladsp > /dev/null; then
    echo "⚠ CamillaDSP is configured but NOT running"
    echo "  → CamillaDSP should start when audio plays"
    ISSUES=$((ISSUES + 1))
fi

if [ "$MIXER_TYPE" = "null" ] && ! systemctl is-active mpd2cdspvolume > /dev/null 2>&1; then
    echo "⚠ Mixer is 'null' but mpd2cdspvolume service is not active"
    echo "  → Volume sync service should be running"
    ISSUES=$((ISSUES + 1))
fi

if [ $ISSUES -eq 0 ]; then
    echo "✓ Configuration looks correct"
    echo ""
    echo "If filters aren't working:"
    echo "  - Check if audio is actually playing through CamillaDSP"
    echo "  - Verify filter gains are reasonable (some are +30dB which is very high)"
    echo "  - Check CamillaDSP logs for processing errors"
fi

echo ""
echo "=== Diagnostic Complete ==="

