#!/bin/bash
# SSH-Key auf Pi 5 einrichten und Passwort-Authentifizierung deaktivieren

PI5_IP="192.168.178.134"
PI5_USER="andre"
SSH_KEY="$(cat ~/.ssh/id_rsa.pub)"

echo "=== SSH-KEY EINRICHTUNG FÜR PI 5 ==="
echo ""

# Versuche Key zu kopieren
echo "1. Kopiere SSH-Key auf Pi 5..."
ssh-copy-id -o StrictHostKeyChecking=accept-new $PI5_USER@$PI5_IP 2>&1

if [ $? -eq 0 ]; then
    echo "✅ SSH-Key kopiert"
    echo ""
    echo "2. Deaktiviere Passwort-Authentifizierung..."
    ssh $PI5_USER@$PI5_IP "sudo sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config && sudo sed -i 's/^PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config && sudo systemctl restart sshd && echo '✅ Passwort-Auth deaktiviert'"
    
    echo ""
    echo "3. Teste SSH-Zugriff..."
    ssh $PI5_USER@$PI5_IP "echo '✅ SSH funktioniert ohne Passwort'"
else
    echo "❌ Key-Kopie fehlgeschlagen"
    echo ""
    echo "Manuell auf Pi 5 ausführen:"
    echo "  mkdir -p ~/.ssh && chmod 700 ~/.ssh"
    echo "  echo '$SSH_KEY' >> ~/.ssh/authorized_keys"
    echo "  chmod 600 ~/.ssh/authorized_keys"
    echo "  sudo sed -i 's/PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config"
    echo "  sudo systemctl restart sshd"
fi
