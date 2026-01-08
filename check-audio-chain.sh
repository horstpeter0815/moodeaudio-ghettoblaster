#!/bin/bash
# Audio Chain Diagnostic Script for moOde
# Run this on the moOde system

echo "================================================"
echo "  moOde Audio Chain Diagnostic"
echo "================================================"
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Initialize variables
CURRENT_CDSP=""
CARD_NUM=""

echo "1. MPD Status"
echo "--------------------------------------------"
if pgrep -x mpd > /dev/null; then
    echo -e "${GREEN}✓${NC} MPD running (PID: $(pgrep -x mpd))"
    mpd --version 2>/dev/null | head -1
else
    echo -e "${RED}✗${NC} MPD NOT running"
fi
echo ""

echo "2. CamillaDSP Status"
echo "--------------------------------------------"
if pgrep camilladsp > /dev/null; then
    echo -e "${GREEN}✓${NC} CamillaDSP running (PID: $(pgrep camilladsp))"
    camilladsp --version 2>/dev/null
else
    echo -e "${YELLOW}⚠${NC} CamillaDSP NOT running"
fi
echo ""

echo "3. MPD Configuration"
echo "--------------------------------------------"
MPD_CONF="/var/lib/mpd/mpd.conf"
if [ -f "$MPD_CONF" ]; then
    echo "Audio outputs:"
    awk '/^audio_output/,/^}/' "$MPD_CONF" | grep -E "type|name|device|format" | sed 's/^/  /'
else
    echo -e "${RED}✗${NC} MPD config not found"
fi
echo ""

echo "4. CamillaDSP Configuration"
echo "--------------------------------------------"
CDSP_CONFIG_DIR="/usr/share/camilladsp/configs"
if [ -d "$CDSP_CONFIG_DIR" ]; then
    echo "Available configs:"
    ls -1 "$CDSP_CONFIG_DIR"/*.yml 2>/dev/null | sed 's|.*/||' | sed 's/^/  /' || echo "  (none)"
    
    if [ -f "$CDSP_CONFIG_DIR/bose_wave_filters.yml" ]; then
        echo ""
        echo -e "${GREEN}✓${NC} Bose Wave filters found!"
        ls -lh "$CDSP_CONFIG_DIR/bose_wave_filters.yml" | awk '{print "  " $9 " (" $5 ")"}'
    else
        echo ""
        echo -e "${YELLOW}⚠${NC} Bose Wave filters NOT found"
    fi
else
    echo -e "${RED}✗${NC} Config directory not found"
fi
echo ""

echo "5. Active Configuration (from moOde database)"
echo "--------------------------------------------"
MOODE_DB="/var/local/www/db/moode-sqlite3.db"
if [ -f "$MOODE_DB" ]; then
    CURRENT_CDSP=$(sqlite3 "$MOODE_DB" "SELECT value FROM cfg_system WHERE param = 'camilladsp';" 2>/dev/null)
    CARD_NUM=$(sqlite3 "$MOODE_DB" "SELECT value FROM cfg_system WHERE param = 'cardnum';" 2>/dev/null)
    
    echo "CamillaDSP config: ${CURRENT_CDSP:-<not set>}"
    if [ "$CURRENT_CDSP" = "bose_wave_filters.yml" ]; then
        echo -e "${GREEN}✓${NC} Bose Wave filters are ACTIVE"
    elif [ "$CURRENT_CDSP" = "off" ] || [ -z "$CURRENT_CDSP" ]; then
        echo -e "${YELLOW}⚠${NC} CamillaDSP is OFF"
    fi
    
    echo "Audio card: ${CARD_NUM:-<not set>}"
else
    echo -e "${RED}✗${NC} Database not found"
fi
echo ""

echo "6. Audio Devices"
echo "--------------------------------------------"
if [ -d "/proc/asound" ]; then
    echo "Available cards:"
    cat /proc/asound/cards 2>/dev/null | sed 's/^/  /' || echo "  (none)"
else
    echo -e "${RED}✗${NC} /proc/asound not available"
fi
echo ""

echo "7. Audio Chain Summary"
echo "--------------------------------------------"
echo "Current audio path:"
echo ""
echo "  Music File"
echo "    ↓"
echo "  MPD (Music Player Daemon)"

if [ "$CURRENT_CDSP" != "off" ] && [ -n "$CURRENT_CDSP" ]; then
    echo -e "    ↓ ${BLUE}(via pipe or ALSA)${NC}"
    echo -e "  ${GREEN}CamillaDSP${NC} [${CURRENT_CDSP}]"
    if [ "$CURRENT_CDSP" = "bose_wave_filters.yml" ]; then
        echo -e "    ${GREEN}→ Applying Bose Wave filters${NC}"
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

echo "================================================"
echo -e "${BLUE}Recommendations:${NC}"
if [ "$CURRENT_CDSP" != "bose_wave_filters.yml" ]; then
    echo "  1. Enable CamillaDSP in moOde Web UI"
    echo "  2. Select 'bose_wave_filters.yml' as the config"
    echo "  3. Apply and restart if needed"
fi
if [ ! -f "$CDSP_CONFIG_DIR/bose_wave_filters.yml" ]; then
    echo "  - Install bose_wave_filters.yml to $CDSP_CONFIG_DIR"
fi
echo ""
