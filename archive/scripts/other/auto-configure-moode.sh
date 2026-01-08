#!/bin/bash
# Automatische moOde Konfiguration

PI_IP="192.168.178.161"

echo "🔧 Automatische moOde Konfiguration..."

# Versuche verschiedene Passwörter
for PASS in "DSD" "moodeaudio" "raspberry" "pi"; do
    if sshpass -p "$PASS" ssh -o StrictHostKeyChecking=no pi@$PI_IP "echo 'OK'" >/dev/null 2>&1; then
        echo "✅ SSH funktioniert mit Passwort"
        
        # Keyboard: Deutsch
        sshpass -p "$PASS" ssh pi@$PI_IP "sudo raspi-config nonint do_configure_keyboard de" 2>/dev/null
        
        # Timezone: Europe/Berlin
        sshpass -p "$PASS" ssh pi@$PI_IP "sudo timedatectl set-timezone Europe/Berlin" 2>/dev/null
        
        # Locale: de_DE.UTF-8
        sshpass -p "$PASS" ssh pi@$PI_IP "sudo locale-gen de_DE.UTF-8" 2>/dev/null
        
        echo "✅ Konfiguration durchgeführt"
        break
    fi
done

# Web-UI API Setup
echo "🌐 Versuche Web-UI API..."
curl -s -X POST "http://$PI_IP/command/sys-config.php" \
    -d "cmd=setcfg&section=system&key=keyboard&value=de" >/dev/null 2>&1

echo "✅ Setup-Versuch abgeschlossen"
