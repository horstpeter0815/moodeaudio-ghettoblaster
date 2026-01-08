#!/bin/bash
# VALIDATE_BUILD_IMAGE.sh
# Validates the newest image after build using Docker simulation

set -e

LOG_FILE="build-validation-$(date +%Y%m%d_%H%M%S).log"
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log "=== BUILD IMAGE VALIDATION START ==="

# Find newest image
NEWEST_IMAGE=$(ls -t imgbuild/deploy/*.img 2>/dev/null | head -1)

if [ -z "$NEWEST_IMAGE" ]; then
    log "❌ Kein Image gefunden"
    exit 1
fi

ABSOLUTE_IMAGE=$(cd "$(dirname "$NEWEST_IMAGE")" && pwd)/$(basename "$NEWEST_IMAGE")
log "✅ Image gefunden: $(basename "$NEWEST_IMAGE")"
log "   Pfad: $ABSOLUTE_IMAGE"

# Check if Docker image-checker exists
if ! docker images | grep -q "image-checker"; then
    log "⚠️  Docker image-checker nicht gefunden, baue..."
    if [ -f "Dockerfile.image-check" ] && [ -f "check-image-contents.sh" ]; then
        docker build -t image-checker:latest -f Dockerfile.image-check . >/dev/null 2>&1
        log "✅ Docker image-checker gebaut"
    else
        log "❌ Dockerfile.image-check oder check-image-contents.sh nicht gefunden"
        exit 1
    fi
fi

# Run Docker validation
log ""
log "=== RUNNING DOCKER VALIDATION ==="
VALIDATION_OUTPUT=$(docker run --rm --privileged -v "$ABSOLUTE_IMAGE:/img.img:ro" image-checker:latest /check-image-contents.sh /img.img 2>&1)

# Check results
log ""
log "=== VALIDATION RESULTS ==="

CRITICAL_SERVICES=(
    "ssh-ultra-early.service"
    "first-boot-setup.service"
)

CRITICAL_SCRIPTS=(
    "force-ssh-on.sh"
    "first-boot-setup.sh"
)

ALL_OK=true

for service in "${CRITICAL_SERVICES[@]}"; do
    if echo "$VALIDATION_OUTPUT" | grep -q "$service FOUND in image"; then
        log "✅ $service FOUND in image"
    else
        log "❌ $service NOT FOUND in image"
        ALL_OK=false
    fi
done

for script in "${CRITICAL_SCRIPTS[@]}"; do
    if echo "$VALIDATION_OUTPUT" | grep -q "$script FOUND in image"; then
        log "✅ $script FOUND in image"
    else
        log "❌ $script NOT FOUND in image"
        ALL_OK=false
    fi
done

# Check if services are enabled
if echo "$VALIDATION_OUTPUT" | grep -q "ssh-ultra-early.service is ENABLED"; then
    log "✅ ssh-ultra-early.service is ENABLED"
else
    log "⚠️  ssh-ultra-early.service is NOT enabled (wird beim Boot enabled)"
fi

# Full validation output
log ""
log "=== FULL VALIDATION OUTPUT ==="
echo "$VALIDATION_OUTPUT" | tee -a "$LOG_FILE"

log ""
if [ "$ALL_OK" = true ]; then
    log "✅ ALLE KRITISCHEN KOMPONENTEN IM IMAGE"
    log "=== BUILD IMAGE VALIDATION SUCCESS ==="
    exit 0
else
    log "❌ FEHLENDE KOMPONENTEN IM IMAGE"
    log "=== BUILD IMAGE VALIDATION FAILED ==="
    exit 1
fi

