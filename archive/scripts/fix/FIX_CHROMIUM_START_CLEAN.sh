#!/bin/bash
# Ghettoblaster - Saubere Lösung: Chromium Start
# Stabile Service-Abhängigkeiten statt Retry-Logic

PI5_ALIAS="pi2"
PI5_IP="192.168.178.143"
LOG_FILE="fix-chromium-clean-$(date +%Y%m%d_%H%M%S).log"

log() {
    echo "[$(date +%H:%M:%S)] $1" | tee -a "$LOG_FILE"
}

echo "=== SAUBERE LÖSUNG: CHROMIUM START ===" | tee -a "$LOG_FILE"

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
log "=== SCHRITT 1: X SERVER READY CHECK SCRIPT ==="

# Erstelle X Server Ready Check Script
./pi5-ssh.sh << 'EOF_XREADY'
cat > /usr/local/bin/xserver-ready.sh << 'XREADY_EOF'
#!/bin/bash
# Prüft ob X Server bereit ist
# Exit 0 = Ready, Exit 1 = Not Ready

export DISPLAY=:0
export XAUTHORITY=/home/andre/.Xauthority

MAX_WAIT=30  # Sekunden
WAIT_INTERVAL=0.5

for i in $(seq 1 $((MAX_WAIT * 2))); do
    # Test 1: xrandr
    if timeout 1 xrandr --query >/dev/null 2>&1; then
        # Test 2: xdpyinfo
        if timeout 1 xdpyinfo -display :0 >/dev/null 2>&1; then
            exit 0  # X Server ist bereit
        fi
    fi
    sleep $WAIT_INTERVAL
done

exit 1  # X Server nicht bereit nach MAX_WAIT Sekunden
XREADY_EOF

chmod +x /usr/local/bin/xserver-ready.sh
echo "✅ X Server Ready Check Script erstellt"
EOF_XREADY

log ""
log "=== SCHRITT 2: SAUBERES CHROMIUM START SCRIPT ==="

# Erstelle sauberes Chromium Start Script (ohne Retry-Logic)
./pi5-ssh.sh << 'EOF_CHROMIUM'
cat > /usr/local/bin/start-chromium-clean.sh << 'CHROMIUM_EOF'
#!/bin/bash
# Sauberes Chromium Startup - Keine Retry-Logic, stabile Abhängigkeiten

export DISPLAY=:0
export XAUTHORITY=/home/andre/.Xauthority

LOG_FILE=/var/log/chromium-clean.log

log() {
    echo "[$(date +%Y-%m-%d %H:%M:%S)] $1" | tee -a "$LOG_FILE"
}

log "=== CHROMIUM CLEAN START ==="

# Warte auf X Server (über Ready-Check)
log "Warte auf X Server..."
/usr/local/bin/xserver-ready.sh
if [ $? -ne 0 ]; then
    log "❌ X Server nicht bereit nach 30 Sekunden"
    exit 1
fi
log "✅ X Server bereit"

# Setze X Permissions
xhost +SI:localuser:andre 2>/dev/null || true
sleep 1

# Setze Display Rotation
if xrandr | grep -q "400x1280"; then
    xrandr --output HDMI-2 --mode 400x1280 --rotate left 2>&1 || \
    xrandr --output HDMI-1 --mode 400x1280 --rotate left 2>&1
elif xrandr | grep -q "1280x400"; then
    xrandr --output HDMI-2 --mode 1280x400 --rotate normal 2>&1 || \
    xrandr --output HDMI-1 --mode 1280x400 --rotate normal 2>&1
fi

# Disable Screensaver
xset s off 2>/dev/null || true
xset -dpms 2>/dev/null || true

# Cleanup alte Chromium Prozesse
pkill -9 chromium 2>/dev/null || true
pkill -9 chromium-browser 2>/dev/null || true
sleep 2

# Cleanup Lock Files
rm -rf /tmp/chromium-data/Singleton* 2>/dev/null || true

# Starte Chromium (EINMAL, keine Retry-Logic)
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

# Verifiziere Start
if ps -p $CHROMIUM_PID > /dev/null 2>&1; then
    log "✅ Chromium gestartet (PID: $CHROMIUM_PID)"
    
    # Warte auf Window
    for i in {1..10}; do
        WINDOW=$(xdotool search --class Chromium 2>/dev/null | head -1)
        if [ -n "$WINDOW" ]; then
            xdotool windowsize $WINDOW 1280 400 2>/dev/null
            xdotool windowmove $WINDOW 0 0 2>/dev/null
            xdotool windowraise $WINDOW 2>/dev/null
            log "✅ Chromium Window gefunden und positioniert"
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
CHROMIUM_EOF

chmod +x /usr/local/bin/start-chromium-clean.sh
echo "✅ Sauberes Chromium Start Script erstellt"
EOF_CHROMIUM

