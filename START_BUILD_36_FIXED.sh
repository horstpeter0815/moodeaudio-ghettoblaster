#!/bin/bash
# Start Build 36 - Connection Guaranteed (Fixed Docker Version)
# This build focuses on SSH and network connectivity

set -e

# Get project directory (works from anywhere)
if [ -f "${BASH_SOURCE[0]}" ]; then
    PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
else
    PROJECT_DIR="$HOME/moodeaudio-cursor"
fi

cd "$PROJECT_DIR"

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  🔨 BUILD 36 - CONNECTION GUARANTEED                        ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Pre-build verification
echo "=== PRE-BUILD VERIFICATION ==="
echo ""

# Check critical services
MISSING=0
for service in ssh-guaranteed.service fix-user-id.service eth0-direct-static.service boot-complete-minimal.service; do
    if [ ! -f "moode-source/lib/systemd/system/$service" ]; then
        echo "❌ MISSING: $service"
        MISSING=1
    else
        echo "✅ Found: $service"
    fi
done

if [ $MISSING -eq 1 ]; then
    echo ""
    echo "❌ ERROR: Missing critical services. Cannot build."
    exit 1
fi

echo ""
echo "✅ All critical services found"
echo ""

# Check deployment script
if [ ! -f "imgbuild/moode-cfg/stage3_03-ghettoblaster-custom_00-deploy.sh" ]; then
    echo "❌ ERROR: Deployment script not found"
    exit 1
fi

echo "✅ Deployment script found"
echo ""

# Check build system
if [ ! -d "imgbuild/pi-gen-64" ]; then
    echo "❌ ERROR: Build system not found"
    exit 1
fi

echo "✅ Build system ready"
echo ""

# Check if we're on macOS (needs Docker)
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "🐳 macOS detected - Build must run in Docker"
    echo ""
    
    # Check Docker and start if needed
    if ! docker info >/dev/null 2>&1; then
        echo "🐳 Docker is not running - Attempting to start..."
        echo ""
        
        # Try to start Docker Desktop (macOS)
        if command -v open >/dev/null 2>&1; then
            echo "Starting Docker Desktop..."
            open -a Docker 2>/dev/null || true
            
            echo "Waiting for Docker to start (this may take 30-60 seconds)..."
            echo ""
            
            # Wait up to 2 minutes for Docker to start
            MAX_WAIT=120
            ELAPSED=0
            while [ $ELAPSED -lt $MAX_WAIT ]; do
                if docker info >/dev/null 2>&1; then
                    echo "✅ Docker is now running!"
                    echo ""
                    break
                fi
                sleep 2
                ELAPSED=$((ELAPSED + 2))
                if [ $((ELAPSED % 10)) -eq 0 ]; then
                    echo "   Still waiting... ($ELAPSED seconds)"
                fi
            done
            
            # Final check
            if ! docker info >/dev/null 2>&1; then
                echo "❌ ERROR: Docker did not start in time"
                echo ""
                echo "Please:"
                echo "  1. Start Docker Desktop manually"
                echo "  2. Wait for Docker to be ready"
                echo "  3. Run this script again"
                echo ""
                exit 1
            fi
        else
            echo "❌ ERROR: Cannot start Docker automatically"
            echo "   Please start Docker Desktop manually"
            exit 1
        fi
    fi
    
    echo "✅ Docker is running"
    echo ""
    echo "Starting Docker-based build..."
    echo ""
    
    # Use Docker build
    cd "$PROJECT_DIR"
    
    # Clean up orphan containers
    echo "Cleaning up old containers..."
    docker-compose -f docker-compose.build.yml down --remove-orphans 2>/dev/null || true
    
    # Build Docker image if needed
    echo "Building/checking Docker image..."
    docker-compose -f docker-compose.build.yml build
    
    # Start container and run build
    echo ""
    echo "=== STARTING BUILD 36 IN DOCKER ==="
    echo ""
    echo "This build includes:"
    echo "  ✅ SSH guaranteed (multiple layers)"
    echo "  ✅ User fix (andre, UID 1000)"
    echo "  ✅ Network fix (eth0 static IP)"
    echo "  ✅ Early boot services"
    echo ""
    echo "Build will take 30-60 minutes..."
    echo ""
    
    # Run build in container with proper bash path
    docker-compose -f docker-compose.build.yml run --rm \
        -e DEBIAN_FRONTEND=noninteractive \
        moode-builder \
        bash -c "cd /workspace/imgbuild && ./build.sh"
    
    echo ""
    echo "✅✅✅ BUILD 36 COMPLETE ✅✅✅"
    echo ""
    echo "Next steps:"
    echo "  1. Validate: ~/moodeaudio-cursor/tools/build.sh --validate"
    echo "  2. Test: ~/moodeaudio-cursor/tools/test.sh --image"
    echo "  3. Deploy: sudo ~/moodeaudio-cursor/tools/build.sh --deploy"
    echo ""
    exit 0
fi

# Linux: Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "⚠️  Build requires root privileges on Linux"
    echo ""
    echo "Please run with sudo:"
    echo "  sudo ~/moodeaudio-cursor/START_BUILD_36.sh"
    echo ""
    exit 1
fi

# Linux build (direct)
echo "=== STARTING BUILD 36 ==="
echo ""
echo "This build includes:"
echo "  ✅ SSH guaranteed (multiple layers)"
echo "  ✅ User fix (andre, UID 1000)"
echo "  ✅ Network fix (eth0 static IP)"
echo "  ✅ Early boot services"
echo ""
echo "Build will take 30-60 minutes..."
echo ""

# Start build
cd imgbuild/pi-gen-64
./build.sh "$@"

echo ""
echo "✅✅✅ BUILD 36 COMPLETE ✅✅✅"
echo ""
echo "Next steps:"
echo "  1. Validate: ./tools/build.sh --validate"
echo "  2. Test: ./tools/test.sh --image"
echo "  3. Deploy: ./tools/build.sh --deploy"
echo ""

