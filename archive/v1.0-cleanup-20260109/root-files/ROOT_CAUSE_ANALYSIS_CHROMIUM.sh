#!/bin/bash
# Ghettoblaster - Root Cause Analysis: Chromium Start Problem
# Systematische Analyse statt Workaround

PI5_ALIAS="pi2"
PI5_IP="192.168.178.143"
LOG_FILE="rca-chromium-$(date +%Y%m%d_%H%M%S).log"

log() {
    echo "[$(date +%H:%M:%S)] $1" | tee -a "$LOG_FILE"
}

echo "=== ROOT CAUSE ANALYSIS: CHROMIUM START ===" | tee -a "$LOG_FILE"

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
log "=== SCHRITT 1: SERVICE-ABHÄNGIGKEITEN ANALYSIEREN ==="

log "localdisplay.service Abhängigkeiten:"
./pi5-ssh.sh "systemctl list-dependencies localdisplay.service --no-pager" | tee -a "$LOG_FILE"

log ""
log "localdisplay.service Status:"
./pi5-ssh.sh "systemctl status localdisplay.service --no-pager -l" | tee -a "$LOG_FILE"

log ""
log "=== SCHRITT 2: X SERVER TIMING ANALYSIEREN ==="

log "X Server Prozesse:"
./pi5-ssh.sh "ps aux | grep -E 'X|Xorg|weston'" | tee -a "$LOG_FILE"

log ""
log "X Server Logs (letzte 50 Zeilen):"
./pi5-ssh.sh "journalctl -u localdisplay.service -n 50 --no-pager" | tee -a "$LOG_FILE"

log ""
log "=== SCHRITT 3: CHROMIUM STARTUP ANALYSIEREN ==="

log "Chromium Prozesse:"
./pi5-ssh.sh "ps aux | grep -i chromium" | tee -a "$LOG_FILE"

log ""
log "Chromium Startup Script:"
./pi5-ssh.sh "cat /usr/local/bin/start-chromium-bulletproof.sh 2>/dev/null | head -50" | tee -a "$LOG_FILE"

log ""
log "=== SCHRITT 4: X SERVER READY CHECK ==="

log "Teste X Server Verfügbarkeit:"
./pi5-ssh.sh << 'EOF_XTEST'
export DISPLAY=:0
export XAUTHORITY=/home/andre/.Xauthority

# Test 1: xrandr
log "Test 1: xrandr --query"
timeout 5 xrandr --query 2>&1 && echo "✅ xrandr funktioniert" || echo "❌ xrandr fehlgeschlagen"

# Test 2: xdpyinfo
log "Test 2: xdpyinfo"
timeout 5 xdpyinfo -display :0 >/dev/null 2>&1 && echo "✅ xdpyinfo funktioniert" || echo "❌ xdpyinfo fehlgeschlagen"

# Test 3: DISPLAY Variable
log "Test 3: DISPLAY Variable"
echo "DISPLAY=$DISPLAY"
echo "XAUTHORITY=$XAUTHORITY"
EOF_XTEST

log ""
log "=== SCHRITT 5: SERVICE TIMING ANALYSIEREN ==="

log "Service Start-Zeiten:"
./pi5-ssh.sh "systemd-analyze blame | head -20" | tee -a "$LOG_FILE"

log ""
log "Service Critical Chain:"
./pi5-ssh.sh "systemd-analyze critical-chain localdisplay.service" | tee -a "$LOG_FILE"

log ""
log "=== SCHRITT 6: PERMISSIONS & LOCK FILES ==="

log "Chromium Lock Files:"
./pi5-ssh.sh "ls -la /tmp/chromium-data/ 2>/dev/null || echo 'Kein chromium-data Verzeichnis'" | tee -a "$LOG_FILE"

log ""
log "X Authority:"
./pi5-ssh.sh "ls -la /home/andre/.Xauthority 2>/dev/null || echo 'Kein .Xauthority'" | tee -a "$LOG_FILE"

log ""
log "=== SCHRITT 7: SYSTEMD UNIT ANALYSIEREN ==="

log "localdisplay.service Unit-Datei:"
./pi5-ssh.sh "systemctl cat localdisplay.service" | tee -a "$LOG_FILE"

log ""
log "=== ZUSAMMENFASSUNG ==="
log "✅ Root Cause Analysis abgeschlossen"
log "📋 Log-Datei: $LOG_FILE"
log ""
log "Nächste Schritte:"
log "  1. Analyse der Ergebnisse"
log "  2. Identifikation der Root Cause"
log "  3. Saubere Lösung implementieren"

echo "==========================================" | tee -a "$LOG_FILE"
echo "✅ ROOT CAUSE ANALYSIS ABGESCHLOSSEN" | tee -a "$LOG_FILE"
echo "==========================================" | tee -a "$LOG_FILE"

