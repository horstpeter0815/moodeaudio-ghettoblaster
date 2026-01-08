#!/bin/bash
################################################################################
#
# Build SOFORT starten - wartet auf Docker und startet dann
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

log "🚀 BUILD START SCRIPT"
log ""

# Warte auf Docker (max. 5 Minuten)
log "⏳ Warte auf Docker Desktop..."
log "   Bitte Docker Desktop öffnen (falls noch nicht geschehen)"

for i in {1..100}; do
    if [ -f "/Applications/Docker.app/Contents/Resources/bin/docker" ]; then
        export PATH="/Applications/Docker.app/Contents/Resources/bin:$PATH"
        if docker info >/dev/null 2>&1; then
            log ""
            log "✅✅✅ DOCKER LÄUFT - STARTE BUILD JETZT! ✅✅✅"
            log ""
            
            # Docker Setup
            if [ -f "docker-build-setup.sh" ]; then
                log "=== DOCKER SETUP ==="
                ./docker-build-setup.sh
            fi
            
            # Build starten
            log ""
            log "=== BUILD START ==="
            log "🚀🚀🚀 GHETTOBLASTER BUILD STARTET JETZT! 🚀🚀🚀"
            log "Dauer: 8-12 Stunden"
            log ""
            
            cd imgbuild
            ./build.sh
            
            log ""
            log "✅✅✅ BUILD ABGESCHLOSSEN ✅✅✅"
            exit 0
        fi
    fi
    if [ $((i % 20)) -eq 0 ]; then
        log "⏳ Warte noch... ($i/100) - Docker Desktop bitte öffnen"
    fi
    sleep 3
done

log ""
log "❌ Docker läuft nach 5 Minuten noch nicht"
log "   Bitte Docker Desktop manuell starten"
log "   Dann: ./start-build-immediately.sh"
exit 1


