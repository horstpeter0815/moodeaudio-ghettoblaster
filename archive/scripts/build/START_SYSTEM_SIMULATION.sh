#!/bin/bash
# Start Complete System Simulation
# Full system simulation with all components

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  🚀 SYSTEM SIMULATION STARTEN                               ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Create directories
echo "📁 Erstelle Verzeichnisse..."
mkdir -p system-sim-test system-sim-logs system-sim-boot system-sim-moode
chmod +x system-sim-test/*.sh 2>/dev/null || true

# Create mock boot files
echo "📝 Erstelle Mock Boot-Dateien..."
cat > system-sim-boot/config.txt << 'EOF'
# Ghettoblaster Display Settings
disable_overscan=1
display_rotate=0
hdmi_group=2
hdmi_mode=87
hdmi_cvt=1280 400 60 6 0 0 0
hdmi_force_mode=1
EOF

touch system-sim-boot/ssh

# Create mock moOde file
echo "📝 Erstelle Mock moOde-Dateien..."
mkdir -p system-sim-moode
touch system-sim-moode/worker.php

# Stop existing container
echo ""
echo "🛑 Stoppe vorhandenen Container..."
docker-compose -f docker-compose.system-sim.yml down 2>/dev/null || true

# Build image
echo ""
echo "🔨 Baue Docker Image..."
docker-compose -f docker-compose.system-sim.yml build

# Start container
echo ""
echo "🚀 Starte System Simulation..."
docker-compose -f docker-compose.system-sim.yml up -d

# Wait for systemd
echo ""
echo "⏳ Warte auf systemd (20 Sekunden)..."
sleep 20

# Set hostname and hosts
echo ""
echo "🔧 Setze Hostname und /etc/hosts..."
docker exec system-simulator bash -c 'echo "GhettoBlaster" > /etc/hostname && echo "127.0.1.1\tGhettoBlaster" >> /etc/hosts && hostname GhettoBlaster' || true

# Run boot simulation
echo ""
echo "🔄 Führe Boot-Simulation aus..."
docker exec system-simulator bash /test/boot-simulation.sh || true

# Run comprehensive tests
echo ""
echo "🔍 Führe umfassende Tests aus..."
docker exec system-simulator bash /test/comprehensive-test.sh || {
    echo ""
    echo "⚠️  Einige Tests fehlgeschlagen"
    echo "   Prüfe Logs: docker logs system-simulator"
    echo "   Test-Logs: cat system-sim-logs/test-results.log"
}

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  ✅ SYSTEM SIMULATION GESTARTET                             ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "📋 NÄCHSTE SCHRITTE:"
echo "  - Container läuft: docker ps | grep system-simulator"
echo "  - Logs ansehen: docker logs system-simulator"
echo "  - Test-Logs: cat system-sim-logs/test-results.log"
echo "  - Boot-Logs: cat system-sim-logs/boot-simulation.log"
echo "  - Shell öffnen: docker exec -it system-simulator bash"
echo "  - Services prüfen: docker exec system-simulator systemctl status <service>"
echo "  - Stoppen: docker-compose -f docker-compose.system-sim.yml down"
echo ""

