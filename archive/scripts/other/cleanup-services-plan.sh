#!/bin/bash
# Service Cleanup Plan - VOR IMPLEMENTIERUNG
# Zeigt was entfernt wird, OHNE es zu tun

PI5_ALIAS="pi2"
PI5_IP="192.168.178.143"
LOG_FILE="cleanup-services-plan-$(date +%Y%m%d_%H%M%S).log"

log() {
    echo "[$(date +%H:%M:%S)] $1" | tee -a "$LOG_FILE"
}

echo "=== SERVICE CLEANUP PLAN ===" | tee -a "$LOG_FILE"
echo "Dieses Script zeigt, was entfernt wird, OHNE es zu tun!" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

# Prüfe ob Pi 5 online ist
if ! ping -c 1 -W 1000 "$PI5_IP" >/dev/null 2>&1; then
    log "❌ Pi 5 ist offline"
    exit 1
fi
log "✅ Pi 5 ist online"

log ""
log "=== SERVICES DIE ENTFERNT WERDEN ==="
log ""

# Redundante Touchscreen-Services
log "1. Redundante Touchscreen-Services:"
./pi5-ssh.sh "systemctl is-enabled touchscreen-fix.service 2>/dev/null && echo '  - touchscreen-fix.service: AKTIV' || echo '  - touchscreen-fix.service: NICHT AKTIV'" | tee -a "$LOG_FILE"
./pi5-ssh.sh "systemctl is-enabled touchscreen-bind.service 2>/dev/null && echo '  - touchscreen-bind.service: AKTIV' || echo '  - touchscreen-bind.service: NICHT AKTIV'" | tee -a "$LOG_FILE"
./pi5-ssh.sh "systemctl is-enabled waveshare-touchscreen-delay.service 2>/dev/null && echo '  - waveshare-touchscreen-delay.service: AKTIV' || echo '  - waveshare-touchscreen-delay.service: NICHT AKTIV'" | tee -a "$LOG_FILE"

log ""
log "2. Redundante/Unnötige Services:"
./pi5-ssh.sh "systemctl is-enabled chromium-monitor.service 2>/dev/null && echo '  - chromium-monitor.service: AKTIV' || echo '  - chromium-monitor.service: NICHT AKTIV'" | tee -a "$LOG_FILE"
./pi5-ssh.sh "systemctl is-enabled samba-ad-dc.service 2>/dev/null && echo '  - samba-ad-dc.service: AKTIV' || echo '  - samba-ad-dc.service: NICHT AKTIV'" | tee -a "$LOG_FILE"
./pi5-ssh.sh "systemctl is-enabled display-rotate-fix.service 2>/dev/null && echo '  - display-rotate-fix.service: AKTIV' || echo '  - display-rotate-fix.service: NICHT AKTIV'" | tee -a "$LOG_FILE"

log ""
log "=== SERVICES DIE BLEIBEN ==="
log ""

log "Essentielle Services:"
./pi5-ssh.sh "systemctl is-enabled mpd.service 2>/dev/null && echo '  ✅ mpd.service: AKTIV' || echo '  ❌ mpd.service: NICHT AKTIV'" | tee -a "$LOG_FILE"
./pi5-ssh.sh "systemctl is-enabled localdisplay.service 2>/dev/null && echo '  ✅ localdisplay.service: AKTIV' || echo '  ❌ localdisplay.service: NICHT AKTIV'" | tee -a "$LOG_FILE"
./pi5-ssh.sh "systemctl is-enabled nginx.service 2>/dev/null && echo '  ✅ nginx.service: AKTIV' || echo '  ❌ nginx.service: NICHT AKTIV'" | tee -a "$LOG_FILE"
./pi5-ssh.sh "systemctl is-enabled php8.4-fpm.service 2>/dev/null && echo '  ✅ php8.4-fpm.service: AKTIV' || echo '  ❌ php8.4-fpm.service: NICHT AKTIV'" | tee -a "$LOG_FILE"

log ""
log "Touchscreen Service:"
./pi5-ssh.sh "systemctl is-enabled ft6236-delay.service 2>/dev/null && echo '  ✅ ft6236-delay.service: AKTIV' || echo '  ❌ ft6236-delay.service: NICHT AKTIV'" | tee -a "$LOG_FILE"

log ""
log "PeppyMeter Services:"
./pi5-ssh.sh "systemctl is-enabled peppymeter.service 2>/dev/null && echo '  ✅ peppymeter.service: AKTIV' || echo '  ❌ peppymeter.service: NICHT AKTIV'" | tee -a "$LOG_FILE"
./pi5-ssh.sh "systemctl is-enabled peppymeter-screensaver.service 2>/dev/null && echo '  ✅ peppymeter-screensaver.service: AKTIV' || echo '  ❌ peppymeter-screensaver.service: NICHT AKTIV'" | tee -a "$LOG_FILE"
./pi5-ssh.sh "systemctl is-enabled peppymeter-position.service 2>/dev/null && echo '  ✅ peppymeter-position.service: AKTIV' || echo '  ❌ peppymeter-position.service: NICHT AKTIV'" | tee -a "$LOG_FILE"
./pi5-ssh.sh "systemctl is-enabled peppymeter-window-fix.service 2>/dev/null && echo '  ✅ peppymeter-window-fix.service: AKTIV' || echo '  ❌ peppymeter-window-fix.service: NICHT AKTIV'" | tee -a "$LOG_FILE"

log ""
log "=== PEPPYMETER SCREENSAVER KONFIGURATION ==="
log ""

log "Aktuelle Konfiguration:"
./pi5-ssh.sh "grep -E 'INACTIVITY_TIMEOUT|timeout' /usr/local/bin/peppymeter-screensaver.sh 2>/dev/null | head -3" | tee -a "$LOG_FILE"

log ""
log "=== ZUSAMMENFASSUNG ==="
log ""
log "ZU ENTFERNEN: 6 Services"
log "BLEIBEN: 9 Services"
log ""
log "PeppyMeter Screensaver: 5 Minuten Inaktivität (zu konfigurieren)"
log ""
log "=========================================="
log "✅ PLAN ERSTELLT - BEREIT FÜR REVIEW"
log "=========================================="
log ""
log "Nächster Schritt: Script zur Implementierung erstellen"

