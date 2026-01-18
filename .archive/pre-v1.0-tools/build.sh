#!/bin/bash
################################################################################
#
# UNIFIED BUILD TOOL
# 
# Consolidates all build-related scripts into one unified tool
#
################################################################################

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[BUILD]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

################################################################################
# BUILD FUNCTIONS
################################################################################

build_image() {
    log "Starting image build..."
    
    # Check if Docker is running
    if ! docker info >/dev/null 2>&1; then
        error "Docker is not running. Please start Docker first."
        exit 1
    fi
    
    # Check if docker-compose file exists
    if [ ! -f "$PROJECT_ROOT/docker-compose.build.yml" ]; then
        error "docker-compose.build.yml not found"
        exit 1
    fi
    
    cd "$PROJECT_ROOT"
    
    # Build Docker image if needed
    if ! docker images | grep -q "moodeaudio-cursor-moode-builder"; then
        log "Building Docker image (first time only, this may take 5-10 minutes)..."
        docker-compose -f docker-compose.build.yml build
    else
        log "Docker image already exists, skipping build..."
    fi
    
    # Clean up orphan containers first
    docker-compose -f docker-compose.build.yml down --remove-orphans 2>/dev/null || true
    
    # Get CPU count for optimization
    CPU_COUNT=$(sysctl -n hw.ncpu 2>/dev/null || echo "8")
    log "Optimizing for $CPU_COUNT CPU cores..."
    
    log "Starting build in Docker container..."
    # Use DOCKER_DEFAULT_PLATFORM to force amd64 emulation (important for Apple Silicon)
    # Override entrypoint to avoid ENTRYPOINT ["/bin/bash"] conflict
    DOCKER_DEFAULT_PLATFORM=linux/amd64 docker-compose -f docker-compose.build.yml run --rm \
        --entrypoint /bin/bash \
        -e DEBIAN_FRONTEND=noninteractive \
        -e MAKEFLAGS="-j$CPU_COUNT" \
        -e DEB_BUILD_OPTIONS="parallel=$CPU_COUNT" \
        -e NPROC="$CPU_COUNT" \
        moode-builder \
        -c "update-binfmts --enable qemu-arm 2>/dev/null || true; cd /workspace/imgbuild/pi-gen-64 && bash build.sh"
    
    log "Build complete!"
}

monitor_build() {
    log "Monitoring build progress..."
    
    if [ -f "$PROJECT_ROOT/imgbuild/deploy/build-*.log" ]; then
        tail -f "$PROJECT_ROOT/imgbuild/deploy/build-*.log"
    else
        warn "No build log found. Build may not be running."
    fi
}

