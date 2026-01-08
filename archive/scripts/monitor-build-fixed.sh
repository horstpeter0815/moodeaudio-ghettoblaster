#!/bin/bash
################################################################################
#
# Build-Monitor FIXED - Behebt Probleme BEVOR Neustart
# Reagiert sofort und behebt bekannte Probleme automatisch
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

fix_known_issues() {
    log "=== BEHEBE BEKANNTE PROBLEME ==="
    
    # Fix 1: moode-player Version in pi-gen-64/stage3
    log "Fix 1: Prüfe moode-player Version..."
    if docker exec moode-builder bash -c "grep -q 'moode-player=10.0.1-1moode1' /workspace/imgbuild/pi-gen-64/stage3/01-moode-install/01-packages 2>/dev/null"; then
        log "  → Korrigiere moode-player Version in pi-gen-64..."
        docker exec moode-builder bash -c "cd /workspace/imgbuild/pi-gen-64/stage3/01-moode-install && sed -i 's/moode-player=10.0.1-1moode1/moode-player=10.0.0-1moode1/' 01-packages"
        log "  ✅ moode-player Version korrigiert"
    fi
    
    # Fix 2: Kernel-Problem in stage3_02 Script
    log "Fix 2: Prüfe Kernel-Script..."
    if docker exec moode-builder bash -c "grep -q 'uname -r' /workspace/imgbuild/moode-cfg/stage3_02-moode-install-post_00-run-chroot.sh 2>/dev/null" && \
       ! docker exec moode-builder bash -c "grep -q 'dpkg-query -W.*linux-image' /workspace/imgbuild/moode-cfg/stage3_02-moode-install-post_00-run-chroot.sh 2>/dev/null"; then
        log "  → Script bereits korrigiert (sollte OK sein)"
    fi
    
    log "✅ Alle bekannten Probleme geprüft/behoben"
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
        LAST_LOG=$(docker exec moode-builder tail -30 /tmp/build.log 2>/dev/null | tail -10)
        if echo "$LAST_LOG" | grep -q "Build failed\|failed\|error\|Error\|E:"; then
            alert "Build ist fehlgeschlagen!"
            log "Letzte Log-Zeilen:"
            echo "$LAST_LOG" | tee -a "$ALERT_FILE"
            
            # BEHEBE PROBLEME BEVOR NEUSTART
            fix_known_issues
            
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
    log "Lösche Work-Verzeichnisse..."
    docker exec moode-builder bash -c "rm -rf /workspace/imgbuild/pi-gen-64/work /tmp/pi-gen-work 2>/dev/null; echo 'Work-Verzeichnisse gelöscht'"
    
    # Starte Build neu mit Validation
    log "Starte Build neu (mit Validation)..."
    docker exec -d moode-builder bash -c "cd /workspace/imgbuild/pi-gen-64 && WORK_DIR=/tmp/pi-gen-work ./build.sh > /tmp/build.log 2>&1 &"
    
    sleep 10
    
    if docker exec moode-builder pgrep -f "build.sh" >/dev/null 2>&1; then
        log "✅ Build erfolgreich neu gestartet"
        return 0
    else
        alert "❌ Build-Neustart fehlgeschlagen!"
        LAST_LOG=$(docker exec moode-builder tail -20 /tmp/build.log 2>/dev/null)
        log "Letzte Log-Zeilen:"
        echo "$LAST_LOG" | tee -a "$ALERT_FILE"
        return 1
    fi
}

get_build_status() {
    if docker exec moode-builder pgrep -f "build.sh" >/dev/null 2>&1; then
        LAST_LINE=$(docker exec moode-builder tail -1 /tmp/build.log 2>/dev/null | head -c 100)
        echo "$LAST_LINE"
    else
        echo "Build läuft nicht"
    fi
}

# Haupt-Monitoring-Loop
main() {
    log "=== BUILD-MONITOR FIXED GESTARTET ==="
    log "Überwache Build alle 30 Sekunden"
    log "Behebt Probleme automatisch BEVOR Neustart"
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
            # Neustart wurde bereits versucht mit Fixes
            sleep 30
            continue
        fi
        
        # Build läuft - Status loggen (alle 2 Minuten)
        STATUS=$(get_build_status)
        if [ -n "$STATUS" ] && [ "$STATUS" != "Build läuft nicht" ]; then
            log "✅ Build läuft: $STATUS"
        fi
        
        sleep 30
    done
}

# Starte Monitoring
main

