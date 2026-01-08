#!/bin/bash
# Verification Script - Prüft Installation nach Reboot
# OPTIMIERT - Morgen um 10 Uhr fertig!

set -e
set -u

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "=========================================="
echo "  VERIFIKATION - ANSATZ 1 INSTALLATION"
echo "=========================================="
echo ""

SUCCESS=0
FAILURES=0

# Check 1: Service Status
echo "1. Service-Status prüfen..."
if systemctl is-enabled --quiet ft6236-delay.service; then
    echo -e "${GREEN}✅ ft6236-delay.service ist aktiviert${NC}"
    ((SUCCESS++))
else
    echo -e "${RED}❌ ft6236-delay.service ist NICHT aktiviert${NC}"
    ((FAILURES++))
fi

if systemctl is-active --quiet ft6236-delay.service; then
    echo -e "${GREEN}✅ ft6236-delay.service ist aktiv${NC}"
    ((SUCCESS++))
else
    echo -e "${YELLOW}⚠️  ft6236-delay.service ist nicht aktiv (normal nach Reboot)${NC}"
fi
echo ""

# Check 2: FT6236 Module
echo "2. FT6236 Modul prüfen..."
if lsmod | grep -q ft6236; then
    echo -e "${GREEN}✅ FT6236 Modul ist geladen${NC}"
    lsmod | grep ft6236
    ((SUCCESS++))
else
    echo -e "${YELLOW}⚠️  FT6236 Modul ist noch nicht geladen${NC}"
    echo "   (Wird nach 3 Sekunden geladen, wenn Display bereit ist)"
fi
echo ""

# Check 3: Touchscreen Device
echo "3. Touchscreen-Device prüfen..."
if ls /dev/input/event* 2>/dev/null | head -1 > /dev/null; then
    echo -e "${GREEN}✅ Touchscreen-Devices gefunden:${NC}"
    ls -la /dev/input/event* 2>/dev/null | head -5
    ((SUCCESS++))
else
    echo -e "${YELLOW}⚠️  Keine Touchscreen-Devices gefunden${NC}"
fi
echo ""

# Check 4: Display Service
echo "4. Display-Service prüfen..."
if systemctl is-active --quiet localdisplay.service; then
    echo -e "${GREEN}✅ localdisplay.service ist aktiv${NC}"
    ((SUCCESS++))
else
    echo -e "${YELLOW}⚠️  localdisplay.service ist nicht aktiv${NC}"
fi
echo ""

# Check 5: Config.txt
echo "5. config.txt prüfen..."
if grep -q "^#dtoverlay=ft6236" /boot/firmware/config.txt 2>/dev/null || grep -q "^#dtoverlay=ft6236" /boot/config.txt 2>/dev/null; then
    echo -e "${GREEN}✅ FT6236 Overlay ist auskommentiert${NC}"
    ((SUCCESS++))
else
    echo -e "${RED}❌ FT6236 Overlay ist NICHT auskommentiert${NC}"
    ((FAILURES++))
fi
echo ""

# Check 6: X Server (if running)
echo "6. X Server prüfen..."
if pgrep -x Xorg > /dev/null; then
    echo -e "${GREEN}✅ X Server läuft${NC}"
    ((SUCCESS++))
else
    echo -e "${YELLOW}⚠️  X Server läuft nicht${NC}"
fi
echo ""

# Check 7: Audio (moOde only)
if [ -f /etc/moode-release ] || systemctl list-units | grep -q "mpd.service"; then
    echo "7. Audio-Service prüfen (moOde)..."
    if systemctl is-active --quiet mpd.service; then
        echo -e "${GREEN}✅ mpd.service ist aktiv (Audio funktioniert)${NC}"
        ((SUCCESS++))
    else
        echo -e "${YELLOW}⚠️  mpd.service ist nicht aktiv${NC}"
    fi
    echo ""
fi

# Summary
echo "=========================================="
echo "  ZUSAMMENFASSUNG"
echo "=========================================="
echo -e "${GREEN}✅ Erfolgreiche Checks: $SUCCESS${NC}"
if [ $FAILURES -gt 0 ]; then
    echo -e "${RED}❌ Fehlgeschlagene Checks: $FAILURES${NC}"
else
    echo -e "${GREEN}✅ Keine Fehler${NC}"
fi
echo ""

if [ $FAILURES -eq 0 ]; then
    echo -e "${GREEN}✅ INSTALLATION ERFOLGREICH!${NC}"
    exit 0
else
    echo -e "${YELLOW}⚠️  Einige Checks fehlgeschlagen - bitte prüfen${NC}"
    exit 1
fi

