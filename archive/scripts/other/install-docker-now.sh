#!/bin/bash
################################################################################
#
# Docker SOFORT installieren und Build starten
# Direkter Ansatz - keine Umwege
#
################################################################################

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

log() {
    echo "[$(date +%H:%M:%S)] $1"
}

log "=== DOCKER INSTALLATION START ==="
log ""

# Homebrew prüfen
if ! command -v brew &> /dev/null; then
    log "❌ Homebrew nicht gefunden"
    log "📥 Installiere Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Docker installieren (wird nach Passwort fragen)
log "📥 Installiere Docker Desktop..."
log "⚠️  Passwort wird benötigt - bitte eingeben wenn gefragt"
brew install --cask docker

log "✅ Docker installiert"
log "🚀 Starte Docker Desktop..."

# Docker Desktop starten
open -a Docker

log "⏳ Warte auf Docker (max. 2 Minuten)..."
for i in {1..40}; do
    if [ -f "/Applications/Docker.app/Contents/Resources/bin/docker" ]; then
        export PATH="/Applications/Docker.app/Contents/Resources/bin:$PATH"
        if docker info >/dev/null 2>&1; then
            log "✅ Docker läuft!"
            break
        fi
    fi
    if [ $i -eq 40 ]; then
        log "⚠️  Docker startet noch - bitte Docker Desktop manuell öffnen"
        log "   Dann: ./start-build-direct.sh"
        exit 1
    fi
    sleep 3
done

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
log "🚀 Build startet JETZT..."
log ""

cd imgbuild
./build.sh

log ""
log "✅ BUILD ABGESCHLOSSEN"


