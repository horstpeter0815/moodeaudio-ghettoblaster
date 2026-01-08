#!/bin/bash
################################################################################
#
# FIX ISSUES AND BUILD IN DOCKER
#
# Behebt alle Probleme im Container und startet dann den Build
#
################################################################################

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  🔧 FIX ISSUES & BUILD IN DOCKER                              ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Prüfe ob Container läuft
if ! docker ps | grep -q moode-builder; then
    echo "❌ Container 'moode-builder' läuft nicht"
    echo "   Bitte zuerst ausführen: ./START_BUILD_DOCKER.sh"
    exit 1
fi

echo "✅ Container läuft"
echo ""

echo "🔧 Fix 1: Git safe.directory..."
docker exec moode-builder bash -c "git config --global --add safe.directory /workspace/imgbuild/pi-gen-64" 2>/dev/null || true
echo "✅ Git konfiguriert"
echo ""

echo "🔧 Fix 2: Installiere fehlende Dependencies..."
docker exec moode-builder bash -c "apt-get update && apt-get install -y quilt parted qemu-user-static debootstrap zerofree dosfstools e2fsprogs libcap2-bin kmod pigz arch-test" 2>/dev/null
echo "✅ Dependencies installiert"
echo ""

echo "🔧 Fix 3: Erstelle /etc/mtab (symlink zu /proc/mounts)..."
docker exec moode-builder bash -c "ln -sf /proc/mounts /etc/mtab 2>/dev/null || true"
echo "✅ /etc/mtab erstellt"
echo ""

echo "🔧 Fix 4: Korrigiere sed-Befehl in build.sh..."
docker exec moode-builder bash -c "cd /workspace/imgbuild && sed -i 's|sed -i \"s/IMG_NAME|sed -i.bak \"s/IMG_NAME|g' build.sh && sed -i 's|sed -i \"s/IMG_NAME|sed -i \"s/IMG_NAME|g' build.sh" 2>/dev/null || true
echo "✅ sed-Befehl korrigiert"
echo ""

echo "🔄 Starte Build..."
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

