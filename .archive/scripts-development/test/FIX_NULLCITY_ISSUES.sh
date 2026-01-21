#!/bin/bash
# Fix Issues in NullCity.DockerTest Container
# Run from HOME: bash ~/moodeaudio-cursor/scripts/test/FIX_NULLCITY_ISSUES.sh

CONTAINER_NAME="nullcity-dockertest"

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  🔧 NullCity.DockerTest - Issue Fixer                       ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Check if container is running
if ! docker ps | grep -q "$CONTAINER_NAME"; then
    echo "❌ Container $CONTAINER_NAME is not running"
    echo ""
    echo "To start it:"
    echo "  docker-compose -f docker-compose.nullcity-dockertest.yml up -d"
    exit 1
fi

echo "✅ Container is running"
echo ""

# Check for common issues and fix them
echo "=== Checking for Issues ==="
echo ""

# Issue 1: Wrong moOde version
if ! docker exec "$CONTAINER_NAME" bash -c "grep -q 'IMG_NAME=moode-r1001' /workspace/imgbuild/moode-cfg/config" 2>/dev/null; then
    echo "❌ Issue found: Wrong moOde version (must be r1001)"
    echo "   Fixing..."
    docker exec "$CONTAINER_NAME" bash -c "sed -i 's/IMG_NAME=.*/IMG_NAME=moode-r1001/' /workspace/imgbuild/moode-cfg/config"
    echo "   ✅ Fixed to r1001"
else
    echo "✅ moOde version: OK (r1001)"
fi

# Issue 2: Display script has fbcon
if docker exec "$CONTAINER_NAME" bash -c "grep -q 'fbcon=rotate:1' /workspace/imgbuild/moode-cfg/stage3_03-ghettoblaster-custom_02-display-cmdline.sh" 2>/dev/null; then
    echo "❌ Issue found: Display script has fbcon=rotate:1"
    echo "   Fixing..."
    docker exec "$CONTAINER_NAME" bash -c "sed -i 's/ fbcon=rotate:1//' /workspace/imgbuild/moode-cfg/stage3_03-ghettoblaster-custom_02-display-cmdline.sh"
    echo "   ✅ Fixed"
else
    echo "✅ Display script: OK (no fbcon)"
fi

# Issue 2: Build script missing
if ! docker exec "$CONTAINER_NAME" test -f /workspace/imgbuild/moode-cfg/stage3_03-ghettoblaster-custom_02-display-cmdline.sh 2>/dev/null; then
    echo "❌ Issue found: Build script missing"
    echo "   This is a critical issue - cannot fix automatically"
else
    echo "✅ Build script: Exists"
fi

# Issue 3: Check build logs for errors
echo ""
echo "=== Recent Build Errors ==="
docker logs "$CONTAINER_NAME" --tail 50 2>&1 | grep -iE "error|failed|fatal" | tail -5 || echo "  (no recent errors)"

echo ""
echo "=== Container Status ==="
docker exec "$CONTAINER_NAME" bash -c "ps aux | head -5" 2>/dev/null || echo "  (cannot check processes)"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "To manually fix issues, log into container:"
echo "  docker exec -it $CONTAINER_NAME bash"
echo ""
echo "Or view logs:"
echo "  docker logs $CONTAINER_NAME --tail 100 -f"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
