#!/bin/bash
# Run NullCity.DockerTest with Monitoring and Auto-Fix
# Run from HOME: bash ~/moodeaudio-cursor/scripts/test/RUN_NULLCITY_DOCKERTEST.sh

PROJECT_DIR="$HOME/moodeaudio-cursor"
cd "$PROJECT_DIR"

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  🚀 NullCity.DockerTest - Full Test Run                      ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# 1. Pre-flight
echo "=== Pre-Flight Checks ==="
bash "$PROJECT_DIR/scripts/test/TEST_NULLCITY_DOCKERTEST.sh" --preflight-only 2>/dev/null || {
    echo "Running pre-flight checks..."
    if ! docker info >/dev/null 2>&1; then
        echo "❌ Docker not running"
        exit 1
    fi
    echo "✅ Docker running"
}

# 2. Start build in background
echo ""
echo "=== Starting Build ==="
docker-compose -f docker-compose.nullcity-dockertest.yml up --build -d

# 3. Start monitor in background
echo ""
echo "=== Starting Monitor ==="
bash "$PROJECT_DIR/scripts/test/MONITOR_NULLCITY_BUILD.sh" &
MONITOR_PID=$!

# 4. Follow build logs
echo ""
echo "=== Build Logs (Ctrl+C to stop following, build continues) ==="
echo ""
docker-compose -f docker-compose.nullcity-dockertest.yml logs -f

# Wait for monitor
wait $MONITOR_PID

echo ""
echo "=== Test Complete ==="
echo ""
echo "Results:"
echo "  - Build logs: docker-compose -f docker-compose.nullcity-dockertest.yml logs"
echo "  - Monitor log: test-results/monitor.log"
echo "  - Docker logs: test-results/docker-logs.txt"
echo ""
