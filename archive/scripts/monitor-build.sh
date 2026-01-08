#!/bin/bash
################################################################################
#
# Build-Monitor - Überwacht den Build kontinuierlich
# Reagiert sofort bei Problemen
#
################################################################################

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

export PATH="/Applications/Docker.app/Contents/Resources/bin:$PATH"

LOG_FILE="$SCRIPT_DIR/build-monitor.log"
ALERT_FILE="$SCRIPT_DIR/build-alert.log"

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

alert() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] ⚠️  ALERT: $1" | tee -a "$ALERT_FILE" | tee -a "$LOG_FILE"
}

check_docker() {
    if ! docker info >/dev/null 2>&1; then
        alert "Docker läuft nicht!"
        return 1
    fi
    return 0
}

check_container() {
    if ! docker ps | grep -q moode-builder; then
        alert "Container moode-builder läuft nicht!"
        return 1
    fi
    return 0
}

check_build_process() {
    if ! docker exec moode-builder pgrep -f "build.sh" >/dev/null 2>&1; then
        alert "Build-Prozess läuft nicht!"
        
        # Prüfe ob Build fehlgeschlagen ist
        LAST_LOG=$(docker exec moode-builder tail -20 /tmp/build.log 2>/dev/null | tail -5)
        if echo "$LAST_LOG" | grep -q "Build failed\|failed\|error\|Error"; then
            alert "Build ist fehlgeschlagen! Letzte Log-Zeilen:"
            echo "$LAST_LOG" | tee -a "$ALERT_FILE"
            
            # Versuche automatischen Neustart
            log "Versuche automatischen Neustart..."
            restart_build
        else
            alert "Build-Prozess nicht gefunden - unbekannter Zustand"
        fi
        return 1
    fi
    return 0
}

restart_build() {
    log "=== BUILD NEUSTART ==="
    
    # Prüfe Docker
    if ! check_docker; then
        alert "Kann nicht neu starten - Docker läuft nicht"
        return 1
    fi
    
    # Prüfe Container
    if ! check_container; then
        alert "Kann nicht neu starten - Container läuft nicht"
        return 1
    fi
    
    # Lösche fehlerhaftes Work-Verzeichnis
    docker exec moode-builder bash -c "cd /workspace/imgbuild/pi-gen-64 && rm -rf work 2>/dev/null; echo 'Work-Verzeichnis gelöscht'"
    
    # Starte Build neu
    log "Starte Build neu..."
    docker exec -d moode-builder bash -c "cd /workspace/imgbuild/pi-gen-64 && WORK_DIR=/tmp/pi-gen-work ./build.sh > /tmp/build.log 2>&1 &"
    
    sleep 5
    
    if docker exec moode-builder pgrep -f "build.sh" >/dev/null 2>&1; then
        log "✅ Build erfolgreich neu gestartet"
        return 0
    else
        alert "❌ Build-Neustart fehlgeschlagen!"
        return 1
    fi
}

get_build_status() {
    if docker exec moode-builder pgrep -f "build.sh" >/dev/null 2>&1; then
        LAST_LINE=$(docker exec moode-builder tail -1 /tmp/build.log 2>/dev/null)
        echo "$LAST_LINE"
    else
        echo "Build läuft nicht"
    fi
}

# Haupt-Monitoring-Loop
main() {
    log "=== BUILD-MONITOR GESTARTET ==="
    log "Überwache Build alle 60 Sekunden"
    log ""
    
    while true; do
        # Docker prüfen
        if ! check_docker; then
            sleep 30
            continue
        fi
        
        # Container prüfen
        if ! check_container; then
            sleep 30
            continue
        fi
        
        # Build-Prozess prüfen
        if ! check_build_process; then
            # Neustart wurde bereits versucht
            sleep 60
            continue
        fi
        
        # Build läuft - Status loggen
        STATUS=$(get_build_status)
        log "✅ Build läuft: $STATUS"
        
        sleep 60
    done
}

# Starte Monitoring
main

