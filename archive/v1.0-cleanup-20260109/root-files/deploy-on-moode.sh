#!/bin/bash
# Deployment Script für moOde System
# Ausführen auf dem Raspberry Pi nach dem Booten

echo "=== moOde Deployment Script ==="
echo ""

# Prüfe ob Dateien auf SD-Karte existieren
if [ ! -d "/boot/moode_deploy" ]; then
    echo "FEHLER: /boot/moode_deploy nicht gefunden!"
    echo "Bitte SD-Karte prüfen."
    exit 1
fi

echo "✓ Deployment-Verzeichnis gefunden"
echo ""

# 1. Fix index.html redirect
echo "1. Fixe index.html redirect..."
if [ -f "/boot/moode_deploy/fix-index-redirect.php" ]; then
    sudo cp /boot/moode_deploy/fix-index-redirect.php /var/www/html/
    sudo chown www-data:www-data /var/www/html/fix-index-redirect.php
    sudo chmod 644 /var/www/html/fix-index-redirect.php
    echo "✓ fix-index-redirect.php kopiert"
    
    # Lösche index.html falls vorhanden
    if [ -f "/var/www/html/index.html" ]; then
        sudo rm /var/www/html/index.html
        echo "✓ index.html gelöscht (Redirect behoben)"
    fi
else
    echo "⚠ fix-index-redirect.php nicht gefunden (übersprungen)"
fi
echo ""

# 2. Kopiere test-wizard Dateien
echo "2. Kopiere test-wizard Dateien..."
if [ -d "/boot/moode_deploy/test-wizard" ]; then
    sudo mkdir -p /var/www/html/test-wizard
    sudo cp -r /boot/moode_deploy/test-wizard/* /var/www/html/test-wizard/
    sudo chown -R www-data:www-data /var/www/html/test-wizard
    sudo find /var/www/html/test-wizard -type f -exec chmod 644 {} \;
    sudo find /var/www/html/test-wizard -type d -exec chmod 755 {} \;
    echo "✓ test-wizard Dateien kopiert"
else
    echo "⚠ test-wizard Verzeichnis nicht gefunden (übersprungen)"
fi
echo ""

# 3. Kopiere room-correction-wizard.php
echo "3. Kopiere room-correction-wizard.php..."
if [ -f "/boot/moode_deploy/command/room-correction-wizard.php" ]; then
    sudo mkdir -p /var/www/html/command
    sudo cp /boot/moode_deploy/command/room-correction-wizard.php /var/www/html/command/
    sudo chown www-data:www-data /var/www/html/command/room-correction-wizard.php
    sudo chmod 644 /var/www/html/command/room-correction-wizard.php
    echo "✓ room-correction-wizard.php kopiert"
else
    echo "⚠ room-correction-wizard.php nicht gefunden (übersprungen)"
fi
echo ""

echo "=== Deployment abgeschlossen ==="
echo ""
echo "Zugriff:"
echo "  - Player: https://10.10.11.39:8443/"
echo "  - Wizard: https://10.10.11.39:8443/test-wizard/index-simple.html"
echo ""

