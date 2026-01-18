#!/bin/bash
################################################################################
#
# Wait for Docker Desktop 40GB RAM and Restart Build
#
# Prüft kontinuierlich ob Docker Desktop 40GB RAM hat
# Startet automatisch Container und Build wenn bereit
#
################################################################################

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

export PATH="/Applications/Docker.app/Contents/Resources/bin:$PATH"

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  WARTE AUF DOCKER DESKTOP 40GB RAM                          ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "⏳ Prüfe alle 10 Sekunden ob Docker Desktop 40GB RAM hat..."
echo "   (Drücke Ctrl+C zum Abbrechen)"
echo ""

CHECK_COUNT=0
MAX_CHECKS=60  # 10 Minuten (60 * 10 Sekunden)

while [ $CHECK_COUNT -lt $MAX_CHECKS ]; do
    CHECK_COUNT=$((CHECK_COUNT + 1))
    
    # Prüfe ob Docker läuft
    if ! docker info >/dev/null 2>&1; then
        echo "[$(date +%H:%M:%S)] ⏳ Docker läuft noch nicht..."
        sleep 10
        continue
    fi
    
    # Prüfe RAM
    DOCKER_RAM=$(docker info 2>/dev/null | grep "Total Memory" | awk '{print $3}' | sed 's/GiB//' || echo "0")
    
    if [ -z "$DOCKER_RAM" ] || [ "$DOCKER_RAM" = "0" ]; then
        echo "[$(date +%H:%M:%S)] ⏳ Docker RAM nicht erkannt..."
        sleep 10
        continue
    fi
    
    # Prüfe ob RAM >= 30 GB
    if [ "$(echo "$DOCKER_RAM >= 30" | bc 2>/dev/null || echo "0")" = "1" ]; then
        echo ""
        echo "✅ Docker Desktop hat ${DOCKER_RAM} GB RAM!"
        echo ""
        echo "🚀 Starte Container und Build..."
        echo ""
        
        # Container neu starten
        docker-compose -f docker-compose.build.yml down 2>/dev/null || true
        docker stop moode-builder 2>/dev/null || true
        docker rm moode-builder 2>/dev/null || true
        
        sleep 2
        
        docker-compose -f docker-compose.build.yml up -d
        
        sleep 5
        
        # Prüfe Container
        if ! docker ps | grep -q moode-builder; then
            echo "❌ Container startet nicht!"
            exit 1
        fi
        
        # Zeige Ressourcen
        echo "📊 Container-Ressourcen:"
        docker stats --no-stream moode-builder --format "  CPU: {{.CPUPerc}} | Memory: {{.MemUsage}} / {{.MemLimit}}"
        echo ""
        
        # Starte Build
        echo "🔨 Starte Build..."
        docker exec -d moode-builder bash -c "cd /workspace/imgbuild/pi-gen-64 && WORK_DIR=/tmp/pi-gen-work ./build.sh > /tmp/build.log 2>&1 &"
        
        sleep 3
        
        # Prüfe Build
        if docker exec moode-builder pgrep -f "build.sh" >/dev/null 2>&1; then
            echo "✅ Build gestartet!"
            echo ""
            echo "📊 Build-Log (letzte Zeilen):"
            docker exec moode-builder tail -10 /tmp/build.log 2>/dev/null | tail -5 || echo "   Log wird erstellt..."
            echo ""
            echo "=== FERTIG ==="
            echo ""
            echo "📊 Status prüfen:"
            echo "   docker stats moode-builder"
            echo ""
            echo "📊 Build-Log folgen:"
            echo "   docker exec moode-builder tail -f /tmp/build.log"
            exit 0
        else
            echo "⚠️  Build-Prozess nicht gefunden"
            echo "   Prüfe Logs: docker exec moode-builder cat /tmp/build.log"
            exit 1
        fi
    else
        echo "[$(date +%H:%M:%S)] ⏳ Docker Desktop RAM: ${DOCKER_RAM} GB (warte auf >= 30 GB)..."
        sleep 10
    fi
done

echo ""
echo "⏰ Timeout erreicht (10 Minuten)"
echo "   Docker Desktop RAM wurde nicht erhöht"
echo "   Bitte manuell in Docker Desktop Settings ändern"
exit 1