log ""
log "=== SCHRITT 3: SERVICE-ABHÄNGIGKEITEN KORRIGIEREN ==="

# Korrigiere localdisplay.service Abhängigkeiten
./pi5-ssh.sh << 'EOF_SERVICE'
# Erstelle Override für localdisplay.service
sudo mkdir -p /etc/systemd/system/localdisplay.service.d/

cat > /tmp/localdisplay-override.conf << 'OVERRIDE_EOF'
[Unit]
# Explizite Abhängigkeiten
After=graphical.target
Wants=graphical.target
After=xserver-ready.service
Wants=xserver-ready.service

[Service]
# X Server Ready Check vor Chromium Start
ExecStartPre=/usr/local/bin/xserver-ready.sh
ExecStartPre=/bin/sleep 2
# Sauberes Chromium Script
ExecStart=/usr/local/bin/start-chromium-clean.sh
# Timeout
TimeoutStartSec=60
# Restart Policy
Restart=on-failure
RestartSec=5
OVERRIDE_EOF

sudo mv /tmp/localdisplay-override.conf /etc/systemd/system/localdisplay.service.d/override.conf
echo "✅ localdisplay.service Override erstellt"

# Erstelle xserver-ready.service
cat > /tmp/xserver-ready.service << 'XREADY_SERVICE_EOF'
[Unit]
Description=X Server Ready Check
After=graphical.target
Wants=graphical.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/xserver-ready.sh
RemainAfterExit=yes
TimeoutStartSec=35

[Install]
WantedBy=graphical.target
XREADY_SERVICE_EOF

sudo mv /tmp/xserver-ready.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable xserver-ready.service
echo "✅ xserver-ready.service erstellt und aktiviert"
EOF_SERVICE

log ""
log "=== SCHRITT 4: ALTE WORKAROUNDS ENTFERNEN ==="

# Entferne chromium-monitor.service (Workaround)
./pi5-ssh.sh << 'EOF_CLEANUP'
if systemctl is-enabled chromium-monitor.service >/dev/null 2>&1; then
    sudo systemctl disable chromium-monitor.service
    sudo systemctl stop chromium-monitor.service
    echo "✅ chromium-monitor.service deaktiviert (Workaround entfernt)"
fi

# Entferne alte bulletproof Script (wird durch clean ersetzt)
if [ -f /usr/local/bin/start-chromium-bulletproof.sh ]; then
    sudo mv /usr/local/bin/start-chromium-bulletproof.sh /usr/local/bin/start-chromium-bulletproof.sh.backup
    echo "✅ Altes bulletproof Script gesichert"
fi
EOF_CLEANUP

log ""
log "=== SCHRITT 5: .XINITRC AKTUALISIEREN ==="

# Aktualisiere .xinitrc
./pi5-ssh.sh << 'EOF_XINITRC'
cat > /tmp/xinitrc-clean << 'XINITRC_EOF'
#!/bin/bash
export DISPLAY=:0

# Wait for X
for i in {1..40}; do
    xrandr --query >/dev/null 2>&1 && break
    sleep 0.25
done

xhost +SI:localuser:andre 2>/dev/null || true
sleep 2

# Set Landscape
if xrandr | grep -q "400x1280"; then
    xrandr --output HDMI-2 --mode 400x1280 --rotate left 2>&1
elif xrandr | grep -q "1280x400"; then
    xrandr --output HDMI-2 --mode 1280x400 --rotate normal 2>&1
fi

xset s 600
xset -dpms 2>/dev/null || true
xset s 600

# Chromium wird jetzt von localdisplay.service gestartet
# (nicht mehr direkt hier)
wait
XINITRC_EOF

sudo mv /tmp/xinitrc-clean /home/andre/.xinitrc
sudo chown andre:andre /home/andre/.xinitrc
chmod +x /home/andre/.xinitrc
echo "✅ .xinitrc aktualisiert"
EOF_XINITRC

log ""
log "=== SCHRITT 6: VERIFIKATION ==="

log "Service-Abhängigkeiten:"
./pi5-ssh.sh "systemctl list-dependencies localdisplay.service --no-pager" | tee -a "$LOG_FILE"

log ""
log "=== ZUSAMMENFASSUNG ==="
log "✅ X Server Ready Check implementiert"
log "✅ Sauberes Chromium Start Script (ohne Retry-Logic)"
log "✅ Service-Abhängigkeiten korrigiert"
log "✅ Alte Workarounds entfernt"
log ""
log "Nächste Schritte:"
log "  1. Reboot durchführen"
log "  2. Chromium sollte stabil starten"
log "  3. Keine Retry-Logic mehr nötig"

echo "==========================================" | tee -a "$LOG_FILE"
echo "✅ SAUBERE CHROMIUM LÖSUNG IMPLEMENTIERT" | tee -a "$LOG_FILE"
echo "==========================================" | tee -a "$LOG_FILE"

