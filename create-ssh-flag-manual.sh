#!/bin/bash
# Manuelles Script zum Erstellen der SSH-Flag-Datei
# Führe aus: ./create-ssh-flag-manual.sh

echo "=== Erstelle SSH-Flag-Datei ==="
echo ""

# Versuche ohne sudo
if touch /Volumes/bootfs/ssh 2>/dev/null; then
    echo "✅ SSH-Flag erstellt: /Volumes/bootfs/ssh"
    ls -lh /Volumes/bootfs/ssh
    exit 0
fi

# Falls das nicht funktioniert, versuche mit sudo
echo "Benötige sudo-Rechte..."
sudo touch /Volumes/bootfs/ssh

if [ -f /Volumes/bootfs/ssh ]; then
    echo "✅ SSH-Flag erstellt (mit sudo): /Volumes/bootfs/ssh"
    sudo chmod 644 /Volumes/bootfs/ssh
    ls -lh /Volumes/bootfs/ssh
    echo ""
    echo "✅ Fertig! SSH sollte nach dem Boot funktionieren."
else
    echo "❌ Konnte SSH-Flag nicht erstellen"
    echo ""
    echo "Alternative: Verwende WebSSH (Port 4200) nach dem Boot"
    exit 1
fi

