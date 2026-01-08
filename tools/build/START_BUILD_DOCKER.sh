#!/bin/bash
################################################################################
#
# START CUSTOM BUILD IN DOCKER - GHETTOBLASTER
#
# Startet den Custom Build in einem Docker-Container (Linux-Umgebung)
#
################################################################################

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  🐳 STARTE CUSTOM BUILD IN DOCKER - GHETTOBLASTER            ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "📋 Build-Konfiguration:"
echo "  - Moode: 10.0.0-1moode1"
echo "  - Custom Components: ✅"
echo "  - Audio/Video Tools: ✅"
echo "  - config.txt Overwrite-Schutz: ✅"
echo "  - Build-Umgebung: Docker (Linux)"
echo ""
echo "⏱️  Geschätzte Build-Zeit: 8-12 Stunden"
echo "📁 Build-Log: imgbuild/build-*.log"
echo ""

# Prüfe Docker
if ! docker info >/dev/null 2>&1; then
    echo "❌ FEHLER: Docker läuft nicht"
    echo "   Bitte starte Docker Desktop"
    exit 1
fi

echo "✅ Docker läuft"
echo ""

# Prüfe ob docker-compose.build.yml existiert
if [ ! -f "docker-compose.build.yml" ]; then
    echo "❌ FEHLER: docker-compose.build.yml nicht gefunden"
    exit 1
fi

# Git safe.directory Fix (für pi-gen-64)
echo "🔧 Git-Konfiguration..."
git config --global --add safe.directory "$SCRIPT_DIR/imgbuild/pi-gen-64" 2>/dev/null || true
echo ""

# Starte Build in Docker
echo "🔄 Starte Docker Build..."
echo "   (Dies kann einige Minuten dauern, bis der Container bereit ist)"
echo ""

# Verwende docker-compose für den Build
docker-compose -f docker-compose.build.yml up --build -d

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Docker Container gestartet"
    echo ""
    echo "📋 Build-Status prüfen:"
    echo "   docker-compose -f docker-compose.build.yml logs -f"
    echo ""
    echo "📋 In Container einloggen:"
    echo "   docker exec -it moode-builder bash"
    echo ""
    echo "📋 Build manuell starten (im Container):"
    echo "   cd /workspace/imgbuild"
    echo "   ./build.sh"
    echo ""
    echo "⏱️  Build läuft im Hintergrund"
else
    echo ""
    echo "❌ FEHLER: Docker Container konnte nicht gestartet werden"
    echo "   Prüfe die Logs:"
    echo "   docker-compose -f docker-compose.build.yml logs"
    exit 1
fi

