#!/bin/bash
# INSTALLATION DIREKT AUSFÜHREN
# Führt Installation auf beiden Pis durch (benötigt SSH-Passwort)

set -e

PI1="192.168.178.62"
PI2="192.168.178.134"
USER="andre"

echo "=========================================="
echo "  INSTALLATION DIREKT AUSFÜHREN"
echo "  Ansatz 1 - FT6236 Delay Service"
echo "=========================================="
echo ""

# Function to install
install_pi() {
    local IP=$1
    local NAME=$2
    
    echo "📋 $NAME ($IP)"
    echo ""
    
    echo "1. Scripts kopieren..."
    scp FINAL_OPTIMIZED_INSTALL.sh verify_installation.sh ${USER}@${IP}:~/ || {
        echo "⚠️  Script-Kopie fehlgeschlagen - bitte manuell kopieren"
        return 1
    }
    
    echo "2. Installation ausführen..."
    ssh ${USER}@${IP} "chmod +x ~/FINAL_OPTIMIZED_INSTALL.sh ~/verify_installation.sh && sudo bash ~/FINAL_OPTIMIZED_INSTALL.sh" || {
        echo "⚠️  Installation fehlgeschlagen - bitte manuell ausführen"
        return 1
    }
    
    echo "✅ $NAME Installation erfolgreich"
    echo ""
}

# Install Pi 1
echo "🖥️  PI 1: RaspiOS"
install_pi $PI1 "RaspiOS"
echo ""

# Install Pi 2
echo "🎵 PI 2: moOde"
install_pi $PI2 "moOde"
echo ""

echo "=========================================="
echo "✅ INSTALLATION ABGESCHLOSSEN"
echo "=========================================="
echo ""
echo "📋 NÄCHSTE SCHRITTE:"
echo "   Auf beiden Pis: sudo reboot"
echo "   Nach Reboot: sudo bash ~/verify_installation.sh"
echo ""

