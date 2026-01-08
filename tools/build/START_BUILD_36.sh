#!/bin/bash
# Start Build 36 - Connection Guaranteed
# This build focuses on SSH and network connectivity
# Usage: Can be run from anywhere

set -e

# Get project directory (works from anywhere)
if [ -f "${BASH_SOURCE[0]}" ]; then
    # Script is in project root
    PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
else
    # Fallback: assume we're in home directory
    PROJECT_DIR="$HOME/moodeaudio-cursor"
fi

cd "$PROJECT_DIR"

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  🔨 BUILD 36                                                  ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Pre-build verification
echo "=== PRE-BUILD VERIFICATION ==="
echo ""

# Check critical services
MISSING=0
for service in 01-ssh-enable.service fix-user-id.service 02-eth0-configure.service 00-boot-network-ssh.service; do
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
    
    # Build Docker image if needed
    if ! docker images | grep -q "moodeaudio-cursor-moode-builder"; then
        echo "Building Docker image (first time only, this may take 5-10 minutes)..."
        docker-compose -f docker-compose.build.yml build --no-cache
    fi
    
    # Start container and run build
    echo "Starting build in Docker container..."
    echo "This will take 30-60 minutes..."
    echo ""
    
    # Clean up orphan containers first
    echo "Cleaning up old containers..."
    docker-compose -f docker-compose.build.yml down --remove-orphans 2>/dev/null || true
    
    # Get CPU count for optimization
    CPU_COUNT=$(sysctl -n hw.ncpu 2>/dev/null || echo "8")
    echo ""
    echo "🚀 Optimizing for maximum performance:"
    echo "   CPU cores: $CPU_COUNT"
    echo "   Parallel jobs: $CPU_COUNT"
    echo "   Memory: Maximum available"
    echo ""
    
    # Create log file for build output
    BUILD_LOG="$PROJECT_DIR/imgbuild/deploy/build-36-$(date +%Y%m%d_%H%M%S).log"
    echo "Build log: $BUILD_LOG"
    echo ""
    
    # Use docker-compose run with proper bash and max resources
    # Note: --cpus flag not supported in docker-compose run, using environment variables instead
    # Output goes to both console AND log file
    # Ensure QEMU binfmt is enabled for ARM emulation
    # Explicitly set platform to force amd64 emulation
    DOCKER_DEFAULT_PLATFORM=linux/amd64 docker-compose -f docker-compose.build.yml run --rm \
        -e DEBIAN_FRONTEND=noninteractive \
        -e MAKEFLAGS="-j$CPU_COUNT" \
        -e DEB_BUILD_OPTIONS="parallel=$CPU_COUNT" \
        -e NPROC="$CPU_COUNT" \
        moode-builder \
        bash -c "update-binfmts --enable qemu-arm 2>/dev/null || true; cd /workspace/imgbuild/pi-gen-64 && bash build.sh" 2>&1 | tee "$BUILD_LOG"
    
    echo ""
    echo "✅✅✅ BUILD 36 COMPLETE ✅✅✅"
    echo ""
    echo "=== VERIFYING BUILD ==="
    echo ""
    echo "Checking if all critical services are included..."
    echo ""
    
    # Run verification
    if [ -f "$PROJECT_DIR/VERIFY_BUILD_AFTER_COMPLETE.sh" ]; then
        "$PROJECT_DIR/VERIFY_BUILD_AFTER_COMPLETE.sh"
    else
        echo "⚠️  Verification script not found, skipping verification"
    fi
    
    echo ""
    echo "=== NEXT STEPS ==="
    echo ""
    echo "1. Verify build: ~/moodeaudio-cursor/VERIFY_BUILD_AFTER_COMPLETE.sh"
    echo "2. Test in Docker: ~/moodeaudio-cursor/tools/test.sh --image"
    echo "3. Deploy to SD card: sudo ~/moodeaudio-cursor/tools/build.sh --deploy"
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

# Check Docker (for Linux too, in case)
if ! docker info >/dev/null 2>&1; then
    echo "⚠️  WARNING: Docker is not running"
    echo "   Build may fail. Start Docker first."
    echo ""
fi

echo "=== STARTING BUILD 36 ==="
echo ""
echo "This build includes:"
    echo "  ✅ SSH enable service"
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

