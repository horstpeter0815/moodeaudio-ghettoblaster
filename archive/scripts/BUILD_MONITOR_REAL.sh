#!/bin/bash
################################################################################
#
# BUILD MONITOR - WIRKLICH FUNKTIONIEREND
#
# Überwacht Build kontinuierlich und dokumentiert Status
#
################################################################################

CONTAINER="moode-builder"
LOG_FILE="build-monitor-real-$(date +%Y%m%d_%H%M%S).log"
STATUS_FILE="BUILD_STATUS_REAL.txt"

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

get_build_stage() {
    docker exec $CONTAINER bash -c "find /tmp/pi-gen-work -name 'build.log' 2>/dev/null | head -1 | xargs tail -1 2>/dev/null" | grep -oE '\[.*\]' | tail -1 || echo "unbekannt"
}

check_build_failed() {
    docker exec $CONTAINER bash -c "find /tmp/pi-gen-work -name 'build.log' 2>/dev/null | head -1 | xargs tail -5 2>/dev/null" | grep -q "Build failed" && return 0 || return 1
}

log "=== BUILD MONITOR GESTARTET ==="

while true; do
    if check_build; then
        STAGE=$(get_build_stage)
        log "✅ Build läuft: $STAGE"
        
        if check_build_failed; then
            log "❌ BUILD FEHLGESCHLAGEN"
            ERROR=$(docker exec $CONTAINER bash -c "find /tmp/pi-gen-work -name 'build.log' 2>/dev/null | head -1 | xargs tail -30 2>/dev/null" | grep -A 5 "Build failed" | tail -10)
            log "Fehler: $ERROR"
            break
        fi
    else
        if check_build_failed; then
            log "❌ BUILD FEHLGESCHLAGEN"
            break
        else
            log "⚠️  Build läuft nicht - prüfe..."
            sleep 10
            if ! check_build; then
                log "❌ Build gestoppt"
                break
            fi
        fi
    fi
    
    sleep 30
done

log "=== BUILD MONITOR BEENDET ==="

