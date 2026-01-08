#!/bin/bash
# Reboot-Test um Boot-Screen-Nachricht zu verifizieren

PI5_ALIAS="pi2"
PI5_IP="192.168.178.143"
LOG_FILE="reboot-test-$(date +%Y%m%d_%H%M%S).log"

log() {
    echo "[$(date +%H:%M:%S)] $1" | tee -a "$LOG_FILE"
}

echo "=== REBOOT TEST - BOOT SCREEN MESSAGE ===" | tee -a "$LOG_FILE"

# Prüfe ob Pi 5 online ist
if ! ping -c 1 -W 1000 "$PI5_IP" >/dev/null 2>&1; then
    log "❌ Pi 5 ist offline"
    exit 1
fi
log "✅ Pi 5 ist online"

log "1. Verifiziere Boot-Screen-Nachricht vor Reboot..."
log "   /etc/issue:"
./pi5-ssh.sh "cat /etc/issue" | tee -a "$LOG_FILE"
log ""
log "   /etc/motd:"
./pi5-ssh.sh "cat /etc/motd" | head -20 | tee -a "$LOG_FILE"

log ""
log "2. Starte Reboot..."
./pi5-ssh.sh "sudo reboot" || true

log ""
log "3. Warte auf Pi 5 nach Reboot (max. 2 Minuten)..."
for i in {1..120}; do
    sleep 1
    if ping -c 1 -W 1000 "$PI5_IP" >/dev/null 2>&1; then
        if ssh -o ConnectTimeout=5 "$PI5_ALIAS" "echo 'Online!'" >/dev/null 2>&1; then
            log "✅ Pi 5 ist nach Reboot online (nach $i Sekunden)"
            break
        fi
    fi
    if [ $i -eq 120 ]; then
        log "⚠️  Pi 5 ist nach 2 Minuten noch nicht online"
        log "   Bitte manuell prüfen"
        exit 1
    fi
done

log ""
log "4. Verifiziere System-Status nach Reboot..."
log "   Services:"
./pi5-ssh.sh "systemctl is-active localdisplay.service && echo 'localdisplay: OK' || echo 'localdisplay: FAILED'" | tee -a "$LOG_FILE"
./pi5-ssh.sh "systemctl is-active mpd.service && echo 'mpd: OK' || echo 'mpd: FAILED'" | tee -a "$LOG_FILE"
./pi5-ssh.sh "systemctl is-active chromium-monitor.service && echo 'chromium-monitor: OK' || echo 'chromium-monitor: FAILED'" | tee -a "$LOG_FILE"

log ""
log "5. Verifiziere Boot-Screen-Nachricht nach Reboot..."
log "   /etc/issue:"
./pi5-ssh.sh "cat /etc/issue" | tee -a "$LOG_FILE"

echo "==========================================" | tee -a "$LOG_FILE"
echo "✅ REBOOT TEST ABGESCHLOSSEN" | tee -a "$LOG_FILE"
echo "==========================================" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"
echo "Bitte prüfe den Boot-Screen physisch am Pi 5!" | tee -a "$LOG_FILE"
echo "Die Nachricht sollte beim Booten sichtbar sein." | tee -a "$LOG_FILE"

