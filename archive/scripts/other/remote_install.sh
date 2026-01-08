#!/bin/bash
# Remote Installation Script
# Versucht, Installation auf beiden Pis durchzuführen

set -e

PI1="192.168.178.62"
PI2="192.168.178.178"
USER="andre"

echo "=========================================="
echo "  REMOTE INSTALLATION - ANSATZ 1"
echo "  Installation auf beiden Pis"
echo "=========================================="
echo ""

# Function to install on Pi
install_on_pi() {
    local PI_IP=$1
    local PI_NAME=$2
    
    echo "📋 Installiere auf $PI_NAME ($PI_IP)..."
    echo ""
    
    # Try to copy script
    echo "1. Script kopieren..."
    if scp -o StrictHostKeyChecking=no -o ConnectTimeout=5 MASTER_INSTALL.sh ${USER}@${PI_IP}:~/ 2>/dev/null; then
        echo "✅ Script kopiert"
    else
        echo "⚠️  Script-Kopie fehlgeschlagen (SSH benötigt Passwort/Key)"
        echo "   Bitte manuell kopieren:"
        echo "   scp MASTER_INSTALL.sh ${USER}@${PI_IP}:~/"
        return 1
    fi
    
    # Try to execute
    echo "2. Script ausführen..."
    if ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 ${USER}@${PI_IP} "sudo bash ~/MASTER_INSTALL.sh" 2>/dev/null; then
        echo "✅ Installation erfolgreich"
        return 0
    else
        echo "⚠️  Remote-Ausführung fehlgeschlagen (SSH benötigt Passwort/Key)"
        echo "   Bitte manuell ausführen auf $PI_NAME:"
        echo "   ssh ${USER}@${PI_IP}"
        echo "   sudo bash ~/MASTER_INSTALL.sh"
        return 1
    fi
}

# Install on Pi 1
echo "🖥️  PHASE 1: RaspiOS (Pi 1)"
install_on_pi $PI1 "RaspiOS"
echo ""

# Install on Pi 2
echo "🎵 PHASE 2: moOde Audio (Pi 2)"
install_on_pi $PI2 "moOde"
echo ""

echo "=========================================="
echo "✅ INSTALLATION VERSUCH ABGESCHLOSSEN"
echo "=========================================="
echo ""
echo "📋 Falls Remote-Installation fehlgeschlagen:"
echo "   1. Scripts manuell auf Pis kopieren"
echo "   2. Auf jedem Pi: sudo bash MASTER_INSTALL.sh"
echo "   3. Reboot: sudo reboot"
echo ""

