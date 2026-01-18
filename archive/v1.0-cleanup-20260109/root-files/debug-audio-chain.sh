#!/bin/bash
# Comprehensive Audio Chain Debug Script for moOde
# Run this on the moOde system

LOG_FILE="/tmp/audio_debug.log"
rm -f "$LOG_FILE"

log() {
    echo "[$(date +%H:%M:%S)] $*" | tee -a "$LOG_FILE"
}

log "=== Audio Chain Debug Session Started ==="
log ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "================================================"
echo "  moOde Audio Chain Debug"
echo "================================================"
echo "Logging to: $LOG_FILE"
echo ""

log "1. MPD Status Check"
echo "1. MPD Status"
echo "--------------------------------------------"
if pgrep -x mpd > /dev/null; then
    MPD_PID=$(pgrep -x mpd)
    echo -e "${GREEN}✓${NC} MPD running (PID: $MPD_PID)"
    log "MPD_PID=$MPD_PID"
    mpd --version 2>/dev/null | head -1 | tee -a "$LOG_FILE"
    
    # Check MPD state
    MPD_STATE=$(mpc status 2>/dev/null | head -1)
    log "MPD_STATE=$MPD_STATE"
    echo "  Current state: $MPD_STATE"
else
    echo -e "${RED}✗${NC} MPD NOT running"
    log "MPD_STATUS=NOT_RUNNING"
fi
echo ""

log "2. CamillaDSP Status Check"
echo "2. CamillaDSP Status"
echo "--------------------------------------------"
if pgrep camilladsp > /dev/null; then
    CDSP_PID=$(pgrep camilladsp)
    echo -e "${GREEN}✓${NC} CamillaDSP running (PID: $CDSP_PID)"
    log "CDSP_PID=$CDSP_PID"
    camilladsp --version 2>/dev/null | tee -a "$LOG_FILE"
    
    # Check if CamillaDSP is actually processing
    CDSP_PROCESSES=$(ps aux | grep camilladsp | grep -v grep | wc -l)
    log "CDSP_PROCESSES=$CDSP_PROCESSES"
    
    # Check CamillaDSP logs
    if [ -f /var/log/camilladsp.log ]; then
        echo "  Recent CamillaDSP logs:"
        tail -20 /var/log/camilladsp.log | tee -a "$LOG_FILE"
    fi
else
    echo -e "${RED}✗${NC} CamillaDSP NOT running"
    log "CDSP_STATUS=NOT_RUNNING"
fi
echo ""

log "3. MPD Configuration Check"
echo "3. MPD Configuration"
echo "--------------------------------------------"
MPD_CONF="/var/lib/mpd/mpd.conf"
if [ -f "$MPD_CONF" ]; then
    echo "MPD config found: $MPD_CONF"
    log "MPD_CONF_EXISTS=yes"
    
    echo "Audio outputs configured:"
    awk '/^audio_output/,/^}/' "$MPD_CONF" | grep -E "type|name|device|format" | sed 's/^/  /' | tee -a "$LOG_FILE"
    
    # Check output type
    OUTPUT_TYPE=$(grep -A 5 "^audio_output" "$MPD_CONF" | grep "type" | awk '{print $2}' | tr -d '"')
    log "MPD_OUTPUT_TYPE=$OUTPUT_TYPE"
    
    # Check if using pipe (CamillaDSP)
    if grep -q 'type.*pipe' "$MPD_CONF"; then
        PIPE_CMD=$(grep -A 5 "^audio_output" "$MPD_CONF" | grep "command" | cut -d'"' -f2)
        log "MPD_PIPE_CMD=$PIPE_CMD"
        echo "  Pipe command: $PIPE_CMD"
    fi
else
    echo -e "${RED}✗${NC} MPD config not found"
    log "MPD_CONF_EXISTS=no"
fi
echo ""

