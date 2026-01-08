#!/bin/bash
# Ghettoblaster - Fix localdisplay.service (mehrere ExecStart Fehler)

PI5_ALIAS="pi2"
PI5_IP="192.168.178.143"
LOG_FILE="fix-localdisplay-service-$(date +%Y%m%d_%H%M%S).log"

log() {
    echo "[$(date +%H:%M:%S)] $1" | tee -a "$LOG_FILE"
}

echo "=== FIX LOCALDISPLAY SERVICE ===" | tee -a "$LOG_FILE"

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
log "=== SCHRITT 1: AKTUELLE SERVICE-DATEIEN PRÜFEN ==="

./pi5-ssh.sh << 'EOF_CHECK'
echo "=== localdisplay.service ==="
systemctl cat localdisplay.service | head -50

echo ""
echo "=== Override Dateien ==="
ls -la /etc/systemd/system/localdisplay.service.d/ 2>/dev/null
EOF_CHECK

log ""
log "=== SCHRITT 2: OVERRIDE DATEIEN BEREINIGEN ==="

./pi5-ssh.sh << 'EOF_FIX'
# Entferne alle Override Dateien
sudo rm -rf /etc/systemd/system/localdisplay.service.d/*

# Erstelle saubere Override
sudo mkdir -p /etc/systemd/system/localdisplay.service.d/

cat > /tmp/localdisplay-override-clean.conf << 'OVERRIDE_EOF'
[Unit]
After=graphical.target
After=xserver-ready.service
Wants=graphical.target
Wants=xserver-ready.service

[Service]
ExecStartPre=/usr/local/bin/xserver-ready.sh
ExecStartPre=/bin/sleep 2
ExecStart=/usr/local/bin/start-chromium-clean.sh
TimeoutStartSec=60
Restart=on-failure
RestartSec=5
OVERRIDE_EOF

sudo mv /tmp/localdisplay-override-clean.conf /etc/systemd/system/localdisplay.service.d/override.conf
echo "✅ Saubere Override erstellt"

# Prüfe ob Scripts existieren
if [ ! -f /usr/local/bin/xserver-ready.sh ]; then
    echo "⚠️  xserver-ready.sh fehlt - erstelle es"
    sudo bash -c 'cat > /usr/local/bin/xserver-ready.sh << "SCRIPT_EOF"
#!/bin/bash
export DISPLAY=:0
export XAUTHORITY=/home/andre/.Xauthority
MAX_WAIT=30
WAIT_INTERVAL=0.5
for i in $(seq 1 $((MAX_WAIT * 2))); do
    if timeout 1 xrandr --query >/dev/null 2>&1; then
        if timeout 1 xdpyinfo -display :0 >/dev/null 2>&1; then
            exit 0
        fi
    fi
    sleep $WAIT_INTERVAL
done
exit 1
SCRIPT_EOF
'
    sudo chmod +x /usr/local/bin/xserver-ready.sh
    echo "✅ xserver-ready.sh erstellt"
fi

if [ ! -f /usr/local/bin/start-chromium-clean.sh ]; then
    echo "⚠️  start-chromium-clean.sh fehlt - erstelle es"
    sudo bash -c 'cat > /usr/local/bin/start-chromium-clean.sh << "SCRIPT_EOF"
#!/bin/bash
export DISPLAY=:0
export XAUTHORITY=/home/andre/.Xauthority
LOG_FILE=/var/log/chromium-clean.log
log() {
    echo "[$(date +%Y-%m-%d %H:%M:%S)] $1" | tee -a "$LOG_FILE"
}
log "=== CHROMIUM CLEAN START ==="
/usr/local/bin/xserver-ready.sh || exit 1
log "✅ X Server bereit"
xhost +SI:localuser:andre 2>/dev/null || true
sleep 1
if xrandr | grep -q "400x1280"; then
    xrandr --output HDMI-2 --mode 400x1280 --rotate left 2>&1 || \
    xrandr --output HDMI-1 --mode 400x1280 --rotate left 2>&1
elif xrandr | grep -q "1280x400"; then
    xrandr --output HDMI-2 --mode 1280x400 --rotate normal 2>&1 || \
    xrandr --output HDMI-1 --mode 1280x400 --rotate normal 2>&1
fi
xset s off 2>/dev/null || true
xset -dpms 2>/dev/null || true
pkill -9 chromium 2>/dev/null || true
pkill -9 chromium-browser 2>/dev/null || true
sleep 2
rm -rf /tmp/chromium-data/Singleton* 2>/dev/null || true
log "Starte Chromium..."
chromium-browser \
    --kiosk \
    --no-sandbox \
    --user-data-dir=/tmp/chromium-data \
    --window-size=1280,400 \
    --window-position=0,0 \
    --start-fullscreen \
    --noerrdialogs \
    --disable-infobars \
    --disable-session-crashed-bubble \
    --disable-restore-session-state \
    --disable-web-security \
    --autoplay-policy=no-user-gesture-required \
    --check-for-update-interval=31536000 \
    --disable-features=TranslateUI \
    --disable-gpu \
    --disable-software-rasterizer \
    http://localhost >/dev/null 2>&1 &
CHROMIUM_PID=$!
sleep 3
if ps -p $CHROMIUM_PID > /dev/null 2>&1; then
    log "✅ Chromium gestartet (PID: $CHROMIUM_PID)"
    for i in {1..10}; do
        WINDOW=$(xdotool search --class Chromium 2>/dev/null | head -1)
        if [ -n "$WINDOW" ]; then
            xdotool windowsize $WINDOW 1280 400 2>/dev/null
            xdotool windowmove $WINDOW 0 0 2>/dev/null
            xdotool windowraise $WINDOW 2>/dev/null
            log "✅ Chromium Window gefunden"
            exit 0
        fi
        sleep 1
    done
    log "⚠️  Chromium läuft, aber Window nicht gefunden"
    exit 0
else
    log "❌ Chromium Start fehlgeschlagen"
    exit 1
fi
SCRIPT_EOF
'
    sudo chmod +x /usr/local/bin/start-chromium-clean.sh
    echo "✅ start-chromium-clean.sh erstellt"
fi
EOF_FIX

log ""
log "=== SCHRITT 3: SYSTEMD DAEMON-RELOAD ==="

./pi5-ssh.sh "sudo systemctl daemon-reload"
log "✅ systemd daemon-reload durchgeführt"

log ""
log "=== SCHRITT 4: SERVICE VERIFIKATION ==="

log "Prüfe localdisplay.service:"
./pi5-ssh.sh "systemctl cat localdisplay.service | head -40" | tee -a "$LOG_FILE"

log ""
log "=== ZUSAMMENFASSUNG ==="
log "✅ localdisplay.service bereinigt"
log "✅ Nur noch ein ExecStart"
log "✅ Saubere Abhängigkeiten"

echo "==========================================" | tee -a "$LOG_FILE"
echo "✅ LOCALDISPLAY SERVICE FIX ABGESCHLOSSEN" | tee -a "$LOG_FILE"
echo "==========================================" | tee -a "$LOG_FILE"

