#!/bin/bash
################################################################################
#
# Build sicher starten - nur nach erfolgreicher Validation
#
################################################################################

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

export PATH="/Applications/Docker.app/Contents/Resources/bin:$PATH"

log() {
    echo "[$(date +%H:%M:%S)] $1"
}

log "=== SICHERER BUILD-START ==="
log ""

# 1. Validation durchführen
log "1. Pre-Build Validation..."
if ! ./pre-build-validation.sh; then
    log "❌ VALIDATION FEHLGESCHLAGEN - Build wird NICHT gestartet!"
    exit 1
fi

log ""
log "2. Work-Verzeichnisse löschen..."
docker exec moode-builder bash -c "rm -rf /workspace/imgbuild/pi-gen-64/work /tmp/pi-gen-work 2>/dev/null; echo 'Work-Verzeichnisse gelöscht'"

log ""
log "3. Build starten..."
docker exec -d moode-builder bash -c "cd /workspace/imgbuild/pi-gen-64 && WORK_DIR=/tmp/pi-gen-work ./build.sh > /tmp/build.log 2>&1 &"

sleep 5

# 4. Prüfen ob Build läuft
if docker exec moode-builder pgrep -f "build.sh" >/dev/null 2>&1; then
    log ""
    log "✅ Build erfolgreich gestartet!"
    log ""
    log "Status prüfen:"
    log "  docker exec moode-builder tail -f /tmp/build.log"
    log ""
    log "Monitor läuft automatisch im Hintergrund"
    exit 0
else
    log ""
    log "❌ Build konnte nicht gestartet werden!"
    log "Letzte Log-Zeilen:"
    docker exec moode-builder tail -20 /tmp/build.log 2>/dev/null || echo "Kein Log verfügbar"
    exit 1
fi

