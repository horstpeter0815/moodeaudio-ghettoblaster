#!/bin/bash
# Monitor NullCity.DockerTest Build and Auto-Fix Issues
# Run from HOME: bash ~/moodeaudio-cursor/scripts/test/MONITOR_NULLCITY_BUILD.sh

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  🔍 NullCity.DockerTest Build Monitor                        ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

PROJECT_DIR="$HOME/moodeaudio-cursor"
cd "$PROJECT_DIR"

CONTAINER_NAME="nullcity-dockertest"
LOG_FILE="$PROJECT_DIR/test-results/monitor.log"

mkdir -p "$PROJECT_DIR/test-results"

log() {
    echo "[$(date +%Y-%m-%d\ %H:%M:%S)] $1" | tee -a "$LOG_FILE"
}

fix_issue() {
    local issue=$1
    log "🔧 Fixing issue: $issue"
    
    case "$issue" in
        "display_script")
            log "Fixing display cmdline script..."
            if docker exec "$CONTAINER_NAME" bash -c "grep -q 'fbcon=rotate:1' /workspace/imgbuild/moode-cfg/stage3_03-ghettoblaster-custom_02-display-cmdline.sh" 2>/dev/null; then
                docker exec "$CONTAINER_NAME" bash -c "sed -i 's/ fbcon=rotate:1//' /workspace/imgbuild/moode-cfg/stage3_03-ghettoblaster-custom_02-display-cmdline.sh"
                log "✅ Fixed: Removed fbcon=rotate:1"
            fi
            ;;
        "build_failed")
            log "Build failed - checking logs..."
            docker logs "$CONTAINER_NAME" --tail 50 >> "$LOG_FILE"
            log "Check $LOG_FILE for details"
            ;;
        "missing_deps")
            log "Missing dependencies - installing..."
            docker exec "$CONTAINER_NAME" bash -c "cd /workspace/imgbuild && apt-get update && apt-get install -y build-essential" 2>&1 | tee -a "$LOG_FILE"
            ;;
    esac
}

# Start monitoring
log "Starting build monitor..."
log "Container: $CONTAINER_NAME"

# Wait for container to start
log "Waiting for container to start..."
for i in {1..30}; do
    if docker ps | grep -q "$CONTAINER_NAME"; then
        log "✅ Container is running"
        break
    fi
    sleep 2
done

# Monitor build process
log "Monitoring build process..."
while docker ps | grep -q "$CONTAINER_NAME"; do
    # Check for common issues
    if docker logs "$CONTAINER_NAME" 2>&1 | grep -qi "fbcon=rotate:1"; then
        log "⚠️  Issue detected: fbcon in build script"
        fix_issue "display_script"
    fi
    
    if docker logs "$CONTAINER_NAME" 2>&1 | grep -qi "drmSetMaster failed\|DRM master"; then
        log "⚠️  Issue detected: DRM master conflict"
        fix_issue "display_script"
    fi
    
    if docker logs "$CONTAINER_NAME" 2>&1 | grep -qi "error\|failed\|fatal"; then
        log "⚠️  Error detected in build logs"
        # Don't auto-fix errors, just log them
    fi
    
    sleep 10
done

# Build complete
log "Build process completed"
log "Final status check..."

# Check if build was successful
if docker logs "$CONTAINER_NAME" 2>&1 | grep -qi "Build Complete\|build complete"; then
    log "✅ Build appears successful"
else
    log "⚠️  Build may have failed - check logs"
    fix_issue "build_failed"
fi

# Save final logs
log "Saving final logs..."
docker logs "$CONTAINER_NAME" > "$PROJECT_DIR/test-results/docker-logs.txt" 2>&1

log "Monitor complete. Check $LOG_FILE for details."
