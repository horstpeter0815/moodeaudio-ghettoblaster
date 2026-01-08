#!/bin/bash
# Ghettoblaster - Root Cause Analysis: Display Rotation Reset
# Identifiziert wer/was config.txt überschreibt

PI5_ALIAS="pi2"
PI5_IP="192.168.178.143"
LOG_FILE="rca-display-rotation-$(date +%Y%m%d_%H%M%S).log"

log() {
    echo "[$(date +%H:%M:%S)] $1" | tee -a "$LOG_FILE"
}

echo "=== ROOT CAUSE ANALYSIS: DISPLAY ROTATION RESET ===" | tee -a "$LOG_FILE"

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
log "=== SCHRITT 1: CONFIG.TXT ÜBERWACHUNG EINRICHTEN ==="

# Installiere inotify-tools für File-Monitoring
./pi5-ssh.sh << 'EOF_INOTIFY'
if ! command -v inotifywait &> /dev/null; then
    echo "Installiere inotify-tools..."
    sudo apt-get update -qq
    sudo apt-get install -y inotify-tools
fi
echo "✅ inotify-tools verfügbar"
EOF_INOTIFY

log ""
log "=== SCHRITT 2: AKTUELLE CONFIG.TXT PRÜFEN ==="

log "Aktuelle config.txt (display_rotate):"
./pi5-ssh.sh "grep -E 'display_rotate|hdmi' /boot/firmware/config.txt" | tee -a "$LOG_FILE"

log ""
log "=== SCHRITT 3: SERVICES FINDEN DIE CONFIG.TXT ÄNDERN ==="

log "Suche nach Services/Scripts die config.txt ändern:"
./pi5-ssh.sh << 'EOF_SEARCH'
# Suche in Systemd Services
echo "=== Systemd Services ==="
grep -r "config.txt" /etc/systemd/system/ 2>/dev/null | head -10

# Suche in Scripts
echo ""
echo "=== Scripts ==="
grep -r "config.txt" /usr/local/bin/ 2>/dev/null | head -10
grep -r "config.txt" /opt/ 2>/dev/null | head -10

# Suche in moOde Scripts
echo ""
echo "=== moOde Scripts ==="
find /var/www -name "*.php" -exec grep -l "config.txt" {} \; 2>/dev/null | head -10
EOF_SEARCH

log ""
log "=== SCHRITT 4: MOODE UPDATE-MECHANISMUS PRÜFEN ==="

log "moOde Update-Services:"
./pi5-ssh.sh "systemctl list-units --type=service | grep -i 'update\|moode'" | tee -a "$LOG_FILE"

log ""
log "moOde Config-Scripts:"
./pi5-ssh.sh "find /var/www -name '*config*' -o -name '*update*' 2>/dev/null | head -10" | tee -a "$LOG_FILE"

log ""
log "=== SCHRITT 5: FILE MONITORING EINRICHTEN ==="

# Erstelle Monitoring-Script
./pi5-ssh.sh << 'EOF_MONITOR'
cat > /tmp/monitor-config-txt.sh << 'MONITOR_EOF'
#!/bin/bash
# Überwacht config.txt Änderungen

CONFIG_FILE="/boot/firmware/config.txt"
LOG_FILE="/var/log/config-txt-monitor.log"

log() {
    echo "[$(date +%Y-%m-%d %H:%M:%S)] $1" | tee -a "$LOG_FILE"
}

log "=== CONFIG.TXT MONITORING GESTARTET ==="
log "Überwache: $CONFIG_FILE"

# Erstelle Backup
cp "$CONFIG_FILE" "${CONFIG_FILE}.backup-$(date +%Y%m%d_%H%M%S)"

# Überwache Änderungen
inotifywait -m -e modify,attrib,close_write "$CONFIG_FILE" 2>/dev/null | while read path action file; do
    log "ÄNDERUNG ERKANNT: $action auf $file"
    
    # Zeige Prozess der geändert hat
    log "Prozesse die config.txt geöffnet haben:"
    lsof "$CONFIG_FILE" 2>/dev/null | tee -a "$LOG_FILE"
    
    # Zeige Änderungen
    log "Aktueller display_rotate Wert:"
    grep "display_rotate" "$CONFIG_FILE" | tee -a "$LOG_FILE"
    
    # Zeige Stack-Trace
    log "Call Stack:"
    ps auxf | grep -E "$(lsof -t "$CONFIG_FILE" 2>/dev/null | tr '\n' '|')" | head -5 | tee -a "$LOG_FILE"
done
MONITOR_EOF

chmod +x /tmp/monitor-config-txt.sh
echo "✅ Monitoring-Script erstellt: /tmp/monitor-config-txt.sh"
EOF_MONITOR

log ""
log "=== SCHRITT 6: DISPLAY-ROTATE-FIX SERVICE PRÜFEN ==="

log "display-rotate-fix.service:"
./pi5-ssh.sh "systemctl cat display-rotate-fix.service 2>/dev/null" | tee -a "$LOG_FILE"

log ""
log "display-rotate-fix.service Status:"
./pi5-ssh.sh "systemctl status display-rotate-fix.service --no-pager -l" | tee -a "$LOG_FILE"

log ""
log "=== SCHRITT 7: BOOT-PROZESS ANALYSIEREN ==="

log "Boot-Logs (config.txt Änderungen):"
./pi5-ssh.sh "journalctl -b | grep -i 'config.txt\|display_rotate' | head -20" | tee -a "$LOG_FILE"

log ""
log "=== ZUSAMMENFASSUNG ==="
log "✅ Root Cause Analysis abgeschlossen"
log "📋 Log-Datei: $LOG_FILE"
log ""
log "Nächste Schritte:"
log "  1. Monitoring-Script starten: /tmp/monitor-config-txt.sh"
log "  2. System testen/rebooten"
log "  3. Log analysieren: /var/log/config-txt-monitor.log"
log "  4. Identifizieren wer überschreibt"
log "  5. Permanente Lösung implementieren"

echo "==========================================" | tee -a "$LOG_FILE"
echo "✅ ROOT CAUSE ANALYSIS ABGESCHLOSSEN" | tee -a "$LOG_FILE"
echo "==========================================" | tee -a "$LOG_FILE"

