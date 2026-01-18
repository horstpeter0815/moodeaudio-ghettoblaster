#!/bin/bash
# Debug CamillaDSP device configuration
# Run this on the moOde system

LOG="/tmp/cdsp_devices_debug.log"
rm -f "$LOG"
log() { echo "[$(date +%H:%M:%S)] $*" | tee -a "$LOG"; }

log "=== CamillaDSP Device Debug Started ==="

echo "=== CamillaDSP Device Configuration Debug ==="
echo "Log: $LOG"
echo ""

CONFIG_FILE="/usr/share/camilladsp/configs/bose_wave_filters.yml"
DB="/var/local/www/db/moode-sqlite3.db"

# 1. Check what moOde thinks the device should be
echo "1. moOde System Settings"
echo "--------------------------------------------"
CARD_NUM=$(sqlite3 "$DB" "SELECT value FROM cfg_system WHERE param = 'cardnum';" 2>/dev/null)
ALSA_MODE=$(sqlite3 "$DB" "SELECT value FROM cfg_system WHERE param = 'alsa_output_mode';" 2>/dev/null)
AUDIO_OUT=$(sqlite3 "$DB" "SELECT value FROM cfg_system WHERE param = 'audioout';" 2>/dev/null)
PEPPY=$(sqlite3 "$DB" "SELECT value FROM cfg_system WHERE param = 'peppy_display';" 2>/dev/null)

echo "Card number: ${CARD_NUM:-<not set>}"
echo "ALSA mode: ${ALSA_MODE:-<not set>}"
echo "Audio output: ${AUDIO_OUT:-<not set>}"
echo "Peppy display: ${PEPPY:-<not set>}"
log "CARD_NUM=$CARD_NUM"
log "ALSA_MODE=$ALSA_MODE"
log "AUDIO_OUT=$AUDIO_OUT"
log "PEPPY=$PEPPY"

# Determine expected device
if [ "$PEPPY" = "1" ]; then
    EXPECTED_DEVICE="peppy"
elif [ "$AUDIO_OUT" = "Bluetooth" ]; then
    EXPECTED_DEVICE="btstream"
elif [ "$ALSA_MODE" = "iec958" ]; then
    EXPECTED_DEVICE=$(amixer -c $CARD_NUM 2>/dev/null | grep -i "iec958\|spdif" | head -1 | awk '{print $1}' || echo "hw:$CARD_NUM,0")
else
    EXPECTED_DEVICE="${ALSA_MODE:-plughw}:${CARD_NUM:-0},0"
fi
echo "Expected device: $EXPECTED_DEVICE"
log "EXPECTED_DEVICE=$EXPECTED_DEVICE"
echo ""

# 2. Check what's in the config file
echo "2. Current Config File Settings"
echo "--------------------------------------------"
if [ -f "$CONFIG_FILE" ]; then
    echo "Capture device:"
    grep -A 5 "^  capture:" "$CONFIG_FILE" | head -6 | tee -a "$LOG" | sed 's/^/  /'
    
    echo ""
    echo "Playback device:"
    grep -A 5 "^  playback:" "$CONFIG_FILE" | head -6 | tee -a "$LOG" | sed 's/^/  /'
    
    CONFIG_CAPTURE_TYPE=$(grep -A 2 "^  capture:" "$CONFIG_FILE" | grep "type:" | awk '{print $2}')
    CONFIG_PLAYBACK_DEVICE=$(grep -A 5 "^  playback:" "$CONFIG_FILE" | grep "device:" | awk '{print $2}')
    CONFIG_PLAYBACK_FORMAT=$(grep -A 5 "^  playback:" "$CONFIG_FILE" | grep "format:" | awk '{print $2}')
    CONFIG_SAMPLERATE=$(grep "^  samplerate:" "$CONFIG_FILE" | awk '{print $2}')
    
    log "CONFIG_CAPTURE_TYPE=$CONFIG_CAPTURE_TYPE"
    log "CONFIG_PLAYBACK_DEVICE=$CONFIG_PLAYBACK_DEVICE"
    log "CONFIG_PLAYBACK_FORMAT=$CONFIG_PLAYBACK_FORMAT"
    log "CONFIG_SAMPLERATE=$CONFIG_SAMPLERATE"
else
    echo "✗ Config file not found"
    log "CONFIG_FILE_MISSING=yes"
fi
echo ""

