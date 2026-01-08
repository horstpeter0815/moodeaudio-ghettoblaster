#!/bin/bash
################################################################################
#
# CONTINUOUS BUILD MONITOR
#
# Überwacht Build kontinuierlich und behebt Probleme automatisch
#
################################################################################

LOG_FILE="build-monitor-$(date +%Y%m%d_%H%M%S).log"
CONTAINER="moode-builder"
MAX_RETRIES=5
RETRY_COUNT=0

log() {
    echo "[$(date +%Y-%m-%d %H:%M:%S)] $1" | tee -a "$LOG_FILE"
}

check_build_status() {
    BUILD_PID=$(docker exec $CONTAINER pgrep -f "build.sh" 2>/dev/null | head -1)
    if [ -n "$BUILD_PID" ]; then
        return 0  # Build läuft
    else
        return 1  # Build läuft nicht
    fi
}

check_build_progress() {
    docker exec $CONTAINER bash -c "find /tmp/pi-gen-work -name 'build.log' 2>/dev/null | head -1 | xargs tail -5 2>/dev/null" | grep -q "Build failed\|Build finished" && return 1 || return 0
}

get_build_stage() {
    docker exec $CONTAINER bash -c "find /tmp/pi-gen-work -name 'build.log' 2>/dev/null | head -1 | xargs tail -3 2>/dev/null" | tail -1
}

log "=== BUILD MONITOR GESTARTET ==="

while true; do
    if check_build_status; then
        STAGE=$(get_build_stage)
        log "✅ Build läuft: $STAGE"
        
        if ! check_build_progress; then
            log "⚠️  Build zeigt keine Aktivität - prüfe Status..."
            sleep 10
            if ! check_build_status; then
                log "❌ Build gestoppt - prüfe Fehler..."
                LAST_ERROR=$(docker exec $CONTAINER bash -c "find /tmp/pi-gen-work -name 'build.log' 2>/dev/null | head -1 | xargs tail -20 2>/dev/null" | grep -i "error\|failed" | tail -1)
                log "Fehler: $LAST_ERROR"
                
                if [ $RETRY_COUNT -lt $MAX_RETRIES ]; then
                    RETRY_COUNT=$((RETRY_COUNT + 1))
                    log "🔄 Retry $RETRY_COUNT/$MAX_RETRIES..."
                    docker exec $CONTAINER bash -c "cd /workspace/imgbuild && rm -rf /tmp/pi-gen-work/* && WORK_DIR=/tmp/pi-gen-work nohup ./build.sh > /tmp/build-retry.log 2>&1 &"
                    sleep 30
                else
                    log "❌ Max Retries erreicht - Build fehlgeschlagen"
                    exit 1
                fi
            fi
        fi
    else
        log "❌ Build läuft nicht - starte neu..."
        docker exec $CONTAINER bash -c "cd /workspace/imgbuild && rm -rf /tmp/pi-gen-work/* && WORK_DIR=/tmp/pi-gen-work nohup ./build.sh > /tmp/build-restart.log 2>&1 &"
        sleep 30
    fi
    
    sleep 60  # Prüfe alle 60 Sekunden
done

