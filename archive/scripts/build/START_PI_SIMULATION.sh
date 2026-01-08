#!/bin/bash
# Start Pi Boot Simulation
# Simulates Raspberry Pi boot to test services and fixes

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  🚀 PI BOOT SIMULATION STARTEN                              ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Create test directory
mkdir -p pi-sim-test
chmod +x pi-sim-test/test-services.sh 2>/dev/null || true

# Stop existing container
echo "🛑 Stoppe vorhandenen Container..."
docker-compose -f docker-compose.pi-sim.yml down 2>/dev/null || true

# Build and start container
echo ""
echo "🔨 Baue Docker Image..."
docker-compose -f docker-compose.pi-sim.yml build

echo ""
echo "🚀 Starte Pi Simulation..."
docker-compose -f docker-compose.pi-sim.yml up -d

echo ""
echo "⏳ Warte auf systemd (10 Sekunden)..."
sleep 10

echo ""
echo "🔍 Führe Tests aus..."
docker exec pi-simulator bash /test/test-services.sh || {
    echo ""
    echo "⚠️  Einige Tests fehlgeschlagen"
    echo "   Prüfe Logs: docker logs pi-simulator"
}

echo ""
echo "📋 NÄCHSTE SCHRITTE:"
echo "  - Container läuft: docker ps | grep pi-simulator"
echo "  - Logs ansehen: docker logs pi-simulator"
echo "  - Shell öffnen: docker exec -it pi-simulator bash"
echo "  - Services prüfen: docker exec pi-simulator systemctl status <service>"
echo "  - Stoppen: docker-compose -f docker-compose.pi-sim.yml down"
echo ""

