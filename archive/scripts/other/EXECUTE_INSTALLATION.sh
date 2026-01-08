#!/bin/bash
set -e

PI1="192.168.178.62"
PI2="192.168.178.134"
USER="andre"

echo "=========================================="
echo "  INSTALLATION - AUTOMATISCH"
echo "=========================================="
echo ""

# Get password once
read -sp "SSH Passwort: " PASSWORD
echo ""
export SSHPASS="$PASSWORD"

# Function to install
install_pi() {
    local IP=$1
    local NAME=$2
    
    echo "📋 $NAME ($IP)"
    
    # Copy scripts
    echo "  → Kopiere Scripts..."
    sshpass -e scp -o StrictHostKeyChecking=no FINAL_OPTIMIZED_INSTALL.sh verify_installation.sh ${USER}@${IP}:~/ 2>&1
    
    # Execute installation
    echo "  → Führe Installation aus..."
    sshpass -e ssh -o StrictHostKeyChecking=no ${USER}@${IP} "chmod +x ~/FINAL_OPTIMIZED_INSTALL.sh ~/verify_installation.sh && echo '$PASSWORD' | sudo -S bash ~/FINAL_OPTIMIZED_INSTALL.sh" 2>&1
    
    echo "  ✅ $NAME fertig"
    echo ""
}

# Install both
install_pi $PI1 "RaspiOS"
install_pi $PI2 "moOde"

echo "=========================================="
echo "✅ INSTALLATION ABGESCHLOSSEN"
echo "=========================================="
echo ""
echo "📋 Reboot durchführen:"
echo "   sshpass -e ssh andre@$PI1 'echo '$PASSWORD' | sudo -S reboot'"
echo "   sshpass -e ssh andre@$PI2 'echo '$PASSWORD' | sudo -S reboot'"
echo ""

