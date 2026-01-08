#!/bin/bash
################################################################################
#
# Docker Build Setup für moOde Custom Build
#
# Erstellt Docker-Container für moOde Image Build auf macOS
#
# (C) 2025 Ghettoblaster Custom Build
# License: GPLv3
#
################################################################################

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$SCRIPT_DIR"
BUILD_DIR="$PROJECT_DIR/imgbuild"

log() {
    echo "[$(date +%H:%M:%S)] $1"
}

error() {
    echo "[ERROR] $1" >&2
    exit 1
}

log "=== DOCKER BUILD SETUP ==="
log "Projekt: Ghettoblaster Custom Build"
log ""

# Check Docker
if ! command -v docker &> /dev/null; then
    error "Docker ist nicht installiert. Bitte Docker Desktop installieren: https://www.docker.com/products/docker-desktop/"
fi

log "✅ Docker gefunden: $(docker --version)"

# Check Docker running
if ! docker info &> /dev/null; then
    error "Docker läuft nicht. Bitte Docker Desktop starten."
fi

log "✅ Docker läuft"

# Check Build-Directory
if [ ! -d "$BUILD_DIR" ]; then
    error "Build-Directory nicht gefunden: $BUILD_DIR"
fi

log "✅ Build-Directory gefunden: $BUILD_DIR"

# Create Dockerfile for build environment
log ""
log "=== ERSTELLE DOCKERFILE ==="

cat > "$PROJECT_DIR/Dockerfile.build" << 'EOF'
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC

# Install build dependencies
RUN apt-get update && apt-get install -y \
    git \
    coreutils \
    qemu-user-static \
    binfmt-support \
    parted \
    kpartx \
    debootstrap \
    dosfstools \
    rsync \
    bc \
    bison \
    flex \
    libssl-dev \
    make \
    gcc \
    g++ \
    build-essential \
    python3 \
    python3-pip \
    curl \
    wget \
    && rm -rf /var/lib/apt/lists/*

# Setup build environment
WORKDIR /workspace

# Entry point
ENTRYPOINT ["/bin/bash"]
EOF

log "✅ Dockerfile erstellt: $PROJECT_DIR/Dockerfile.build"

# Create docker-compose for build
log ""
log "=== ERSTELLE DOCKER-COMPOSE ==="

cat > "$PROJECT_DIR/docker-compose.build.yml" << EOF
version: '3.8'

services:
  moode-builder:
    build:
      context: .
      dockerfile: Dockerfile.build
    container_name: moode-builder
    volumes:
      - "$BUILD_DIR:/workspace/imgbuild"
      - "$PROJECT_DIR/custom-components:/workspace/custom-components"
      - build-cache:/workspace/cache
    environment:
      - DEBIAN_FRONTEND=noninteractive
      - TZ=UTC
    stdin_open: true
    tty: true
    privileged: true
    network_mode: host

volumes:
  build-cache:
EOF

log "✅ Docker-Compose erstellt: $PROJECT_DIR/docker-compose.build.yml"

# Create build script
log ""
log "=== ERSTELLE BUILD-SCRIPT ==="

cat > "$PROJECT_DIR/build-in-docker.sh" << 'EOF'
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
EOF

chmod +x "$PROJECT_DIR/build-in-docker.sh"

log "✅ Build-Script erstellt: $PROJECT_DIR/build-in-docker.sh"

log ""
log "=== SETUP ABGESCHLOSSEN ==="
log ""
log "Nächste Schritte:"
log "  1. Container bauen: docker-compose -f docker-compose.build.yml build"
log "  2. Container starten: docker-compose -f docker-compose.build.yml up -d"
log "  3. Container betreten: docker exec -it moode-builder bash"
log "  4. Build starten: cd /workspace/imgbuild && ./build.sh"
log ""
log "Oder einfach: ./build-in-docker.sh"
log ""

