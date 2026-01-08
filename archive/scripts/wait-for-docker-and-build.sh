#!/bin/bash
################################################################################
#
# Warte auf Docker und starte Build SOFORT wenn bereit
#
################################################################################

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

export PATH="/Applications/Docker.app/Contents/Resources/bin:$PATH"

log() {
    echo "[$(date +%H:%M:%S)] $1"
}

log "=== WARTE AUF DOCKER & STARTE BUILD ==="
log ""

# Warte auf Docker (max. 5 Minuten)
for i in {1..100}; do
    if docker info >/dev/null 2>&1; then
        log ""
        log "✅✅✅ DOCKER LÄUFT! ✅✅✅"
        log ""
        docker --version
        log ""
        
        # Docker Setup
        log "=== DOCKER SETUP ==="
        if [ -f "docker-build-setup.sh" ]; then
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
    
    if [ $((i % 10)) -eq 0 ]; then
        log "⏳ Warte auf Docker... ($i/100) - Docker Desktop sollte in der Menüleiste erscheinen"
    fi
    
    sleep 3
done

log ""
log "❌ Docker läuft nach 5 Minuten noch nicht"
log "   Bitte Docker Desktop manuell prüfen"
exit 1

