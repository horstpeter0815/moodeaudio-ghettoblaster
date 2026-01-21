#!/bin/bash
# NullCity.DockerTest - Custom Build Test & Auto-Fix
# Run from HOME: bash ~/moodeaudio-cursor/scripts/test/TEST_NULLCITY_DOCKERTEST.sh

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  🧪 NullCity.DockerTest - Custom Build Test                  ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

PROJECT_DIR="$HOME/moodeaudio-cursor"
cd "$PROJECT_DIR"

# 1. Pre-flight checks
echo "=== Pre-Flight Checks ==="
echo ""

# Check Docker
if ! docker info >/dev/null 2>&1; then
    echo "❌ Docker is not running"
    echo "   Please start Docker Desktop"
    exit 1
fi
echo "✅ Docker is running"

# Check moOde version (MUST be r1001 - best working version)
if [ -f "imgbuild/moode-cfg/config" ]; then
    if grep -q "IMG_NAME=moode-r1001" "imgbuild/moode-cfg/config"; then
        echo "✅ moOde version: CORRECT (r1001 - best working version)"
    else
        echo "❌ moOde version: INCORRECT"
        echo "   Current: $(grep 'IMG_NAME' imgbuild/moode-cfg/config)"
        echo "   Required: IMG_NAME=moode-r1001"
        echo "   Fixing now..."
        sed -i '' 's/IMG_NAME=.*/IMG_NAME=moode-r1001/' "imgbuild/moode-cfg/config"
        echo "   ✅ Fixed to r1001"
    fi
else
    echo "❌ Build config not found"
    exit 1
fi

# Check build script fix
if [ -f "imgbuild/moode-cfg/stage3_03-ghettoblaster-custom_02-display-cmdline.sh" ]; then
    if grep -q "video=HDMI-A-1:400x1280M@60,rotate=90" "imgbuild/moode-cfg/stage3_03-ghettoblaster-custom_02-display-cmdline.sh" && \
       ! grep -q "fbcon=rotate:1" "imgbuild/moode-cfg/stage3_03-ghettoblaster-custom_02-display-cmdline.sh"; then
        echo "✅ Display cmdline script: CORRECT (fbcon removed)"
    else
        echo "❌ Display cmdline script: INCORRECT"
        echo "   Fixing now..."
        # Apply fix
        sed -i '' 's/ fbcon=rotate:1//' "imgbuild/moode-cfg/stage3_03-ghettoblaster-custom_02-display-cmdline.sh"
        echo "   ✅ Fixed"
    fi
else
    echo "❌ Build script not found"
    exit 1
fi

# Check docker-compose file
if [ ! -f "docker-compose.nullcity-dockertest.yml" ]; then
    echo "❌ docker-compose.nullcity-dockertest.yml not found"
    exit 1
fi
echo "✅ Docker compose file exists"

echo ""
echo "=== Starting NullCity.DockerTest ==="
echo ""

# 2. Start test
docker-compose -f docker-compose.nullcity-dockertest.yml up --build

# 3. Check results
echo ""
echo "=== Test Results ==="
echo ""

if [ -d "test-results" ]; then
    if [ -f "test-results/build.log" ]; then
        echo "Build log: test-results/build.log"
        echo ""
        echo "Last 20 lines:"
        tail -20 test-results/build.log
    fi
fi

echo ""
echo "=== Test Complete ==="
echo ""
echo "To view full logs:"
echo "  docker logs nullcity-dockertest"
echo ""
echo "To check build artifacts:"
echo "  ls -la imgbuild/work/*/deploy/*.img 2>/dev/null"
