#!/bin/bash
################################################################################
#
# RUN BUILD IN DOCKER CONTAINER
#
# Führt den Build direkt im Docker-Container aus
#
################################################################################

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  🐳 BUILD IM DOCKER CONTAINER AUSFÜHREN                      ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Prüfe ob Container läuft
if ! docker ps | grep -q moode-builder; then
    echo "❌ Container 'moode-builder' läuft nicht"
    echo "   Bitte zuerst ausführen: ./START_BUILD_DOCKER.sh"
    exit 1
fi

echo "✅ Container 'moode-builder' läuft"
echo ""
echo "🔄 Starte Build im Container..."
echo "   (Dies kann 8-12 Stunden dauern)"
echo ""

# Starte Build im Container
docker exec -it moode-builder bash -c "cd /workspace/imgbuild && ./build.sh 2>&1 | tee build-\$(date +%Y%m%d_%H%M%S).log"

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  ✅ BUILD ABGESCHLOSSEN                                       ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "📁 Image sollte in imgbuild/deploy/ sein"
echo ""

