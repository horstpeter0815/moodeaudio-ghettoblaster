#!/bin/bash
# MASTER INSTALLATION SCRIPT - ANSATZ 1
# Universal Script für beide Pis (RaspiOS & moOde)
# Automatische Erkennung und Installation

set -e  # Exit on error
set -u  # Exit on undefined variable

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "=========================================="
echo "  MASTER INSTALLATION - ANSATZ 1"
echo "  FT6236 Delay Service Implementation"
echo "=========================================="
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}❌ Bitte mit sudo ausführen:${NC}"
    echo "   sudo bash MASTER_INSTALL.sh"
    exit 1
fi

# Detect which Pi we're on
PI_TYPE="UNKNOWN"
PI_NAME="Unknown"
PI_IP="Unknown"

if [ -f /etc/moode-release ] || [ -d /var/www/html ] || systemctl list-units | grep -q "mpd.service"; then
    PI_TYPE="MOODE"
    PI_NAME="Pi 2 (moOde Audio)"
    PI_IP="192.168.178.178"
    echo -e "${GREEN}🔍 Erkannt: $PI_NAME${NC}"
elif [ -f /etc/os-release ] && grep -q "Raspberry Pi OS" /etc/os-release; then
    PI_TYPE="RASPIOS"
    PI_NAME="Pi 1 (RaspiOS)"
    PI_IP="192.168.178.62"
    echo -e "${GREEN}🔍 Erkannt: $PI_NAME${NC}"
else
    echo -e "${YELLOW}⚠️  Pi-Typ nicht eindeutig erkannt, verwende Standard-Konfiguration${NC}"
    PI_TYPE="STANDARD"
    PI_NAME="Standard Pi"
fi

echo ""

# Find config.txt location
CONFIG_FILE=""
if [ -f /boot/firmware/config.txt ]; then
    CONFIG_FILE="/boot/firmware/config.txt"
elif [ -f /boot/config.txt ]; then
    CONFIG_FILE="/boot/config.txt"
else
    echo -e "${RED}❌ config.txt nicht gefunden!${NC}"
    exit 1
fi

echo -e "${GREEN}📋 SCHRITT 1: Backup config.txt erstellen...${NC}"
BACKUP_FILE="${CONFIG_FILE}.backup-$(date +%Y%m%d-%H%M%S)"
cp "$CONFIG_FILE" "$BACKUP_FILE"
echo -e "${GREEN}✅ Backup erstellt: $BACKUP_FILE${NC}"
echo ""

echo -e "${GREEN}📋 SCHRITT 2: FT6236 Overlay auskommentieren...${NC}"
if grep -q "^dtoverlay=ft6236" "$CONFIG_FILE"; then
    sed -i 's/^dtoverlay=ft6236/#dtoverlay=ft6236/' "$CONFIG_FILE"
    echo -e "${GREEN}✅ FT6236 Overlay auskommentiert${NC}"
elif grep -q "^#dtoverlay=ft6236" "$CONFIG_FILE"; then
    echo -e "${YELLOW}⚠️  FT6236 Overlay ist bereits auskommentiert${NC}"
else
    echo -e "${YELLOW}⚠️  FT6236 Overlay nicht in config.txt gefunden (wird übersprungen)${NC}"
fi
echo ""

echo -e "${GREEN}📋 SCHRITT 3: systemd-Service erstellen...${NC}"
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

echo -e "${GREEN}✅ Service-Datei erstellt: /etc/systemd/system/ft6236-delay.service${NC}"
echo ""

echo -e "${GREEN}📋 SCHRITT 4: Service aktivieren...${NC}"
systemctl daemon-reload
systemctl enable ft6236-delay.service
echo -e "${GREEN}✅ Service aktiviert${NC}"
echo ""

echo -e "${GREEN}📋 SCHRITT 5: Service starten (Test)...${NC}"
systemctl start ft6236-delay.service
sleep 2
echo -e "${GREEN}✅ Service gestartet${NC}"
echo ""

echo -e "${GREEN}📋 SCHRITT 6: Verifikation...${NC}"
echo ""

echo "Service-Status:"
if systemctl is-active --quiet ft6236-delay.service; then
    echo -e "${GREEN}✅ ft6236-delay.service ist aktiv${NC}"
else
    echo -e "${YELLOW}⚠️  ft6236-delay.service Status unklar${NC}"
fi
systemctl status ft6236-delay.service --no-pager -l | head -15 || true
echo ""

echo "FT6236 Modul:"
if lsmod | grep -q ft6236; then
    echo -e "${GREEN}✅ FT6236 Modul ist geladen${NC}"
    lsmod | grep ft6236
else
    echo -e "${YELLOW}⚠️  FT6236 Modul ist noch nicht geladen (wird nach 3 Sekunden geladen)${NC}"
fi
echo ""

echo "Touchscreen-Devices:"
if ls /dev/input/event* 2>/dev/null | head -1 > /dev/null; then
    echo -e "${GREEN}✅ Touchscreen-Devices gefunden:${NC}"
    ls -la /dev/input/event* 2>/dev/null | head -5
else
    echo -e "${YELLOW}⚠️  Noch keine Touchscreen-Devices gefunden${NC}"
fi
echo ""

if [ "$PI_TYPE" = "MOODE" ]; then
    echo "localdisplay.service Status:"
    if systemctl is-active --quiet localdisplay.service; then
        echo -e "${GREEN}✅ localdisplay.service ist aktiv${NC}"
    else
        echo -e "${YELLOW}⚠️  localdisplay.service ist nicht aktiv${NC}"
    fi
    echo ""
    
    echo "mpd.service Status (Audio):"
    if systemctl is-active --quiet mpd.service; then
        echo -e "${GREEN}✅ mpd.service ist aktiv (Audio funktioniert)${NC}"
    else
        echo -e "${YELLOW}⚠️  mpd.service ist nicht aktiv${NC}"
    fi
    echo ""
fi

echo "=========================================="
echo -e "${GREEN}✅ INSTALLATION ABGESCHLOSSEN${NC}"
echo "=========================================="
echo ""
echo -e "${GREEN}📋 NÄCHSTE SCHRITTE:${NC}"
echo "   1. Reboot durchführen: ${YELLOW}sudo reboot${NC}"
echo "   2. Nach Reboot prüfen:"
echo "      - Display funktioniert?"
echo "      - Touchscreen funktioniert nach 3 Sekunden?"
echo "      - Keine X Server Crashes?"
if [ "$PI_TYPE" = "MOODE" ]; then
    echo "      - Audio funktioniert weiterhin?"
fi
echo ""
echo -e "${GREEN}📋 ROLLBACK (falls nötig):${NC}"
echo "   sudo systemctl disable ft6236-delay.service"
echo "   sudo systemctl stop ft6236-delay.service"
echo "   sudo cp $BACKUP_FILE $CONFIG_FILE"
echo "   sudo reboot"
echo ""
echo -e "${GREEN}📊 Backup-Datei: $BACKUP_FILE${NC}"
echo ""