log "4. CamillaDSP Configuration Check"
echo "4. CamillaDSP Configuration"
echo "--------------------------------------------"
MOODE_DB="/var/local/www/db/moode-sqlite3.db"
if [ -f "$MOODE_DB" ]; then
    CURRENT_CDSP=$(sqlite3 "$MOODE_DB" "SELECT value FROM cfg_system WHERE param = 'camilladsp';" 2>/dev/null)
    CARD_NUM=$(sqlite3 "$MOODE_DB" "SELECT value FROM cfg_system WHERE param = 'cardnum';" 2>/dev/null)
    ALSA_MODE=$(sqlite3 "$MOODE_DB" "SELECT value FROM cfg_system WHERE param = 'alsa_output_mode';" 2>/dev/null)
    
    log "CURRENT_CDSP=$CURRENT_CDSP"
    log "CARD_NUM=$CARD_NUM"
    log "ALSA_MODE=$ALSA_MODE"
    
    echo "Active CamillaDSP config: ${CURRENT_CDSP:-<not set>}"
    echo "Audio card: ${CARD_NUM:-<not set>}"
    echo "ALSA mode: ${ALSA_MODE:-<not set>}"
    
    CDSP_CONFIG_DIR="/usr/share/camilladsp/configs"
    if [ -f "$CDSP_CONFIG_DIR/$CURRENT_CDSP" ]; then
        echo -e "${GREEN}✓${NC} Config file exists"
        log "CDSP_CONFIG_EXISTS=yes"
        
        # Validate config
        echo "Validating config..."
        VALIDATION=$(camilladsp -c "$CDSP_CONFIG_DIR/$CURRENT_CDSP" 2>&1)
        echo "$VALIDATION" | tee -a "$LOG_FILE"
        if echo "$VALIDATION" | grep -q "Config is valid"; then
            log "CDSP_CONFIG_VALID=yes"
        else
            log "CDSP_CONFIG_VALID=no"
            echo -e "${RED}✗${NC} Config validation failed!"
        fi
        
        # Check config content
        echo ""
        echo "Config preview (devices section):"
        grep -A 10 "^devices:" "$CDSP_CONFIG_DIR/$CURRENT_CDSP" | head -15 | sed 's/^/  /' | tee -a "$LOG_FILE"
    else
        echo -e "${RED}✗${NC} Config file NOT found: $CDSP_CONFIG_DIR/$CURRENT_CDSP"
        log "CDSP_CONFIG_EXISTS=no"
    fi
else
    echo -e "${RED}✗${NC} Database not found"
    log "MOODE_DB_EXISTS=no"
fi
echo ""

log "5. ALSA Configuration Check"
echo "5. ALSA Configuration"
echo "--------------------------------------------"
ALSA_AUDIOOUT="/etc/alsa/conf.d/_audioout.conf"
if [ -f "$ALSA_AUDIOOUT" ]; then
    echo "ALSA audio output config:"
    cat "$ALSA_AUDIOOUT" | tee -a "$LOG_FILE" | sed 's/^/  /'
else
    echo -e "${YELLOW}⚠${NC} ALSA audio output config not found"
    log "ALSA_AUDIOOUT_EXISTS=no"
fi

ALSA_CDSP="/etc/alsa/conf.d/camilladsp.conf"
if [ -f "$ALSA_CDSP" ]; then
    echo ""
    echo "ALSA CamillaDSP config:"
    head -30 "$ALSA_CDSP" | tee -a "$LOG_FILE" | sed 's/^/  /'
    log "ALSA_CDSP_EXISTS=yes"
else
    echo ""
    echo -e "${YELLOW}⚠${NC} ALSA CamillaDSP config not found (using pipe mode?)"
    log "ALSA_CDSP_EXISTS=no"
fi
echo ""

log "6. Audio Device Check"
echo "6. Audio Devices"
echo "--------------------------------------------"
if [ -d "/proc/asound" ]; then
    echo "Available cards:"
    cat /proc/asound/cards 2>/dev/null | tee -a "$LOG_FILE" | sed 's/^/  /'
    
    if [ -n "$CARD_NUM" ]; then
        CARD_NAME=$(cat /proc/asound/card$CARD_NUM/id 2>/dev/null || echo "unknown")
        log "CARD_NAME=$CARD_NAME"
        
        echo ""
        echo "Testing card $CARD_NUM ($CARD_NAME):"
        # Check if card is accessible
        if [ -d "/proc/asound/card$CARD_NUM" ]; then
            echo -e "${GREEN}✓${NC} Card accessible"
            log "CARD_ACCESSIBLE=yes"
        else
            echo -e "${RED}✗${NC} Card NOT accessible"
            log "CARD_ACCESSIBLE=no"
        fi
        
        # Check mixer
        MIXER=$(amixer -c $CARD_NUM 2>&1 | head -5)
        echo "Mixer info:"
        echo "$MIXER" | tee -a "$LOG_FILE" | sed 's/^/  /'
    fi
