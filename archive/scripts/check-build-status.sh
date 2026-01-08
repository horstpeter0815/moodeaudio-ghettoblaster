#!/bin/bash
################################################################################
#
# Build-Status prüfen
#
################################################################################

export PATH="/Applications/Docker.app/Contents/Resources/bin:$PATH"

echo "=== GHETTOBLASTER BUILD STATUS ==="
echo ""

# Docker Status
if docker info >/dev/null 2>&1; then
    echo "✅ Docker läuft"
else
    echo "❌ Docker läuft nicht"
    exit 1
fi

# Container Status
if docker ps | grep -q moode-builder; then
    echo "✅ Container läuft"
    echo ""
    echo "Build-Log (letzte 20 Zeilen):"
    docker exec moode-builder tail -20 /tmp/build.log 2>/dev/null || echo "Log noch nicht verfügbar"
else
    echo "❌ Container läuft nicht"
fi

echo ""
echo "Container betreten:"
echo "  docker exec -it moode-builder bash"
echo ""
echo "Build-Log live ansehen:"
echo "  docker exec -it moode-builder tail -f /tmp/build.log"

