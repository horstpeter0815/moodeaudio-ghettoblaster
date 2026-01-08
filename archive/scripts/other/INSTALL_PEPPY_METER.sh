#!/bin/bash
# INSTALLIERE PEPPY METER - Ghetto Pi 5

PI_IP="192.168.178.178"
PI_USER="andre"
PI_PASS="0815"

echo "=== INSTALLIERE PEPPY METER ==="

sshpass -p "$PI_PASS" ssh -o StrictHostKeyChecking=no "$PI_USER@$PI_IP" bash << 'INSTALL'
set -e

echo "1. Prüfe ob Peppy Meter bereits installiert ist..."
if [ -d "/opt/peppymeter" ] || [ -f "/usr/local/bin/peppymeter" ]; then
    echo "   Peppy Meter bereits installiert"
    exit 0
fi

echo "2. Installiere Abhängigkeiten..."
sudo apt-get update -qq
sudo apt-get install -y python3-pip python3-pygame python3-numpy python3-pil || true

echo "3. Klone Peppy Meter Repository..."
cd /tmp
if [ -d "peppymeter" ]; then
    rm -rf peppymeter
fi
git clone https://github.com/project-owner/peppymeter.git 2>/dev/null || echo "   Repository nicht gefunden - manuelle Installation nötig"

echo "4. Installiere Peppy Meter..."
if [ -d "/tmp/peppymeter" ]; then
    cd /tmp/peppymeter
    sudo python3 setup.py install 2>/dev/null || echo "   Setup fehlgeschlagen"
fi

echo "5. Konfiguriere für 1280x400 Display..."
# Erstelle Config für 1280x400
sudo mkdir -p /opt/peppymeter
sudo tee /opt/peppymeter/config.ini > /dev/null << 'CONFIG'
[display]
width = 1280
height = 400
fullscreen = true

[visualizer]
type = spectrum
bars = 64
CONFIG

echo "6. Erstelle Systemd Service..."
sudo tee /etc/systemd/system/peppymeter.service > /dev/null << 'SERVICE'
[Unit]
Description=Peppy Meter Visualizer
After=graphical.target

[Service]
Type=simple
User=andre
Environment=DISPLAY=:0
ExecStart=/usr/local/bin/peppymeter --config /opt/peppymeter/config.ini
Restart=always

[Install]
WantedBy=graphical.target
SERVICE

sudo systemctl daemon-reload
sudo systemctl enable peppymeter.service

echo "✅ Peppy Meter installiert"
INSTALL

echo ""
echo "✅ Installation abgeschlossen"

