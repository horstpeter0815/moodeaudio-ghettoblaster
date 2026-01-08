#!/bin/bash
# Ghettoblaster - Saubere Lösung: Touchscreen Reliability
# Systematische Analyse und Lösung statt Workarounds

PI5_ALIAS="pi2"
PI5_IP="192.168.178.143"
LOG_FILE="fix-touchscreen-clean-$(date +%Y%m%d_%H%M%S).log"

log() {
    echo "[$(date +%H:%M:%S)] $1" | tee -a "$LOG_FILE"
}

echo "=== SAUBERE LÖSUNG: TOUCHSCREEN RELIABILITY ===" | tee -a "$LOG_FILE"

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
log "=== SCHRITT 1: TOUCHSCREEN HARDWARE ANALYSIEREN ==="

./pi5-ssh.sh << 'EOF_ANALYZE'
echo "=== Touchscreen Hardware ==="
lsmod | grep -i ft6236 || echo "FT6236 Modul nicht geladen"

echo ""
echo "=== Input Devices ==="
cat /proc/bus/input/devices | grep -A 10 -i "waveshare\|ft6236" || echo "Kein WaveShare/FT6236 gefunden"

echo ""
echo "=== X Input Devices ==="
export DISPLAY=:0
export XAUTHORITY=/home/andre/.Xauthority
xinput list 2>/dev/null | grep -i "waveshare\|touch" || echo "Kein Touchscreen in X"
EOF_ANALYZE

log ""
log "=== SCHRITT 2: TOUCHSCREEN TIMING ANALYSIEREN ==="

./pi5-ssh.sh << 'EOF_TIMING'
echo "=== FT6236 Delay Service ==="
systemctl status ft6236-delay.service --no-pager -l | head -20

echo ""
echo "=== Service Abhängigkeiten ==="
systemctl list-dependencies ft6236-delay.service --no-pager | head -15
EOF_TIMING

log ""
log "=== SCHRITT 3: XORG KONFIGURATION PRÜFEN ==="

./pi5-ssh.sh << 'EOF_XORG'
echo "=== Xorg Touchscreen Configs ==="
find /etc/X11/xorg.conf.d/ -name "*touch*" -o -name "*libinput*" 2>/dev/null | while read f; do
    echo "--- $f ---"
    cat "$f" 2>/dev/null | head -30
    echo ""
done
EOF_XORG

log ""
log "=== SCHRITT 4: SAUBERE LÖSUNG IMPLEMENTIEREN ==="

# Erstelle einheitliche Touchscreen-Konfiguration
./pi5-ssh.sh << 'EOF_FIX'
# Erstelle einheitliche Xorg Config
cat > /tmp/99-touchscreen-unified.conf << 'XORG_EOF'
Section "InputClass"
    Identifier "WaveShare Touchscreen"
    MatchProduct "WaveShare|FT6236"
    MatchDevicePath "/dev/input/event*"
    Driver "libinput"
    Option "CalibrationMatrix" "0 -1 1 1 0 0 0 0 1"
    Option "SendEventsMode" "enabled"
    Option "AccelProfile" "flat"
EndSection
XORG_EOF

sudo mv /tmp/99-touchscreen-unified.conf /etc/X11/xorg.conf.d/
echo "✅ Einheitliche Xorg Config erstellt"

# Entferne alte/duplizierte Configs
sudo rm -f /etc/X11/xorg.conf.d/40-libinput-touchscreen.conf
sudo rm -f /etc/X11/xorg.conf.d/99-touchscreen-events.conf
echo "✅ Alte Configs entfernt"
EOF_FIX

log ""
log "=== SCHRITT 5: TOUCHSCREEN SERVICE OPTIMIEREN ==="

# Optimiere ft6236-delay.service
./pi5-ssh.sh << 'EOF_SERVICE'
cat > /tmp/ft6236-delay-optimized.service << 'SERVICE_EOF'
[Unit]
Description=Load FT6236 Touchscreen after Display
After=graphical.target
After=xserver-ready.service
Wants=graphical.target
Wants=xserver-ready.service
Requires=graphical.target

[Service]
Type=oneshot
ExecStartPre=/bin/sleep 2
ExecStart=/sbin/modprobe ft6236
ExecStartPost=/bin/sleep 1
RemainAfterExit=yes
TimeoutStartSec=10

[Install]
WantedBy=graphical.target
SERVICE_EOF

sudo mv /tmp/ft6236-delay-optimized.service /etc/systemd/system/ft6236-delay.service
sudo systemctl daemon-reload
sudo systemctl enable ft6236-delay.service
echo "✅ ft6236-delay.service optimiert"
EOF_SERVICE

log ""
log "=== SCHRITT 6: TOUCHSCREEN-FIX SERVICE ENTFERNEN ==="

# Entferne touchscreen-fix.service (Workaround)
./pi5-ssh.sh << 'EOF_REMOVE'
if systemctl is-enabled touchscreen-fix.service >/dev/null 2>&1; then
    sudo systemctl disable touchscreen-fix.service
    sudo systemctl stop touchscreen-fix.service
    echo "✅ touchscreen-fix.service entfernt (Workaround)"
fi
EOF_REMOVE

log ""
log "=== ZUSAMMENFASSUNG ==="
log "✅ Einheitliche Xorg Config erstellt"
log "✅ ft6236-delay.service optimiert"
log "✅ Alte Workarounds entfernt"
log ""
log "Nächste Schritte:"
log "  1. Reboot durchführen"
log "  2. Touchscreen sollte zuverlässig funktionieren"

echo "==========================================" | tee -a "$LOG_FILE"
echo "✅ SAUBERE TOUCHSCREEN LÖSUNG IMPLEMENTIERT" | tee -a "$LOG_FILE"
echo "==========================================" | tee -a "$LOG_FILE"

