#!/bin/bash
################################################################################
#
# Build moOde Image in Docker Container
#
################################################################################

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

log() {
    echo "[$(date +%H:%M:%S)] $1"
}

log "=== BUILD IN DOCKER ==="
log ""

# Check if container exists
if docker ps -a | grep -q moode-builder; then
    log "Container existiert - starte..."
    docker start -ai moode-builder
else
    log "Container existiert nicht - erstelle..."
    cd "$SCRIPT_DIR"
    docker-compose -f docker-compose.build.yml up --build -d
    
    log ""
    log "Container gestartet. Verbinden mit:"
    log "  docker exec -it moode-builder bash"
    log ""
    log "Oder direkt Build starten:"
    log "  docker exec -it moode-builder bash -c 'cd /workspace/imgbuild && ./build.sh'"
fi
