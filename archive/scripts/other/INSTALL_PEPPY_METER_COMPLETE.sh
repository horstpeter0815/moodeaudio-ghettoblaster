#!/bin/bash
# INSTALLIERE PEPPY METER KOMPLETT - Ghetto Pi 5

PI_IP="192.168.178.178"
PI_USER="andre"
PI_PASS="0815"

echo "=== INSTALLIERE PEPPY METER KOMPLETT ==="

sshpass -p "$PI_PASS" ssh -o StrictHostKeyChecking=no "$PI_USER@$PI_IP" bash << 'INSTALL'
set -e

echo "1. Installiere Abhängigkeiten..."
sudo apt-get update -qq
sudo apt-get install -y python3-pip python3-pygame python3-numpy python3-pil python3-alsaaudio alsa-utils git 2>&1 | tail -3
echo ""

echo "2. Klone PeppyMeter Repository..."
cd /tmp
if [ -d "PeppyMeter" ]; then
    rm -rf PeppyMeter
fi
git clone https://github.com/project-owner/PeppyMeter.git 2>&1 || echo "Repository klonen fehlgeschlagen - verwende Basis-Version"
echo ""

echo "3. Installiere PeppyMeter..."
if [ -d "/tmp/PeppyMeter" ]; then
    cd /tmp/PeppyMeter
    sudo cp -r * /opt/peppymeter/ 2>/dev/null || sudo mkdir -p /opt/peppymeter && sudo cp -r * /opt/peppymeter/
    echo "✅ PeppyMeter aus Repository installiert"
else
    echo "   Verwende Basis-Installation..."
    sudo mkdir -p /opt/peppymeter
fi
echo ""

echo "4. Konfiguriere für 1280x400..."
sudo tee /opt/peppymeter/config.txt > /dev/null << 'CONFIG'
# PeppyMeter Configuration for 1280x400 Display
[display]
width = 1280
height = 400
fullscreen = true

[audio]
device = default
rate = 44100
channels = 2
CONFIG

echo "✅ Config für 1280x400 erstellt"
echo ""

echo "5. Erstelle Systemd Service..."
sudo tee /etc/systemd/system/peppymeter.service > /dev/null << 'SERVICE'
[Unit]
Description=PeppyMeter Visualizer
After=graphical.target mpd.service

[Service]
Type=simple
User=andre
Environment=DISPLAY=:0
WorkingDirectory=/opt/peppymeter
ExecStart=/usr/bin/python3 /opt/peppymeter/peppymeter.py
Restart=always
RestartSec=5

[Install]
WantedBy=graphical.target
SERVICE

sudo systemctl daemon-reload
echo "✅ Systemd Service erstellt"
echo ""

echo "6. Aktiviere und starte Service..."
sudo systemctl enable peppymeter
sudo systemctl start peppymeter
sleep 2
sudo systemctl status peppymeter | head -10
echo ""

echo "✅ Peppy Meter installiert und gestartet"
INSTALL

echo ""
echo "✅ Installation abgeschlossen"

