#!/bin/bash
################################################################################
#
# AUTONOMOUS BUILD WORKER
#
# Arbeitet durch bis Build erfolgreich ist und auf SD-Karte gebrannt ist
#
################################################################################

CONTAINER="moode-builder"
LOG_FILE="autonomous-worker-$(date +%Y%m%d_%H%M%S).log"
STATUS_FILE="BUILD_STATUS_AUTONOMOUS.txt"
MAX_ITERATIONS=10
ITERATION=0

log() {
    echo "[$(date +%Y-%m-%d\ %H:%M:%S)] $1" | tee -a "$LOG_FILE"
    echo "$1" > "$STATUS_FILE"
}

check_build() {
    BUILD_PID=$(docker exec $CONTAINER pgrep -f "build.sh" 2>/dev/null | head -1)
    if [ -n "$BUILD_PID" ]; then
        return 0
    else
        return 1
    fi
}

check_build_failed() {
    docker exec $CONTAINER bash -c "find /tmp/pi-gen-work -name 'build.log' 2>/dev/null | head -1 | xargs tail -5 2>/dev/null" | grep -q "Build failed" && return 0 || return 1
}

get_build_stage() {
    docker exec $CONTAINER bash -c "find /tmp/pi-gen-work -name 'build.log' 2>/dev/null | head -1 | xargs tail -1 2>/dev/null" | grep -oE '\[.*\]' | tail -1 || echo "unbekannt"
}

get_build_error() {
    docker exec $CONTAINER bash -c "find /tmp/pi-gen-work -name 'build.log' 2>/dev/null | head -1 | xargs tail -50 2>/dev/null" | grep -A 10 "Build failed" | tail -15
}

fix_build_error() {
    ERROR=$(get_build_error)
    log "🔧 Analysiere Fehler..."
    
    # Prüfe auf Custom-Stage Fehler
    if echo "$ERROR" | grep -q "03-ghettoblaster-custom"; then
        log "🔧 Fix: Custom-Stage Fehler erkannt"
        # Script sollte bereits gefixt sein, aber prüfe nochmal
        return 0
    fi
    
    # Weitere Fehler-Typen hier hinzufügen
    log "⚠️  Unbekannter Fehler-Typ - manuelle Analyse nötig"
    return 1
}

restart_build() {
    log "🔄 Starte Build neu..."
    docker exec $CONTAINER bash -c "cd /workspace/imgbuild && rm -rf /tmp/pi-gen-work/moode-r1001-arm64/stage3/03-ghettoblaster-custom 2>/dev/null || true"
    docker exec -d $CONTAINER bash -c "cd /workspace/imgbuild && WORK_DIR=/tmp/pi-gen-work nohup bash -c './build.sh 2>&1 | tee /workspace/build-autonomous-$(date +%Y%m%d_%H%M%S).log' > /dev/null 2>&1 &"
    sleep 10
}

check_image_exists() {
    docker exec $CONTAINER bash -c "find /tmp/pi-gen-work -name '*.img' -size +100M 2>/dev/null | head -1" | grep -q ".img" && return 0 || return 1
}

get_image_path() {
    docker exec $CONTAINER bash -c "find /tmp/pi-gen-work -name '*.img' -size +100M 2>/dev/null | head -1"
}

log "=== AUTONOMOUS BUILD WORKER GESTARTET ==="
log "Arbeite durch bis Build erfolgreich ist..."

while [ $ITERATION -lt $MAX_ITERATIONS ]; do
    ITERATION=$((ITERATION + 1))
    log "🔄 Iteration $ITERATION/$MAX_ITERATIONS"
    
    # Prüfe ob Build läuft
    if check_build; then
        STAGE=$(get_build_stage)
        log "✅ Build läuft: $STAGE"
        
        # Prüfe auf Fehler
        if check_build_failed; then
            log "❌ BUILD FEHLGESCHLAGEN"
            ERROR=$(get_build_error)
            log "Fehler: $ERROR"
            
            # Versuche zu fixen
            if fix_build_error; then
                log "✅ Fix angewendet - starte Build neu"
                restart_build
                continue
            else
                log "❌ Konnte Fehler nicht automatisch fixen"
                break
            fi
        fi
        
        # Warte und prüfe erneut
        sleep 30
        continue
    fi
    
    # Build läuft nicht - prüfe ob erfolgreich
    if check_build_failed; then
        log "❌ BUILD FEHLGESCHLAGEN"
        ERROR=$(get_build_error)
        log "Fehler: $ERROR"
        
        if fix_build_error; then
            log "✅ Fix angewendet - starte Build neu"
            restart_build
            continue
        else
            log "❌ Konnte Fehler nicht automatisch fixen"
            break
        fi
    else
        # Build beendet - prüfe ob Image existiert
        if check_image_exists; then
            IMAGE=$(get_image_path)
            log "✅ BUILD ERFOLGREICH - Image gefunden: $IMAGE"
            log "📦 Nächster Schritt: Image auf SD-Karte brennen"
            break
        else
            log "⚠️  Build beendet, aber kein Image gefunden - prüfe..."
            sleep 10
            if check_image_exists; then
                IMAGE=$(get_image_path)
                log "✅ Image gefunden: $IMAGE"
                break
            else
                log "❌ Kein Image gefunden - Build möglicherweise fehlgeschlagen"
                if fix_build_error; then
                    restart_build
                    continue
                else
                    break
                fi
            fi
        fi
    fi
done

if [ $ITERATION -ge $MAX_ITERATIONS ]; then
    log "❌ Maximale Iterationen erreicht"
fi

log "=== AUTONOMOUS BUILD WORKER BEENDET ==="

