#!/bin/bash
# MONITOR_BUILD_30.sh
# Monitors Build #30 and validates image when complete

set -e

LOG_FILE="build-30-monitor-$(date +%Y%m%d_%H%M%S).log"
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log "=== BUILD #30 MONITOR START ==="

# Wait for build to complete
log "Warte auf Build-Abschluss..."
LAST_IMAGE_COUNT=$(ls imgbuild/deploy/*.img 2>/dev/null | wc -l)

while true; do
    sleep 60
    
    # Check if new image appeared
    CURRENT_IMAGE_COUNT=$(ls imgbuild/deploy/*.img 2>/dev/null | wc -l)
    NEWEST_IMAGE=$(ls -t imgbuild/deploy/*.img 2>/dev/null | head -1)
    
    if [ "$CURRENT_IMAGE_COUNT" -gt "$LAST_IMAGE_COUNT" ]; then
        log "✅ Neues Image erkannt: $(basename "$NEWEST_IMAGE")"
        log "   Warte 30 Sekunden für Datei-Vollständigkeit..."
        sleep 30
        
        # Check if image is complete (not growing)
        IMAGE_SIZE_1=$(stat -f%z "$NEWEST_IMAGE" 2>/dev/null || stat -c%s "$NEWEST_IMAGE" 2>/dev/null || echo "0")
        sleep 10
        IMAGE_SIZE_2=$(stat -f%z "$NEWEST_IMAGE" 2>/dev/null || stat -c%s "$NEWEST_IMAGE" 2>/dev/null || echo "0")
        
        if [ "$IMAGE_SIZE_1" -eq "$IMAGE_SIZE_2" ] && [ "$IMAGE_SIZE_1" -gt 1000000000 ]; then
            log "✅ Image vollständig (${IMAGE_SIZE_1} bytes)"
            log ""
            log "=== STARTE VALIDIERUNG ==="
            bash VALIDATE_BUILD_IMAGE.sh
            VALIDATION_EXIT=$?
            
            if [ $VALIDATION_EXIT -eq 0 ]; then
                log "✅ BUILD #30 VALIDIERUNG ERFOLGREICH"
                log "=== BUILD #30 MONITOR SUCCESS ==="
                exit 0
            else
                log "❌ BUILD #30 VALIDIERUNG FEHLGESCHLAGEN"
                log "=== BUILD #30 MONITOR FAILED ==="
                exit 1
            fi
        else
            log "⚠️  Image wächst noch (${IMAGE_SIZE_1} -> ${IMAGE_SIZE_2} bytes)"
        fi
    fi
    
    # Check if build process is still running
    if ! ps aux | grep -E "build.sh|pi-gen" | grep -v grep >/dev/null 2>&1; then
        log "⚠️  Build-Prozess nicht mehr aktiv"
        log "   Prüfe ob Image vorhanden..."
        
        if [ -n "$NEWEST_IMAGE" ] && [ -f "$NEWEST_IMAGE" ]; then
            log "✅ Image gefunden, starte Validierung..."
            bash VALIDATE_BUILD_IMAGE.sh
            exit $?
        else
            log "❌ Kein Image gefunden - Build möglicherweise fehlgeschlagen"
            exit 1
        fi
    fi
    
    LAST_IMAGE_COUNT=$CURRENT_IMAGE_COUNT
done

