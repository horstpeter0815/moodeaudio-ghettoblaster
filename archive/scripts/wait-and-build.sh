#!/bin/bash
################################################################################
#
# Warte auf Docker und starte Build
#
################################################################################

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

log() {
    echo "[$(date +%H:%M:%S)] $1"
}

# Docker-Pfad setzen
if [ -f "/Applications/Docker.app/Contents/Resources/bin/docker" ]; then
    export PATH="/Applications/Docker.app/Contents/Resources/bin:$PATH"
fi

log "⏳ Warte auf Docker Desktop (max. 3 Minuten)..."
log "   Bitte Docker Desktop öffnen und warten bis es läuft"

for i in {1..60}; do
    if [ -f "/Applications/Docker.app/Contents/Resources/bin/docker" ]; then
        export PATH="/Applications/Docker.app/Contents/Resources/bin:$PATH"
        if docker info >/dev/null 2>&1; then
            log "✅ Docker läuft!"
            log ""
            
            # Docker Setup
            log "=== DOCKER SETUP ==="
            if [ -f "docker-build-setup.sh" ]; then
                ./docker-build-setup.sh
            else
                log "❌ docker-build-setup.sh nicht gefunden"
                exit 1
            fi
            
            # Build starten
            log ""
            log "=== BUILD START ==="
            log "🚀 Build startet JETZT..."
            log ""
            
            cd imgbuild
            ./build.sh
            
            log ""
            log "✅ BUILD ABGESCHLOSSEN"
            exit 0
        fi
    fi
    if [ $((i % 10)) -eq 0 ]; then
        log "⏳ Warte noch... ($i/60)"
    fi
    sleep 3
done

log "❌ Docker läuft nach 3 Minuten noch nicht"
log "   Bitte Docker Desktop manuell starten und dann: ./wait-and-build.sh"
exit 1


