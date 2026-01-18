#!/bin/bash
################################################################################
#
# START FRESH BUILD IN DOCKER
#
# Räumt auf, startet Container neu und führt Build aus
#
################################################################################

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  🐳 FRESH DOCKER BUILD - GHETTOBLASTER                       ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Prüfe Docker
if ! docker info >/dev/null 2>&1; then
    echo "❌ FEHLER: Docker läuft nicht"
    echo "   Bitte starte Docker Desktop"
    exit 1
fi

echo "✅ Docker läuft"
echo ""

# Aufräumen
echo "🧹 Räume alte Container auf..."
docker-compose -f docker-compose.build.yml down 2>/dev/null || true
docker stop moode-builder 2>/dev/null || true
docker rm moode-builder 2>/dev/null || true
echo "✅ Aufgeräumt"
echo ""

# Git safe.directory Fix
echo "🔧 Git-Konfiguration..."
git config --global --add safe.directory "$SCRIPT_DIR/imgbuild/pi-gen-64" 2>/dev/null || true
echo "✅ Git konfiguriert"
echo ""

# Container starten
echo "🔄 Starte Docker Container..."
docker-compose -f docker-compose.build.yml up -d --build

if [ $? -ne 0 ]; then
    echo ""
    echo "❌ FEHLER: Container konnte nicht gestartet werden"
    exit 1
fi

echo ""
echo "✅ Container gestartet"
echo ""

# Warte bis Container bereit ist
echo "⏳ Warte bis Container bereit ist..."
sleep 5

# Prüfe ob Container läuft
if ! docker ps | grep -q moode-builder; then
    echo "❌ Container läuft nicht"
    echo "   Prüfe Logs: docker-compose -f docker-compose.build.yml logs"
    exit 1
fi

echo "✅ Container läuft"
echo ""

# Fixes im Container
echo "🔧 Fix 1: Installiere Dependencies..."
docker exec moode-builder bash -c "apt-get update && apt-get install -y quilt parted qemu-user-static debootstrap zerofree dosfstools e2fsprogs libcap2-bin kmod pigz arch-test" >/dev/null 2>&1
echo "✅ Dependencies installiert"
echo ""

echo "🔧 Fix 2: Git safe.directory im Container..."
docker exec moode-builder bash -c "git config --global --add safe.directory /workspace/imgbuild/pi-gen-64" 2>/dev/null || true
echo "✅ Git konfiguriert"
echo ""

echo "🔧 Fix 3: Erstelle /etc/mtab..."
docker exec moode-builder bash -c "ln -sf /proc/mounts /etc/mtab 2>/dev/null || true"
echo "✅ /etc/mtab erstellt"
echo ""

# Starte Build
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  🚀 STARTE BUILD                                              ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "⏱️  Geschätzte Build-Zeit: 8-12 Stunden"
echo "📁 Build-Log: imgbuild/build-*.log (im Container)"
echo ""
echo "🔄 Starte Build..."
echo ""

# Starte Build im Container
docker exec -it moode-builder bash -c "cd /workspace/imgbuild && ./build.sh 2>&1 | tee build-\$(date +%Y%m%d_%H%M%S).log"

BUILD_EXIT=$?

echo ""
if [ $BUILD_EXIT -eq 0 ]; then
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║  ✅ BUILD ERFOLGREICH ABGESCHLOSSEN                           ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo ""
    echo "📁 Image sollte in imgbuild/deploy/ sein"
else
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║  ⚠️  BUILD MIT FEHLERN ABGESCHLOSSEN                          ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo ""
    echo "📋 Prüfe Logs:"
    echo "   docker exec -it moode-builder bash"
    echo "   cd /workspace/imgbuild"
    echo "   tail -50 build-*.log"
fi
echo ""

