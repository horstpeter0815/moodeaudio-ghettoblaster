#!/bin/bash
################################################################################
#
# Docker Status prüfen und Build starten wenn bereit
#
################################################################################

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

export PATH="/Applications/Docker.app/Contents/Resources/bin:$PATH"

log() {
    echo "[$(date +%H:%M:%S)] $1"
}

log "=== DOCKER STATUS CHECK ==="
log ""

# Prüfe ob Docker läuft
if docker info >/dev/null 2>&1; then
    log "✅✅✅ DOCKER LÄUFT! ✅✅✅"
    log ""
    docker --version
    log ""
    log "🚀 Starte Build-Setup..."
    
    if [ -f "docker-build-setup.sh" ]; then
        ./docker-build-setup.sh
    fi
    
    log ""
    log "🚀🚀🚀 STARTE BUILD JETZT! 🚀🚀🚀"
    log ""
    
    cd imgbuild
    ./build.sh
    
else
    log "⏳ Docker startet noch..."
    log "   Bitte warten bis Docker Desktop vollständig gestartet ist"
    log "   (Docker-Icon sollte in der Menüleiste erscheinen)"
    log ""
    log "   Dann erneut ausführen: ./check-docker-status.sh"
fi

