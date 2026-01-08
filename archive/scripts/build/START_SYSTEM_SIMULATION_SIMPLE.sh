#!/bin/bash
# Start Simplified System Simulation (without systemd)
# Fast and reliable testing

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  🚀 SYSTEM SIMULATION STARTEN (VEREINFACHT)                 ║"
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
docker-compose -f docker-compose.system-sim-simple.yml down 2>/dev/null || true

# Build image
echo ""
echo "🔨 Baue Docker Image..."
docker-compose -f docker-compose.system-sim-simple.yml build

# Start container
echo ""
echo "🚀 Starte System Simulation..."
docker-compose -f docker-compose.system-sim-simple.yml up -d

# Wait for container
echo ""
echo "⏳ Warte auf Container (5 Sekunden)..."
sleep 5

# Set hostname and hosts
echo ""
echo "🔧 Setze Hostname und /etc/hosts..."
docker exec system-simulator bash -c 'echo "GhettoBlaster" > /etc/hostname && echo "127.0.1.1\tGhettoBlaster" >> /etc/hosts && hostname GhettoBlaster' || true

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
echo "  - Shell öffnen: docker exec -it system-simulator bash"
echo "  - SSH: ssh -p 2222 andre@localhost (Password: 0815)"
echo "  - Stoppen: docker-compose -f docker-compose.system-sim-simple.yml down"
echo ""

