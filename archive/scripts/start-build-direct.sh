#!/bin/bash
################################################################################
#
# Build direkt starten (wenn Docker schon installiert ist)
#
################################################################################

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Docker-Pfad finden
if [ -f "/Applications/Docker.app/Contents/Resources/bin/docker" ]; then
    export PATH="/Applications/Docker.app/Contents/Resources/bin:$PATH"
fi

# Docker prüfen
if ! docker info >/dev/null 2>&1; then
    echo "❌ Docker läuft nicht"
    echo "📥 Bitte Docker Desktop starten"
    echo "   Oder: brew install --cask docker (braucht Passwort)"
    exit 1
fi

echo "✅ Docker läuft: $(docker --version)"
echo ""

# Docker Setup
if [ -f "docker-build-setup.sh" ]; then
    echo "=== DOCKER SETUP ==="
    ./docker-build-setup.sh
else
    echo "❌ docker-build-setup.sh nicht gefunden"
    exit 1
fi

# Build starten
echo ""
echo "=== BUILD START ==="
echo "Build startet jetzt auf Mac..."
echo "Dauer: 8-12 Stunden"
echo ""

cd imgbuild
./build.sh

echo ""
echo "✅ BUILD ABGESCHLOSSEN"

