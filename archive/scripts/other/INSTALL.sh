#!/bin/bash
# INSTALLATION - Passwort als Argument

set -e

if [ -z "$1" ]; then
    echo "Usage: ./INSTALL.sh <ssh-password>"
    exit 1
fi

PASSWORD=$1
PI1="192.168.178.62"
PI2="192.168.178.134"
USER="andre"

echo "=========================================="
echo "  INSTALLATION STARTET"
echo "=========================================="
echo ""

install_pi() {
    local IP=$1
    local NAME=$2
    
    echo "📋 $NAME ($IP)"
    sshpass -p "$PASSWORD" scp -o StrictHostKeyChecking=no FINAL_OPTIMIZED_INSTALL.sh verify_installation.sh ${USER}@${IP}:~/
    sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no ${USER}@${IP} "chmod +x ~/FINAL_OPTIMIZED_INSTALL.sh ~/verify_installation.sh && echo '$PASSWORD' | sudo -S bash ~/FINAL_OPTIMIZED_INSTALL.sh"
    echo "✅ $NAME fertig"
    echo ""
}

install_pi $PI1 "RaspiOS"
install_pi $PI2 "moOde"

echo "✅ Installation abgeschlossen!"
echo "Reboot: sshpass -p '$PASSWORD' ssh andre@$PI1 'sudo reboot'"
echo "Reboot: sshpass -p '$PASSWORD' ssh andre@$PI2 'sudo reboot'"

