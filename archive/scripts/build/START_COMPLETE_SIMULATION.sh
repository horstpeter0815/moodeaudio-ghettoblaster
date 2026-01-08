#!/bin/bash
################################################################################
#
# START COMPLETE SIMULATION
#
# Starts Docker container with complete boot simulation including:
# - Display (X Server)
# - Audio (ALSA)
# - All Services
# - Boot Sequence
#
################################################################################

set -e

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  🚀 COMPLETE SIMULATION STARTEN                             ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Create necessary directories
mkdir -p complete-sim-test complete-sim-logs complete-sim-boot complete-sim-moode

# Create mock boot files
echo "📝 Creating mock boot files..."
echo "display_rotate=0" > complete-sim-boot/config.txt.overwrite
echo "hdmi_force_mode=1" >> complete-sim-boot/config.txt.overwrite
touch complete-sim-boot/ssh

# Create mock moOde files
echo "📝 Creating mock moOde files..."
mkdir -p complete-sim-moode
echo "<?php // moOde worker.php" > complete-sim-moode/worker.php
echo "// Ghettoblaster: display_rotate=0" >> complete-sim-moode/worker.php

# Stop and remove existing container
echo "🛑 Stopping existing container..."
docker-compose -f docker-compose.complete-simulation.yml down --remove-orphans 2>/dev/null || true

# Build Docker image
echo "🔨 Building Docker image..."
docker-compose -f docker-compose.complete-simulation.yml build

# Start container
echo "🚀 Starting container..."
docker-compose -f docker-compose.complete-simulation.yml up -d

# Wait for container to be ready
echo "⏳ Waiting for container to be ready (20 seconds)..."
sleep 20

# Set hostname
echo "🔧 Setting hostname..."
docker exec complete-simulator hostnamectl set-hostname GhettoBlaster 2>/dev/null || true
docker exec complete-simulator bash -c 'echo "127.0.1.1\tGhettoBlaster" >> /etc/hosts' 2>/dev/null || true

# Run complete boot simulation
echo "🔄 Running complete boot simulation..."
docker exec complete-simulator /test/complete-boot-simulation.sh

if [ $? -eq 0 ]; then
    echo ""
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║  ✅ COMPLETE SIMULATION ERFOLGREICH                         ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo ""
    echo "📋 LOGS:"
    echo "  - Boot Simulation: cat complete-sim-logs/complete-boot-simulation.log"
    echo "  - Container Logs: docker logs complete-simulator"
    echo ""
    echo "📋 NÄCHSTE SCHRITTE:"
    echo "  - Logs prüfen: cat complete-sim-logs/complete-boot-simulation.log"
    echo "  - Container Shell: docker exec -it complete-simulator bash"
    echo "  - Stoppen: docker-compose -f docker-compose.complete-simulation.yml down"
    echo ""
else
    echo ""
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║  ❌ SIMULATION FEHLGESCHLAGEN                               ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo ""
    echo "📋 FEHLER PRÜFEN:"
    echo "  - Boot Logs: cat complete-sim-logs/complete-boot-simulation.log"
    echo "  - Container Logs: docker logs complete-simulator"
    echo ""
    exit 1
fi

