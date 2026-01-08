#!/bin/bash
################################################################################
#
# Restart Build with 40GB RAM
#
# Startet Container und Build neu nach Docker Desktop RAM-Erhöhung
#
################################################################################

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

export PATH="/Applications/Docker.app/Contents/Resources/bin:$PATH"

echo "=== RESTART BUILD WITH 40GB RAM ==="
echo ""

# Prüfe Docker
if ! docker info >/dev/null 2>&1; then
    echo "❌ Docker läuft nicht!"
    echo "   Bitte starte Docker Desktop zuerst."
    exit 1
fi

# Prüfe RAM
DOCKER_RAM=$(docker info 2>/dev/null | grep "Total Memory" | awk '{print $3}' | sed 's/GiB//')
echo "📊 Docker Desktop RAM: ${DOCKER_RAM} GB"

if [ -z "$DOCKER_RAM" ] || [ "$(echo "$DOCKER_RAM < 30" | bc 2>/dev/null || echo "1")" = "1" ]; then
    echo "⚠️  WARNUNG: Docker Desktop hat weniger als 30 GB RAM!"
    echo "   Bitte erhöhe Docker Desktop RAM auf 40 GB:"
    echo "   Docker Desktop → Settings → Resources → Advanced → Memory: 40 GB"
    echo ""
    read -p "Trotzdem fortfahren? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Stoppe alten Container
echo ""
echo "🛑 Stoppe alten Container..."
docker-compose -f docker-compose.build.yml down 2>/dev/null || true
docker stop moode-builder 2>/dev/null || true
docker rm moode-builder 2>/dev/null || true

# Starte Container mit neuen Ressourcen
echo ""
echo "🚀 Starte Container mit 40GB RAM..."
docker-compose -f docker-compose.build.yml up -d

# Warte auf Container
echo ""
echo "⏳ Warte auf Container..."
sleep 5

# Prüfe Container-Status
if ! docker ps | grep -q moode-builder; then
    echo "❌ Container startet nicht!"
    exit 1
fi

# Prüfe Container-Ressourcen
echo ""
echo "📊 Container-Ressourcen:"
docker stats --no-stream moode-builder --format "  CPU: {{.CPUPerc}} | Memory: {{.MemUsage}} / {{.MemLimit}}"

# Starte Build
echo ""
echo "🔨 Starte Build..."
docker exec -d moode-builder bash -c "cd /workspace/imgbuild/pi-gen-64 && WORK_DIR=/tmp/pi-gen-work ./build.sh > /tmp/build.log 2>&1 &"

# Warte kurz
sleep 3

# Prüfe Build-Status
if docker exec moode-builder pgrep -f "build.sh" >/dev/null 2>&1; then
    echo "✅ Build gestartet!"
    echo ""
    echo "📊 Build-Log:"
    echo "   docker exec moode-builder tail -f /tmp/build.log"
    echo ""
    echo "📊 Status:"
    echo "   docker stats moode-builder"
else
    echo "⚠️  Build-Prozess nicht gefunden - prüfe Logs:"
    echo "   docker exec moode-builder cat /tmp/build.log"
fi

echo ""
echo "=== FERTIG ==="

