#!/bin/bash
################################################################################
#
# AUTONOMOUS SERIAL MONITOR
# 
# Überwacht Serial Console kontinuierlich und greift bei Problemen ein
#
################################################################################

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

SERIAL_PORT="/dev/cu.usbmodem214302"
BAUDRATE="115200"
LOG_FILE="$SCRIPT_DIR/serial-monitor-$(date +%Y%m%d_%H%M%S).log"
PI_IPS=("192.168.178.143" "192.168.178.161" "192.168.178.162")
PI_USER="andre"
PI_PASS="0815"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log "=== AUTONOMOUS SERIAL MONITOR START ==="

# Prüfe Serial Port
if [ ! -e "$SERIAL_PORT" ]; then
    log "❌ Serial-Port nicht gefunden: $SERIAL_PORT"
    exit 1
fi

log "✅ Serial-Port gefunden: $SERIAL_PORT"
log "📋 Baudrate: $BAUDRATE"

# Starte Serial Console Monitoring im Hintergrund
log "🔌 Starte Serial Console Monitoring..."
SERIAL_LOG="$LOG_FILE.serial"
(
    while true; do
        if [ -e "$SERIAL_PORT" ]; then
            # Verwende cu statt screen für macOS Kompatibilität
            timeout 10 cu -l "$SERIAL_PORT" -s "$BAUDRATE" 2>&1 | tee -a "$SERIAL_LOG" || \
            timeout 10 cat "$SERIAL_PORT" 2>&1 | tee -a "$SERIAL_LOG" || true
            sleep 1
        else
            log "⚠️  Serial-Port nicht verfügbar, warte..."
            sleep 5
        fi
    done
) &

SERIAL_PID=$!
log "✅ Serial Monitoring gestartet (PID: $SERIAL_PID)"

# Überwache Pi-Verbindung parallel
log "🔍 Überwache Pi-Verbindung..."
while true; do
    # Prüfe alle IPs
    for ip in "${PI_IPS[@]}"; do
        if ping -c 1 -W 1 "$ip" >/dev/null 2>&1; then
            log "✅ Pi erreichbar auf $ip"
            
            # Prüfe SSH
            if sshpass -p "$PI_PASS" ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 "$PI_USER@$ip" "echo 'SSH_OK'" >/dev/null 2>&1; then
                log "✅ SSH funktioniert auf $ip"
                
                # Führe automatisch Fixes aus
                log "🔧 Führe automatische Fixes aus..."
                
                # Prüfe first-boot-setup
                if sshpass -p "$PI_PASS" ssh -o StrictHostKeyChecking=no "$PI_USER@$ip" "test -f /var/lib/first-boot-setup.done" 2>/dev/null; then
                    log "✅ first-boot-setup bereits ausgeführt"
                else
                    log "⏳ first-boot-setup läuft noch..."
                fi
                
                # Prüfe Services
                sshpass -p "$PI_PASS" ssh -o StrictHostKeyChecking=no "$PI_USER@$ip" "
                    systemctl is-active localdisplay.service >/dev/null 2>&1 && echo 'localdisplay: aktiv' || echo 'localdisplay: inaktiv'
                    systemctl is-active first-boot-setup.service >/dev/null 2>&1 && echo 'first-boot-setup: aktiv' || echo 'first-boot-setup: inaktiv'
                " 2>/dev/null | tee -a "$LOG_FILE"
                
                # Prüfe Display
                sshpass -p "$PI_PASS" ssh -o StrictHostKeyChecking=no "$PI_USER@$ip" "
                    pgrep -x Xorg >/dev/null 2>&1 && echo 'X Server: läuft' || echo 'X Server: nicht läuft'
                    pgrep chromium >/dev/null 2>&1 && echo 'Chromium: läuft' || echo 'Chromium: nicht läuft'
                " 2>/dev/null | tee -a "$LOG_FILE"
                
                log "✅ Pi-Status geprüft und dokumentiert"
                break
            else
                log "⏳ SSH noch nicht bereit auf $ip"
            fi
        fi
    done
    
    sleep 5
done

