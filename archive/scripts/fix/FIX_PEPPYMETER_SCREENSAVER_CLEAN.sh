#!/bin/bash
# Ghettoblaster - Saubere Lösung: PeppyMeter Screensaver
# Zuverlässige Touch-Erkennung ohne komplexe Workarounds

PI5_ALIAS="pi2"
PI5_IP="192.168.178.143"
LOG_FILE="fix-peppymeter-screensaver-clean-$(date +%Y%m%d_%H%M%S).log"

log() {
    echo "[$(date +%H:%M:%S)] $1" | tee -a "$LOG_FILE"
}

echo "=== SAUBERE LÖSUNG: PEPPYMETER SCREENSAVER ===" | tee -a "$LOG_FILE"

# Check if Pi 5 is online
if ! ping -c 1 -W 1000 "$PI5_IP" >/dev/null 2>&1; then
    log "❌ Pi 5 ist offline"
    exit 1
fi
if ! ssh -o ConnectTimeout=5 "$PI5_ALIAS" "echo 'Online!'" >/dev/null 2>&1; then
    log "❌ SSH-Verbindung fehlgeschlagen"
    exit 1
fi
log "✅ Pi 5 ist online"

log ""
log "=== SCHRITT 1: AKTUELLE SCREENSAVER ANALYSIEREN ==="

./pi5-ssh.sh << 'EOF_ANALYZE'
echo "=== PeppyMeter Screensaver Service ==="
systemctl status peppymeter-screensaver.service --no-pager -l | head -30

echo ""
echo "=== Screensaver Script ==="
head -50 /usr/local/bin/peppymeter-screensaver.sh 2>/dev/null || echo "Script nicht gefunden"
EOF_ANALYZE

log ""
log "=== SCHRITT 2: SAUBERE SCREENSAVER LÖSUNG ==="

# Erstelle sauberes Screensaver Script
./pi5-ssh.sh << 'EOF_SCREENSAVER'
cat > /tmp/peppymeter-screensaver-clean.sh << 'SCREENSAVER_EOF'
#!/bin/bash
# Ghettoblaster - PeppyMeter Screensaver (Saubere Lösung)
export DISPLAY=:0
export XAUTHORITY=/home/andre/.Xauthority

INACTIVITY_TIMEOUT=600  # 10 Minuten
LAST_ACTIVITY_FILE=/tmp/peppymeter_last_activity
LOG_FILE=/var/log/peppymeter-screensaver.log

log() {
    echo "[$(date +%H:%M:%S)] $1" | tee -a "$LOG_FILE"
}

# Warte auf X Server
for i in {1..30}; do
    xrandr --query >/dev/null 2>&1 && break
    sleep 1
done

# Initialisiere
date +%s > "$LAST_ACTIVITY_FILE"

# Finde Touchscreen
WAVESHARE_ID=$(xinput list | grep -i WaveShare | grep -oP 'id=\K[0-9]+' | head -1)
if [ -z "$WAVESHARE_ID" ]; then
    log "❌ WaveShare Touchscreen nicht gefunden"
    exit 1
fi

log "✅ Touchscreen gefunden (ID: $WAVESHARE_ID)"
log "✅ Screensaver gestartet (Timeout: ${INACTIVITY_TIMEOUT}s)"

# Touch-Monitoring im Hintergrund
(
    while true; do
        # Prüfe auf Touch-Events (einfach und zuverlässig)
        if xinput --query-state "$WAVESHARE_ID" 2>/dev/null | grep -q "button\[1\]=down"; then
            date +%s > "$LAST_ACTIVITY_FILE"
            log "Touch erkannt"
            
            # Wenn PeppyMeter aktiv, schließe es
            if systemctl is-active --quiet peppymeter.service; then
                log "PeppyMeter aktiv - schließe"
                sudo systemctl stop peppymeter.service
                sleep 1
                # Stelle Chromium wieder her
                pkill -f "chromium" || true
                sleep 2
                sudo systemctl restart localdisplay.service
            fi
        fi
        sleep 0.5
    done
) &
TOUCH_PID=$!

# Haupt-Loop
while true; do
    CURRENT_TIME=$(date +%s)
    LAST_ACTIVITY=$(cat "$LAST_ACTIVITY_FILE" 2>/dev/null || echo "$CURRENT_TIME")
    INACTIVE_TIME=$((CURRENT_TIME - LAST_ACTIVITY))
    
    if [ $INACTIVE_TIME -ge $INACTIVITY_TIMEOUT ]; then
        if ! systemctl is-active --quiet peppymeter.service; then
            log "Inaktivität erreicht - starte PeppyMeter"
            sudo systemctl start peppymeter.service
            sleep 2
            # Verstecke Chromium
            CHROMIUM_WID=$(xdotool search --class Chromium 2>/dev/null | head -1)
            if [ -n "$CHROMIUM_WID" ]; then
                xdotool windowunmap "$CHROMIUM_WID" 2>/dev/null
            fi
        fi
    fi
    
    sleep 5
done
SCREENSAVER_EOF

sudo mv /tmp/peppymeter-screensaver-clean.sh /usr/local/bin/peppymeter-screensaver.sh
sudo chmod +x /usr/local/bin/peppymeter-screensaver.sh
sudo chown andre:andre /usr/local/bin/peppymeter-screensaver.sh
echo "✅ Sauberes Screensaver Script erstellt"
EOF_SCREENSAVER

log ""
log "=== SCHRITT 3: SCREENSAVER SERVICE AKTUALISIEREN ==="

./pi5-ssh.sh << 'EOF_SERVICE'
cat > /tmp/peppymeter-screensaver.service << 'SERVICE_EOF'
[Unit]
Description=PeppyMeter Screensaver
After=localdisplay.service
After=xserver-ready.service
Wants=localdisplay.service
Wants=xserver-ready.service

[Service]
Type=simple
ExecStart=/usr/local/bin/peppymeter-screensaver.sh
Restart=always
RestartSec=5
User=andre
Environment=DISPLAY=:0
Environment=XAUTHORITY=/home/andre/.Xauthority

[Install]
WantedBy=multi-user.target
SERVICE_EOF

sudo mv /tmp/peppymeter-screensaver.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable peppymeter-screensaver.service
sudo systemctl restart peppymeter-screensaver.service
echo "✅ peppymeter-screensaver.service aktualisiert"
EOF_SERVICE

log ""
log "=== ZUSAMMENFASSUNG ==="
log "✅ Sauberes Screensaver Script erstellt"
log "✅ Service aktualisiert"
log "✅ Einfache und zuverlässige Touch-Erkennung"

echo "==========================================" | tee -a "$LOG_FILE"
echo "✅ SAUBERE PEPPYMETER SCREENSAVER LÖSUNG" | tee -a "$LOG_FILE"
echo "==========================================" | tee -a "$LOG_FILE"