# 3. Check ALSA device availability
echo "3. ALSA Device Availability"
echo "--------------------------------------------"
if [ -n "$CARD_NUM" ]; then
    echo "Card $CARD_NUM info:"
    cat /proc/asound/card$CARD_NUM/id 2>/dev/null | tee -a "$LOG" | sed 's/^/  /' || echo "  (cannot read)"
    
    echo ""
    echo "Testing device access:"
    
    # Test different device formats
    for DEVICE in "hw:$CARD_NUM,0" "plughw:$CARD_NUM,0" "peppy"; do
        echo "  Testing: $DEVICE"
        if [ "$DEVICE" = "peppy" ] && [ "$PEPPY" != "1" ]; then
            echo "    (skipped - peppy not enabled)"
            continue
        fi
        
        # Try to get device info
        if [ "$DEVICE" != "peppy" ] && [ "$DEVICE" != "btstream" ]; then
            aplay -D "$DEVICE" --dump-hw-params /dev/null 2>&1 | head -3 | tee -a "$LOG" | sed 's/^/    /' || echo "    (cannot access)"
        fi
    done
else
    echo "⚠ Card number not set"
fi
echo ""

# 4. Check MPD configuration
echo "4. MPD Audio Output"
echo "--------------------------------------------"
MPD_CONF="/var/lib/mpd/mpd.conf"
if [ -f "$MPD_CONF" ]; then
    echo "MPD audio output configuration:"
    awk '/^audio_output/,/^}/' "$MPD_CONF" | tee -a "$LOG" | sed 's/^/  /'
    
    MPD_OUTPUT_TYPE=$(grep -A 5 "^audio_output" "$MPD_CONF" | grep "type" | awk '{print $2}' | tr -d '"')
    log "MPD_OUTPUT_TYPE=$MPD_OUTPUT_TYPE"
    
    if [ "$MPD_OUTPUT_TYPE" = "pipe" ]; then
        MPD_PIPE_CMD=$(grep -A 5 "^audio_output" "$MPD_CONF" | grep "command" | cut -d'"' -f2)
        echo ""
        echo "Pipe command: $MPD_PIPE_CMD"
        log "MPD_PIPE_CMD=$MPD_PIPE_CMD"
    fi
else
    echo "✗ MPD config not found"
fi
echo ""

# 5. Check format compatibility
echo "5. Format Compatibility"
echo "--------------------------------------------"
if [ -n "$CARD_NUM" ]; then
    echo "Card $CARD_NUM supported formats:"
    cat /proc/asound/card$CARD_NUM/pcm0p/sub0/hw_params 2>/dev/null | tee -a "$LOG" | sed 's/^/  /' || echo "  (cannot read - device may not be in use)"
    
    echo ""
    echo "Config format: ${CONFIG_PLAYBACK_FORMAT:-<not set>}"
    echo "Config samplerate: ${CONFIG_SAMPLERATE:-<not set>}"
fi
echo ""

# 6. Check for errors
echo "6. Recent CamillaDSP Errors"
echo "--------------------------------------------"
if pgrep camilladsp > /dev/null; then
    CDSP_PID=$(pgrep camilladsp)
    echo "CamillaDSP is running (PID: $CDSP_PID)"
    echo "Recent logs:"
    journalctl _PID=$CDSP_PID -n 20 --no-pager 2>&1 | tee -a "$LOG" | sed 's/^/  /' || echo "  (no logs)"
else
    echo "CamillaDSP is NOT running"
    echo "Systemd service logs:"
    journalctl -u camilladsp -n 20 --no-pager 2>&1 | tee -a "$LOG" | sed 's/^/  /' || echo "  (no service logs)"
fi
echo ""

# 7. Recommendations
echo "7. Analysis & Recommendations"
echo "--------------------------------------------"
ISSUES=0

if [ -n "$CONFIG_PLAYBACK_DEVICE" ] && [ "$CONFIG_PLAYBACK_DEVICE" != "$EXPECTED_DEVICE" ]; then
    echo "⚠ Device mismatch detected!"
    echo "  Config has: $CONFIG_PLAYBACK_DEVICE"
    echo "  Should be: $EXPECTED_DEVICE"
    log "ISSUE=DEVICE_MISMATCH"
    ISSUES=$((ISSUES + 1))
fi

if [ "$CONFIG_CAPTURE_TYPE" != "Stdin" ]; then
    echo "⚠ Capture type should be 'Stdin' for pipe mode"
    log "ISSUE=CAPTURE_TYPE_WRONG"
    ISSUES=$((ISSUES + 1))
fi

if [ $ISSUES -eq 0 ]; then
    echo "✓ No obvious device configuration issues"
    log "ISSUES=0"
else
    echo "✗ Found $ISSUES issue(s)"
fi
echo ""

log "=== Debug Complete ==="
echo "Full log: $LOG"

