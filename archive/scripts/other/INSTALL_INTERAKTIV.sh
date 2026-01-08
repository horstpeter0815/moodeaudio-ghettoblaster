#!/bin/bash
# INTERAKTIVE INSTALLATION - Fragt Passwort ab

set -e

PI1="192.168.178.62"
PI2="192.168.178.134"
USER="andre"

echo "=========================================="
echo "  INTERAKTIVE INSTALLATION"
echo "  Ansatz 1 - FT6236 Delay Service"
echo "=========================================="
echo ""

# Ask for password
read -sp "SSH Passwort für beide Pis: " PASSWORD
echo ""

# Function to install with password
install_pi() {
    local IP=$1
    local NAME=$2
    
    echo "📋 $NAME ($IP)"
    echo ""
    
    echo "1. Scripts kopieren..."
    sshpass -p "$PASSWORD" scp -o StrictHostKeyChecking=no FINAL_OPTIMIZED_INSTALL.sh verify_installation.sh ${USER}@${IP}:~/ 2>&1 || {
        echo "⚠️  Script-Kopie fehlgeschlagen"
        return 1
    }
    echo "✅ Scripts kopiert"
    
    echo "2. Installation ausführen..."
    sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no ${USER}@${IP} "chmod +x ~/FINAL_OPTIMIZED_INSTALL.sh ~/verify_installation.sh && sudo -S bash ~/FINAL_OPTIMIZED_INSTALL.sh" <<< "$PASSWORD" 2>&1 || {
        echo "⚠️  Installation fehlgeschlagen"
        return 1
    }
    echo "✅ Installation erfolgreich"
    echo ""
}

# Install Pi 1
echo "🖥️  PI 1: RaspiOS"
install_pi $PI1 "RaspiOS"

# Install Pi 2
echo "🎵 PI 2: moOde"
install_pi $PI2 "moOde"

echo "=========================================="
echo "✅ INSTALLATION ABGESCHLOSSEN"
echo "=========================================="
echo ""
echo "📋 NÄCHSTE SCHRITTE:"
echo "   Auf beiden Pis: sudo reboot"
echo "   Nach Reboot: sudo bash ~/verify_installation.sh"
echo ""

