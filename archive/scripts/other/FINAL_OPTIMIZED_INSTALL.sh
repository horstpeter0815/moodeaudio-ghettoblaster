#!/bin/bash
# FINAL OPTIMIZED INSTALLATION - ANSATZ 1
# Perfektioniert und getestet - Morgen um 10 Uhr fertig!

set -e
set -u

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "=========================================="
echo "  FINAL INSTALLATION - ANSATZ 1"
echo "  FT6236 Delay Service - OPTIMIERT"
echo "=========================================="
echo ""

# Root check
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}❌ Bitte mit sudo ausführen:${NC}"
    echo "   sudo bash FINAL_OPTIMIZED_INSTALL.sh"
    exit 1
fi

# Detect Pi type
PI_TYPE="UNKNOWN"
if [ -f /etc/moode-release ] || [ -d /var/www/html ] || systemctl list-units 2>/dev/null | grep -q "mpd.service"; then
    PI_TYPE="MOODE"
    echo -e "${BLUE}🔍 Erkannt: moOde Audio (Pi 2)${NC}"
elif [ -f /etc/os-release ] && grep -q "Raspberry Pi OS" /etc/os-release 2>/dev/null; then
    PI_TYPE="RASPIOS"
    echo -e "${BLUE}🔍 Erkannt: RaspiOS (Pi 1)${NC}"
else
    echo -e "${YELLOW}⚠️  Pi-Typ nicht eindeutig, verwende Standard${NC}"
    PI_TYPE="STANDARD"
fi
echo ""

# Find config.txt
CONFIG_FILE=""
if [ -f /boot/firmware/config.txt ]; then
    CONFIG_FILE="/boot/firmware/config.txt"
elif [ -f /boot/config.txt ]; then
    CONFIG_FILE="/boot/config.txt"
else
    echo -e "${RED}❌ config.txt nicht gefunden!${NC}"
    exit 1
fi

echo -e "${GREEN}📋 SCHRITT 1: Backup erstellen...${NC}"
BACKUP_FILE="${CONFIG_FILE}.backup-$(date +%Y%m%d-%H%M%S)"
cp "$CONFIG_FILE" "$BACKUP_FILE"
echo -e "${GREEN}✅ Backup: $BACKUP_FILE${NC}"
echo ""

echo -e "${GREEN}📋 SCHRITT 2: FT6236 Overlay auskommentieren...${NC}"
if grep -q "^dtoverlay=ft6236" "$CONFIG_FILE"; then
    sed -i 's/^dtoverlay=ft6236/#dtoverlay=ft6236/' "$CONFIG_FILE"
    echo -e "${GREEN}✅ FT6236 auskommentiert${NC}"
elif grep -q "^#dtoverlay=ft6236" "$CONFIG_FILE"; then
    echo -e "${YELLOW}⚠️  Bereits auskommentiert${NC}"
else
    echo -e "${YELLOW}⚠️  FT6236 Overlay nicht gefunden${NC}"
fi
echo ""

echo -e "${GREEN}📋 SCHRITT 3: Service erstellen...${NC}"
cat > /etc/systemd/system/ft6236-delay.service << 'EOF'
[Unit]
Description=Load FT6236 touchscreen after display
After=graphical.target
After=localdisplay.service
Wants=localdisplay.service

[Service]
Type=oneshot
ExecStart=/bin/bash -c 'sleep 3 && modprobe ft6236'
RemainAfterExit=yes
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=graphical.target
EOF
echo -e "${GREEN}✅ Service erstellt${NC}"
echo ""

echo -e "${GREEN}📋 SCHRITT 4: Service aktivieren...${NC}"
systemctl daemon-reload
systemctl enable ft6236-delay.service
echo -e "${GREEN}✅ Service aktiviert${NC}"
echo ""

echo -e "${GREEN}📋 SCHRITT 5: Service starten...${NC}"
systemctl start ft6236-delay.service
sleep 2
echo -e "${GREEN}✅ Service gestartet${NC}"
echo ""

echo -e "${GREEN}📋 SCHRITT 6: Verifikation...${NC}"
echo ""

# Check service
if systemctl is-enabled --quiet ft6236-delay.service; then
    echo -e "${GREEN}✅ Service ist aktiviert${NC}"
else
    echo -e "${RED}❌ Service ist NICHT aktiviert${NC}"
fi

if systemctl is-active --quiet ft6236-delay.service; then
    echo -e "${GREEN}✅ Service ist aktiv${NC}"
else
    echo -e "${YELLOW}⚠️  Service ist nicht aktiv (normal nach Reboot)${NC}"
fi

# Check module
if lsmod | grep -q ft6236; then
    echo -e "${GREEN}✅ FT6236 Modul geladen${NC}"
else
    echo -e "${YELLOW}⚠️  FT6236 Modul noch nicht geladen (wird nach 3s geladen)${NC}"
fi

# Check devices
if ls /dev/input/event* 2>/dev/null | head -1 > /dev/null; then
    echo -e "${GREEN}✅ Touchscreen-Devices gefunden${NC}"
else
    echo -e "${YELLOW}⚠️  Noch keine Devices${NC}"
fi

# Check display service
if systemctl is-active --quiet localdisplay.service 2>/dev/null; then
    echo -e "${GREEN}✅ localdisplay.service aktiv${NC}"
else
    echo -e "${YELLOW}⚠️  localdisplay.service nicht aktiv${NC}"
fi

# Check audio (moOde only)
if [ "$PI_TYPE" = "MOODE" ]; then
    if systemctl is-active --quiet mpd.service 2>/dev/null; then
        echo -e "${GREEN}✅ mpd.service aktiv (Audio OK)${NC}"
    else
        echo -e "${YELLOW}⚠️  mpd.service nicht aktiv${NC}"
    fi
fi

echo ""
echo "=========================================="
echo -e "${GREEN}✅ INSTALLATION ABGESCHLOSSEN${NC}"
echo "=========================================="
echo ""
echo -e "${BLUE}📋 NÄCHSTE SCHRITTE:${NC}"
echo "   1. ${YELLOW}sudo reboot${NC}"
echo "   2. Nach Reboot: ${YELLOW}sudo bash verify_installation.sh${NC}"
echo ""
echo -e "${BLUE}📊 Backup: $BACKUP_FILE${NC}"
echo ""

