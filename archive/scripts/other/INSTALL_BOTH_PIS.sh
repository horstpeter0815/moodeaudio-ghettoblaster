#!/bin/bash
# INSTALLATION AUF BEIDEN PIS - ANSATZ 1
# Installiert FT6236 Delay Service auf beiden Pis automatisch

set -e

# IPs der Pis
PI1_IP="192.168.178.62"  # RaspiOS
PI2_IP="192.168.178.178" # moOde
USER="andre"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo "=========================================="
echo "  INSTALLATION AUF BEIDEN PIS"
echo "  Ansatz 1 - FT6236 Delay Service"
echo "=========================================="
echo ""

# Function to install on Pi
install_on_pi() {
    local PI_IP=$1
    local PI_NAME=$2
    
    echo -e "${GREEN}📋 Installiere auf $PI_NAME ($PI_IP)...${NC}"
    
    # Copy script
    echo "  1. Script kopieren..."
    if scp -o StrictHostKeyChecking=no -o ConnectTimeout=5 FINAL_OPTIMIZED_INSTALL.sh ${USER}@${PI_IP}:~/ 2>/dev/null; then
        echo -e "  ${GREEN}✅ Script kopiert${NC}"
    else
        echo -e "  ${YELLOW}⚠️  Script-Kopie fehlgeschlagen (SSH benötigt Passwort)${NC}"
        echo "     Bitte manuell kopieren: scp FINAL_OPTIMIZED_INSTALL.sh ${USER}@${PI_IP}:~/"
        return 1
    fi
    
    # Execute script
    echo "  2. Installation ausführen..."
    if ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 ${USER}@${PI_IP} "sudo bash ~/FINAL_OPTIMIZED_INSTALL.sh" 2>/dev/null; then
        echo -e "  ${GREEN}✅ Installation erfolgreich${NC}"
        return 0
    else
        echo -e "  ${YELLOW}⚠️  Remote-Ausführung fehlgeschlagen (SSH benötigt Passwort)${NC}"
        echo "     Bitte manuell ausführen auf $PI_NAME:"
        echo "     ssh ${USER}@${PI_IP}"
        echo "     sudo bash ~/FINAL_OPTIMIZED_INSTALL.sh"
        return 1
    fi
}

# Install on Pi 1
echo -e "${GREEN}🖥️  PHASE 1: RaspiOS (Pi 1)${NC}"
install_on_pi $PI1_IP "RaspiOS"
echo ""

# Install on Pi 2
echo -e "${GREEN}🎵 PHASE 2: moOde Audio (Pi 2)${NC}"
install_on_pi $PI2_IP "moOde"
echo ""

echo "=========================================="
echo -e "${GREEN}✅ INSTALLATION ABGESCHLOSSEN${NC}"
echo "=========================================="
echo ""
echo -e "${YELLOW}📋 NÄCHSTE SCHRITTE:${NC}"
echo "  1. Auf beiden Pis: ${GREEN}sudo reboot${NC}"
echo "  2. Nach Reboot: ${GREEN}sudo bash ~/verify_installation.sh${NC}"
echo ""

