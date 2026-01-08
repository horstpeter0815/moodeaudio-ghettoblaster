#!/bin/bash
# Service Cleanup Implementation
# Entfernt redundante Services und konfiguriert PeppyMeter Screensaver auf 5 Minuten

PI5_ALIAS="pi2"
PI5_IP="192.168.178.143"
LOG_FILE="service-cleanup-$(date +%Y%m%d_%H%M%S).log"
DRY_RUN=${1:-"plan"}  # "plan" oder "execute"

log() {
    echo "[$(date +%H:%M:%S)] $1" | tee -a "$LOG_FILE"
}

execute() {
    if [ "$DRY_RUN" = "execute" ]; then
        ./pi5-ssh.sh "$@"
    else
        log "  [PLAN] Würde ausführen: $*"
    fi
}

echo "=== SERVICE CLEANUP IMPLEMENTATION ===" | tee -a "$LOG_FILE"
if [ "$DRY_RUN" = "plan" ]; then
    echo "MODE: PLAN (zeigt was gemacht wird, ohne es zu tun)" | tee -a "$LOG_FILE"
    echo "Zum Ausführen: $0 execute" | tee -a "$LOG_FILE"
else
    echo "MODE: EXECUTE (führt Änderungen durch)" | tee -a "$LOG_FILE"
fi
echo "" | tee -a "$LOG_FILE"

# Prüfe ob Pi 5 online ist
if ! ping -c 1 -W 1000 "$PI5_IP" >/dev/null 2>&1; then
    log "❌ Pi 5 ist offline"
    exit 1
fi
log "✅ Pi 5 ist online"

log ""
log "=== SCHRITT 1: PEPPYMETER SCREENSAVER AUF 5 MINUTEN SETZEN ==="
log ""

log "Aktuelle Konfiguration prüfen:"
./pi5-ssh.sh "grep 'INACTIVITY_TIMEOUT=' /usr/local/bin/peppymeter-screensaver.sh 2>/dev/null | head -1" | tee -a "$LOG_FILE"

log ""
log "Konfiguration ändern (600 Sekunden → 300 Sekunden):"
execute << 'EOF_PEPPY'
SCREENSAVER_SCRIPT="/usr/local/bin/peppymeter-screensaver.sh"
if [ -f "$SCREENSAVER_SCRIPT" ]; then
    sudo sed -i 's/INACTIVITY_TIMEOUT=600/INACTIVITY_TIMEOUT=300/' "$SCREENSAVER_SCRIPT"
    echo "✅ PeppyMeter Screensaver auf 5 Minuten (300 Sekunden) gesetzt"
    grep 'INACTIVITY_TIMEOUT=' "$SCREENSAVER_SCRIPT" | head -1
else
    echo "⚠️  Script nicht gefunden: $SCREENSAVER_SCRIPT"
fi
EOF_PEPPY

log ""
log "=== SCHRITT 2: REDUNDANTE TOUCHSCREEN-SERVICES ENTFERNEN ==="
log ""

log "1. touchscreen-fix.service:"
execute "sudo systemctl disable touchscreen-fix.service"
execute "sudo systemctl stop touchscreen-fix.service"
execute "sudo rm -f /etc/systemd/system/touchscreen-fix.service"

log ""
log "2. touchscreen-bind.service:"
execute "sudo systemctl disable touchscreen-bind.service"
execute "sudo systemctl stop touchscreen-bind.service"
execute "sudo rm -f /etc/systemd/system/touchscreen-bind.service"

log ""
log "3. waveshare-touchscreen-delay.service:"
execute "sudo systemctl disable waveshare-touchscreen-delay.service"
execute "sudo systemctl stop waveshare-touchscreen-delay.service"
execute "sudo rm -f /etc/systemd/system/waveshare-touchscreen-delay.service"

log ""
log "=== SCHRITT 3: REDUNDANTE/UNNÖTIGE SERVICES ENTFERNEN ==="
log ""

log "4. chromium-monitor.service:"
execute "sudo systemctl disable chromium-monitor.service"
execute "sudo systemctl stop chromium-monitor.service"
execute "sudo rm -f /etc/systemd/system/chromium-monitor.service"

log ""
log "5. samba-ad-dc.service:"
execute "sudo systemctl disable samba-ad-dc.service"
execute "sudo systemctl stop samba-ad-dc.service"

log ""
log "6. display-rotate-fix.service:"
execute "sudo systemctl disable display-rotate-fix.service"
execute "sudo systemctl stop display-rotate-fix.service"
execute "sudo rm -f /etc/systemd/system/display-rotate-fix.service"

log ""
log "=== SCHRITT 4: SYSTEMCTL DAEMON-RELOAD ==="
log ""
execute "sudo systemctl daemon-reload"

log ""
log "=== SCHRITT 5: VERIFIKATION ==="
log ""

log "Verbleibende Services prüfen:"
./pi5-ssh.sh "systemctl is-enabled ft6236-delay.service 2>/dev/null && echo '✅ ft6236-delay.service: AKTIV' || echo '❌ ft6236-delay.service: NICHT AKTIV'" | tee -a "$LOG_FILE"
./pi5-ssh.sh "systemctl is-enabled peppymeter-screensaver.service 2>/dev/null && echo '✅ peppymeter-screensaver.service: AKTIV' || echo '❌ peppymeter-screensaver.service: NICHT AKTIV'" | tee -a "$LOG_FILE"

log ""
log "Entfernte Services prüfen:"
./pi5-ssh.sh "systemctl is-enabled touchscreen-fix.service 2>/dev/null && echo '⚠️  touchscreen-fix.service: NOCH AKTIV!' || echo '✅ touchscreen-fix.service: ENTFERNT'" | tee -a "$LOG_FILE"
./pi5-ssh.sh "systemctl is-enabled chromium-monitor.service 2>/dev/null && echo '⚠️  chromium-monitor.service: NOCH AKTIV!' || echo '✅ chromium-monitor.service: ENTFERNT'" | tee -a "$LOG_FILE"

log ""
log "PeppyMeter Screensaver Konfiguration:"
./pi5-ssh.sh "grep 'INACTIVITY_TIMEOUT=' /usr/local/bin/peppymeter-screensaver.sh 2>/dev/null | head -1" | tee -a "$LOG_FILE"

echo "==========================================" | tee -a "$LOG_FILE"
if [ "$DRY_RUN" = "plan" ]; then
    echo "✅ PLAN ERSTELLT" | tee -a "$LOG_FILE"
    echo "==========================================" | tee -a "$LOG_FILE"
    echo "" | tee -a "$LOG_FILE"
    echo "Zum Ausführen:" | tee -a "$LOG_FILE"
    echo "  ./implement-service-cleanup.sh execute" | tee -a "$LOG_FILE"
else
    echo "✅ IMPLEMENTIERUNG ABGESCHLOSSEN" | tee -a "$LOG_FILE"
    echo "==========================================" | tee -a "$LOG_FILE"
    echo "" | tee -a "$LOG_FILE"
    echo "Nächster Schritt: Reboot empfohlen" | tee -a "$LOG_FILE"
fi

