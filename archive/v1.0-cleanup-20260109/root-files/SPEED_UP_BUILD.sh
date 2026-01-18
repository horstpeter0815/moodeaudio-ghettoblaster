#!/bin/bash
################################################################################
# SPEED UP BUILD - Optimize Docker Container Resources
################################################################################

set -e

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  ⚡ BUILD BESCHLEUNIGEN - OPTIMIERUNG                        ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Check if container is running
if ! docker ps -f name=moode-builder | grep -q moode-builder; then
    echo "❌ Docker Container 'moode-builder' läuft nicht!"
    exit 1
fi

echo "📊 Aktuelle Ressourcen-Nutzung:"
docker stats moode-builder --no-stream --format "CPU: {{.CPUPerc}}, Memory: {{.MemUsage}}"
echo ""

# Get available CPUs
AVAILABLE_CPUS=$(sysctl -n hw.ncpu 2>/dev/null || echo "12")
echo "💻 Verfügbare CPUs: $AVAILABLE_CPUS"
echo ""

# Update environment variables in running container
echo "🔧 Setze optimierte Build-Flags..."
docker exec moode-builder bash -c "export MAKEFLAGS=-j$AVAILABLE_CPUS && export DEB_BUILD_OPTIONS=parallel=$AVAILABLE_CPUS && echo '✅ MAKEFLAGS=-j$AVAILABLE_CPUS' && echo '✅ DEB_BUILD_OPTIONS=parallel=$AVAILABLE_CPUS'"
echo ""

# Restart container with optimized resources (if needed)
echo "🔄 Container mit optimierten Ressourcen neu starten..."
docker-compose -f docker-compose.build.yml up -d --force-recreate
echo ""

# Wait for container to be ready
echo "⏳ Warte auf Container..."
sleep 5

# Verify
echo "✅ Optimierung abgeschlossen!"
echo ""
echo "📊 Neue Ressourcen-Nutzung:"
docker stats moode-builder --no-stream --format "CPU: {{.CPUPerc}}, Memory: {{.MemUsage}}"
echo ""

echo "💡 Tipp: Der Build nutzt jetzt alle verfügbaren CPUs ($AVAILABLE_CPUS)"
echo "   Dies sollte die Build-Zeit deutlich reduzieren!"