validate_build() {
    log "Validating build image..."
    
    LATEST_IMAGE=$(ls -t "$PROJECT_ROOT/imgbuild/deploy"/*.img 2>/dev/null | head -1)
    
    if [ -z "$LATEST_IMAGE" ]; then
        error "No image found to validate"
        exit 1
    fi
    
    log "Validating: $LATEST_IMAGE"
    
    # Check image size
    SIZE=$(du -h "$LATEST_IMAGE" | cut -f1)
    log "Image size: $SIZE"
    
    # Check if image is valid
    if file "$LATEST_IMAGE" | grep -q "DOS/MBR boot sector"; then
        log "✅ Image appears to be valid"
    else
        error "Image validation failed"
        exit 1
    fi
}

deploy_image() {
    log "Deploying image to SD card..."
    
    LATEST_IMAGE=$(ls -t "$PROJECT_ROOT/imgbuild/deploy"/*.img 2>/dev/null | head -1)
    
    if [ -z "$LATEST_IMAGE" ]; then
        error "No image found to deploy"
        exit 1
    fi
    
    log "Deploying: $LATEST_IMAGE"
    
    # Use existing burn script if available
    if [ -f "$PROJECT_ROOT/BURN_IMAGE_TO_SD.sh" ]; then
        bash "$PROJECT_ROOT/BURN_IMAGE_TO_SD.sh" "$LATEST_IMAGE"
    else
        error "BURN_IMAGE_TO_SD.sh not found"
        exit 1
    fi
}

cleanup_old_images() {
    log "Cleaning up old images..."
    
    if [ -f "$PROJECT_ROOT/AUTOMATIC_IMAGE_CLEANUP.sh" ]; then
        bash "$PROJECT_ROOT/AUTOMATIC_IMAGE_CLEANUP.sh"
    else
        warn "AUTOMATIC_IMAGE_CLEANUP.sh not found, using manual cleanup"
        
        cd "$PROJECT_ROOT/imgbuild/deploy"
        LATEST=$(ls -t *.img 2>/dev/null | head -1)
        if [ -n "$LATEST" ]; then
            ls -t *.img 2>/dev/null | tail -n +2 | xargs rm -f
            log "Old images deleted, keeping: $LATEST"
        fi
    fi
}

################################################################################
# MAIN MENU
################################################################################

show_menu() {
    echo ""
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║  🔨 BUILD TOOL - Unified Build Management                   ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo ""
    echo "1) Build new image"
    echo "2) Monitor build progress"
    echo "3) Validate build image"
    echo "4) Deploy image to SD card"
    echo "5) Cleanup old images"
    echo "6) Show build status"
    echo "0) Exit"
    echo ""
    read -p "Select option: " choice
}

show_build_status() {
    log "Build Status:"
    echo ""
    
    # Latest image
    LATEST_IMAGE=$(ls -t "$PROJECT_ROOT/imgbuild/deploy"/*.img 2>/dev/null | head -1)
    if [ -n "$LATEST_IMAGE" ]; then
        SIZE=$(du -h "$LATEST_IMAGE" | cut -f1)
        DATE=$(stat -f "%Sm" -t "%Y-%m-%d %H:%M:%S" "$LATEST_IMAGE" 2>/dev/null || stat -c "%y" "$LATEST_IMAGE" 2>/dev/null | cut -d' ' -f1-2)
        echo "  Latest Image: $(basename "$LATEST_IMAGE")"
        echo "  Size: $SIZE"
        echo "  Date: $DATE"
    else
        warn "No images found"
    fi
    
    # Build counter
    if [ -f "$PROJECT_ROOT/BUILD_COUNTER.txt" ]; then
        BUILD_NUM=$(cat "$PROJECT_ROOT/BUILD_COUNTER.txt")
        echo "  Build Number: $BUILD_NUM"
    fi
    
    # Docker status
    if docker info >/dev/null 2>&1; then
        echo "  Docker: ✅ Running"
    else
        echo "  Docker: ❌ Not running"
    fi
}

main() {
    if [ "$1" = "--build" ] || [ "$1" = "-b" ]; then
        build_image "${@:2}"
    elif [ "$1" = "--monitor" ] || [ "$1" = "-m" ]; then
        monitor_build
    elif [ "$1" = "--validate" ] || [ "$1" = "-v" ]; then
        validate_build
    elif [ "$1" = "--deploy" ] || [ "$1" = "-d" ]; then
        deploy_image
    elif [ "$1" = "--cleanup" ] || [ "$1" = "-c" ]; then
        cleanup_old_images
    elif [ "$1" = "--status" ] || [ "$1" = "-s" ]; then
        show_build_status
    elif [ -z "$1" ]; then
        # Interactive mode
        while true; do
            show_menu
            case $choice in
                1) build_image ;;
                2) monitor_build ;;
                3) validate_build ;;
                4) deploy_image ;;
                5) cleanup_old_images ;;
                6) show_build_status ;;
                0) exit 0 ;;
                *) error "Invalid option" ;;
            esac
            echo ""
            read -p "Press Enter to continue..."
        done
    else
        error "Unknown option: $1"
        echo "Usage: $0 [--build|--monitor|--validate|--deploy|--cleanup|--status]"
        exit 1
    fi
}

main "$@"