else
    echo -e "${RED}✗${NC} /proc/asound not available"
    log "PROC_ASOUND_EXISTS=no"
fi
echo ""

log "7. Process Tree Check"
echo "7. Process Tree"
echo "--------------------------------------------"
if pgrep mpd > /dev/null; then
    echo "MPD process tree:"
    pstree -p $MPD_PID 2>/dev/null | tee -a "$LOG_FILE" | sed 's/^/  /' || ps aux | grep mpd | grep -v grep | tee -a "$LOG_FILE" | sed 's/^/  /'
fi

if pgrep camilladsp > /dev/null; then
    echo ""
    echo "CamillaDSP process tree:"
    pstree -p $CDSP_PID 2>/dev/null | tee -a "$LOG_FILE" | sed 's/^/  /' || ps aux | grep camilladsp | grep -v grep | tee -a "$LOG_FILE" | sed 's/^/  /'
    
    # Check file descriptors
    echo ""
    echo "CamillaDSP file descriptors:"
    ls -la /proc/$CDSP_PID/fd/ 2>/dev/null | tee -a "$LOG_FILE" | sed 's/^/  /' || echo "  (cannot access)"
fi
echo ""

log "8. System Logs Check"
echo "8. System Logs"
echo "--------------------------------------------"
echo "Recent systemd logs for camilladsp:"
journalctl -u camilladsp -n 20 --no-pager 2>/dev/null | tee -a "$LOG_FILE" | sed 's/^/  /' || echo "  (no systemd service)"
echo ""

echo "Recent dmesg audio errors:"
dmesg | grep -i "audio\|alsa\|snd" | tail -10 | tee -a "$LOG_FILE" | sed 's/^/  /' || echo "  (none)"
echo ""

log "9. Audio Chain Summary"
echo "9. Audio Chain Summary"
echo "--------------------------------------------"
echo "Current audio path:"
echo ""
echo "  Music File"
echo "    ↓"
echo "  MPD (Music Player Daemon) [$MPD_PID]"

if [ "$CURRENT_CDSP" != "off" ] && [ -n "$CURRENT_CDSP" ]; then
    if pgrep camilladsp > /dev/null; then
        echo -e "    ↓ ${BLUE}(via pipe or ALSA)${NC}"
        echo -e "  ${GREEN}CamillaDSP${NC} [$CDSP_PID] [${CURRENT_CDSP}]"
    else
        echo -e "    ↓ ${RED}(CamillaDSP configured but NOT running!)${NC}"
        echo -e "  ${RED}CamillaDSP${NC} [NOT RUNNING] [${CURRENT_CDSP}]"
    fi
else
    echo -e "    ↓ ${YELLOW}(direct)${NC}"
fi

if [ -n "$CARD_NUM" ]; then
    CARD_NAME=$(cat /proc/asound/card$CARD_NUM/id 2>/dev/null || echo "card$CARD_NUM")
    echo "    ↓"
    echo "  ALSA Card $CARD_NUM ($CARD_NAME)"
fi
echo "    ↓"
echo "  Hardware Output"
echo ""

log "10. Potential Issues"
echo "10. Potential Issues"
echo "--------------------------------------------"
ISSUES=0

if [ "$CURRENT_CDSP" != "off" ] && [ -n "$CURRENT_CDSP" ] && ! pgrep camilladsp > /dev/null; then
    echo -e "${RED}✗${NC} CamillaDSP is configured but NOT running"
    log "ISSUE=CDSP_NOT_RUNNING"
    ISSUES=$((ISSUES + 1))
fi

if [ -n "$CURRENT_CDSP" ] && [ "$CURRENT_CDSP" != "off" ] && [ ! -f "$CDSP_CONFIG_DIR/$CURRENT_CDSP" ]; then
    echo -e "${RED}✗${NC} Config file missing: $CURRENT_CDSP"
    log "ISSUE=CONFIG_MISSING"
    ISSUES=$((ISSUES + 1))
fi

if ! pgrep mpd > /dev/null; then
    echo -e "${RED}✗${NC} MPD is not running"
    log "ISSUE=MPD_NOT_RUNNING"
    ISSUES=$((ISSUES + 1))
fi

if [ $ISSUES -eq 0 ]; then
    echo -e "${GREEN}✓${NC} No obvious issues detected"
    log "ISSUES=0"
fi
echo ""

log "=== Debug Session Complete ==="
echo ""
echo "Full log saved to: $LOG_FILE"
echo "================================================"

