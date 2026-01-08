#!/bin/bash
# Monitor Build Live - See console output in real-time
# Usage: ~/moodeaudio-cursor/MONITOR_BUILD_LIVE.sh

PROJECT_DIR="$HOME/moodeaudio-cursor"

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  📡 MONITOR BUILD LIVE - REAL-TIME OUTPUT                   ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Check if container is running
if ! docker ps | grep -q moode-builder; then
    echo "⚠️  Build container not running"
    echo ""
    echo "Options:"
    echo "  1. Start build: sudo ~/moodeaudio-cursor/START_BUILD_36.sh"
    echo "  2. Check logs: docker-compose -f ~/moodeaudio-cursor/docker-compose.build.yml logs"
    echo ""
    exit 1
fi

echo "✅ Build container is running"
echo ""
echo "=== LIVE BUILD OUTPUT ==="
echo ""
echo "Press Ctrl+C to stop monitoring (build will continue)"
echo ""

# Follow container logs in real-time
docker-compose -f "$PROJECT_DIR/docker-compose.build.yml" logs -f moode-builder
