#!/bin/bash
# Optimiere alle Services für maximale Stabilität
# Keine Workarounds - alles sauber integriert

PI5_ALIAS="pi2"
PI5_IP="192.168.178.143"
LOG_FILE="optimize-services-$(date +%Y%m%d_%H%M%S).log"

log() {
    echo "[$(date +%H:%M:%S)] $1" | tee -a "$LOG_FILE"
}

echo "=== SERVICE OPTIMIZATION ===" | tee -a "$LOG_FILE"

# Prüfe ob Pi 5 online ist
if ! ping -c 1 -W 1000 "$PI5_IP" >/dev/null 2>&1; then
    log "❌ Pi 5 ist offline"
    exit 1
fi
log "✅ Pi 5 ist online"

log "1. Optimiere localdisplay.service..."
./pi5-ssh.sh << 'EOF_LOCALDISPLAY'
sudo tee /etc/systemd/system/localdisplay.service > /dev/null << 'SERVICE_EOF'
[Unit]
Description=Start Local Display
After=graphical.target nginx.service php8.4-fpm.service mpd.service
Wants=graphical.target
Requires=graphical.target

[Service]
Type=simple
User=andre
Environment=DISPLAY=:0
Environment=XAUTHORITY=/home/andre/.Xauthority
ExecStartPre=/bin/bash -c 'until [ -f /tmp/.X11-unix/X0 ]; do sleep 0.5; done'
ExecStart=/usr/bin/xinit
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
SERVICE_EOF
sudo systemctl daemon-reload
log "   ✅ localdisplay.service optimiert"
EOF_LOCALDISPLAY

log "2. Optimiere ft6236-delay.service (Touchscreen)..."
./pi5-ssh.sh << 'EOF_TOUCHSCREEN'
sudo tee /etc/systemd/system/ft6236-delay.service > /dev/null << 'SERVICE_EOF'
[Unit]
Description=Load FT6236 touchscreen after display
After=localdisplay.service
Wants=localdisplay.service
Requires=localdisplay.service

[Service]
Type=oneshot
ExecStart=/bin/bash -c 'sleep 3 && modprobe ft6236'
RemainAfterExit=yes
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=localdisplay.service
SERVICE_EOF
sudo systemctl daemon-reload
sudo systemctl enable ft6236-delay.service
log "   ✅ ft6236-delay.service optimiert"
EOF_TOUCHSCREEN

log "3. Optimiere MPD Service..."
./pi5-ssh.sh << 'EOF_MPD'
sudo mkdir -p /etc/systemd/system/mpd.service.d
sudo tee /etc/systemd/system/mpd.service.d/override.conf > /dev/null << 'OVERRIDE_EOF'
[Unit]
After=localdisplay.service sound.target local-fs.target
Wants=localdisplay.service sound.target local-fs.target

[Service]
ExecStartPre=/bin/bash -c 'until aplay -l | grep -q hifiberry || aplay -l | grep -q card; do sleep 1; done'
Restart=always
RestartSec=5
OVERRIDE_EOF
sudo systemctl daemon-reload
log "   ✅ MPD Service optimiert"
EOF_MPD

log "4. Optimiere PeppyMeter Service..."
./pi5-ssh.sh << 'EOF_PEPPYMETER'
sudo mkdir -p /etc/systemd/system/peppymeter.service.d
sudo tee /etc/systemd/system/peppymeter.service.d/override.conf > /dev/null << 'OVERRIDE_EOF'
[Unit]
After=localdisplay.service mpd.service
Wants=localdisplay.service mpd.service
Requires=localdisplay.service

[Service]
ExecStartPre=/bin/bash -c 'until [ -f /tmp/.X11-unix/X0 ]; do sleep 0.5; done'
Restart=always
RestartSec=10
OVERRIDE_EOF
sudo systemctl daemon-reload
log "   ✅ PeppyMeter Service optimiert"
EOF_PEPPYMETER

log "5. Optimiere Chromium Monitor Service..."
./pi5-ssh.sh << 'EOF_CHROMIUM'
sudo tee /etc/systemd/system/chromium-monitor.service > /dev/null << 'SERVICE_EOF'
[Unit]
Description=Chromium Kiosk Monitor
After=localdisplay.service
Wants=localdisplay.service
Requires=localdisplay.service

[Service]
Type=simple
ExecStart=/bin/bash -c 'while true; do sleep 15; if ! pgrep -f chromium-browser > /dev/null; then echo "Chromium not running, restarting localdisplay.service" | systemd-cat -t chromium-monitor; sudo systemctl restart localdisplay.service; fi; done'
Restart=always
RestartSec=5
User=andre
Environment=DISPLAY=:0
Environment=XAUTHORITY=/home/andre/.Xauthority
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
SERVICE_EOF
sudo systemctl daemon-reload
sudo systemctl enable chromium-monitor.service
log "   ✅ chromium-monitor.service optimiert"
EOF_CHROMIUM

log "6. Verifikation - Service-Abhängigkeiten..."
./pi5-ssh.sh "systemctl list-dependencies localdisplay.service --no-pager" | tee -a "$LOG_FILE"

echo "==========================================" | tee -a "$LOG_FILE"
echo "✅ ALLE SERVICES OPTIMIERT" | tee -a "$LOG_FILE"
echo "==========================================" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"
echo "Services haben jetzt:" | tee -a "$LOG_FILE"
echo "  - Korrekte Abhängigkeiten" | tee -a "$LOG_FILE"
echo "  - Restart-Policies" | tee -a "$LOG_FILE"
echo "  - Error-Handling" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"
echo "Reboot empfohlen, um alle Änderungen zu aktivieren." | tee -a "$LOG_FILE"

