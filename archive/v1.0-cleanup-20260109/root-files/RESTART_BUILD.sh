#!/bin/bash

# Restart Build Script
# Startet den Build neu nach einem Fehler

set -e

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  🔄 BUILD NEU STARTEN                                        ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Prüfe ob Container läuft
if ! docker ps | grep -q moode-builder; then
    echo "❌ Container 'moode-builder' läuft nicht!"
    echo "   Starte Container mit: ./START_BUILD_DOCKER.sh"
    exit 1
fi

echo "✅ Container läuft"
echo ""

# Stoppe laufenden Build falls vorhanden
echo "🛑 Stoppe laufenden Build..."
docker exec moode-builder bash -c "pkill -f build.sh || true" 2>/dev/null || true
sleep 2

# Starte Build neu
echo "🚀 Starte Build neu..."
echo ""

cd /Users/andrevollmer/moodeaudio-cursor
./RUN_BUILD_IN_DOCKER.sh

echo ""
echo "✅ Build gestartet!"
echo ""
echo "📊 Monitoring:"
echo "   ./MONITOR_BUILD_LIVE.sh"
echo ""

