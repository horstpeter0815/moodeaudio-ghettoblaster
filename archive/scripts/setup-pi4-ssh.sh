#!/bin/bash
# SSH-Key Setup für Pi 4 (moodepi4)
# 
# WICHTIG: Dieses Script wird auf dem MAC ausgeführt!
# Es kopiert den SSH-Key vom Mac auf den Pi 4.

PI4_HOSTNAME="moodepi4"
PI4_USER="andre"
PI4_PASS="0815"

# Versuche IP zu finden
echo "=== SSH-Key Setup für Pi 4 (moodepi4) ==="
echo "Suche IP-Adresse..."

# Versuche IP über mDNS zu finden
PI4_IP=$(ping -c 1 -W 1000 "${PI4_HOSTNAME}.local" 2>/dev/null | grep -oE '\([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+\)' | tr -d '()' | head -1)

if [ -z "$PI4_IP" ]; then
    echo "⚠️ IP nicht gefunden über mDNS"
    echo "Bitte IP-Adresse manuell eingeben:"
    read -p "IP-Adresse: " PI4_IP
fi

if [ -z "$PI4_IP" ]; then
    echo "❌ Keine IP-Adresse angegeben"
    exit 1
fi

echo "IP: $PI4_IP"
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

# Kopiere Public Key auf Pi 4
echo "Kopiere SSH-Key auf Pi 4..."
sshpass -p "$PI4_PASS" ssh-copy-id -o StrictHostKeyChecking=no -o ConnectTimeout=5 "$PI4_USER@$PI4_IP" 2>&1

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ SSH-Key erfolgreich installiert!"
    echo ""
    echo "Teste Verbindung..."
    ssh -o StrictHostKeyChecking=no "$PI4_USER@$PI4_IP" "echo '✅ SSH ohne Passwort funktioniert!' && hostname && uname -a"
    
    if [ $? -eq 0 ]; then
        echo ""
        echo "✅ Setup erfolgreich abgeschlossen!"
        echo "IP-Adresse: $PI4_IP"
        echo "Du kannst jetzt 'pi4-ssh.sh' verwenden."
        
        # Speichere IP in Datei
        echo "$PI4_IP" > .pi4_ip
        echo "IP gespeichert in .pi4_ip"
    else
        echo "❌ Verbindungstest fehlgeschlagen"
        exit 1
    fi
else
    echo ""
    echo "❌ SSH-Key Installation fehlgeschlagen"
    echo "Bitte prüfe:"
    echo "  - IP-Adresse: $PI4_IP"
    echo "  - Passwort: $PI4_PASS"
    echo "  - SSH-Service läuft auf Pi 4"
    exit 1
fi

