#!/bin/bash
################################################################################
#
# Docker installieren und Build starten
# Nutzt Mac-Ressourcen wie geplant
#
################################################################################

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

log() {
    echo "[$(date +%H:%M:%S)] $1"
}

log "=== DOCKER INSTALLATION & BUILD START ==="
log ""

# Docker installieren
log "📥 Installiere Docker Desktop..."
brew install --cask docker

log "✅ Docker installiert"
log "⏳ Starte Docker Desktop..."

# Docker Desktop starten
open -a Docker

log "⏳ Warte auf Docker (max. 60 Sekunden)..."
for i in {1..30}; do
    if docker info >/dev/null 2>&1; then
        log "✅ Docker läuft"
        break
    fi
    sleep 2
done

if ! docker info >/dev/null 2>&1; then
    log "⚠️  Docker startet noch - bitte manuell starten und dann: ./start-build-now.sh"
    exit 1
fi

# Docker Setup
log ""
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
log "Build startet jetzt auf Mac..."
log "Dauer: 8-12 Stunden"
log "Mac-Ressourcen werden parallel genutzt"
log ""

cd imgbuild
./build.sh

log ""
log "✅ BUILD ABGESCHLOSSEN"

