#!/bin/bash
################################################################################
#
# Ghetto Blaster Custom Build - Build Start Script
#
# Startet Docker Setup und Build
#
################################################################################

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

log() {
    echo "[$(date +%H:%M:%S)] $1"
}

error() {
    echo "[ERROR] $1" >&2
    exit 1
}

log "=== GHETTO BLASTER BUILD START ==="
log ""

# Check Docker
if ! command -v docker &> /dev/null; then
    log "❌ Docker nicht installiert"
    log "📥 Installiere Docker via Homebrew..."
    brew install --cask docker
    log "✅ Docker installiert"
    log "⚠️  Bitte Docker Desktop starten und dann dieses Script erneut ausführen"
    exit 0
fi

log "✅ Docker gefunden: $(docker --version)"

# Check Docker running
if ! docker info &> /dev/null 2>&1; then
    error "Docker läuft nicht. Bitte Docker Desktop starten und dann dieses Script erneut ausführen."
fi

log "✅ Docker läuft"

# Setup Docker Build Environment
log ""
log "=== DOCKER SETUP ==="
if [ -f "docker-build-setup.sh" ]; then
    ./docker-build-setup.sh
else
    error "docker-build-setup.sh nicht gefunden"
fi

# Start Build
log ""
log "=== BUILD START ==="
log "Build startet jetzt..."
log "Dauer: 8-12 Stunden"
log ""

cd imgbuild
./build.sh

log ""
log "✅ BUILD ABGESCHLOSSEN"

