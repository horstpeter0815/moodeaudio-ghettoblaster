#!/bin/bash
# SSH-Key Setup für Pi 5
# 
# WICHTIG: Dieses Script wird auf dem MAC ausgeführt!
# Es kopiert den SSH-Key vom Mac auf den Pi 5.
#
# Einmalig ausführen, dann kann ohne Passwort gearbeitet werden

PI5_IP="192.168.178.134"
PI5_USER="andre"
PI5_PASS="0815"

echo "=== SSH-Key Setup für Pi 5 ==="
echo "IP: $PI5_IP"
echo ""

# Prüfe ob SSH-Key bereits existiert
SSH_DIR="$HOME/.ssh"
SSH_KEY="$SSH_DIR/id_rsa"

if [ ! -d "$SSH_DIR" ]; then
    mkdir -p "$SSH_DIR"
    chmod 700 "$SSH_DIR"
fi

if [ ! -f "$SSH_KEY" ]; then
    echo "Erstelle SSH-Key..."
    ssh-keygen -t rsa -b 4096 -f "$SSH_KEY" -N "" -q
fi

# Kopiere Public Key auf Pi 5
echo "Kopiere SSH-Key auf Pi 5..."
sshpass -p "$PI5_PASS" ssh-copy-id -o StrictHostKeyChecking=no -o ConnectTimeout=5 "$PI5_USER@$PI5_IP" 2>&1

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ SSH-Key erfolgreich installiert!"
    echo ""
    echo "Teste Verbindung..."
    ssh -o StrictHostKeyChecking=no "$PI5_USER@$PI5_IP" "echo '✅ SSH ohne Passwort funktioniert!' && hostname && uname -a"
    
    if [ $? -eq 0 ]; then
        echo ""
        echo "✅ Setup erfolgreich abgeschlossen!"
        echo "Du kannst jetzt 'pi5-ssh.sh' verwenden."
    else
        echo "❌ Verbindungstest fehlgeschlagen"
        exit 1
    fi
else
    echo ""
    echo "❌ SSH-Key Installation fehlgeschlagen"
    echo "Bitte prüfe:"
    echo "  - IP-Adresse: $PI5_IP"
    echo "  - Passwort: $PI5_PASS"
    echo "  - SSH-Service läuft auf Pi 5"
    exit 1
fi

