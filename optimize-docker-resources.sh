#!/bin/bash
################################################################################
#
# Docker-Ressourcen optimieren für Build
# Nutzt die volle Mac-Power (48GB RAM, 16 CPUs)
#
################################################################################

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

export PATH="/Applications/Docker.app/Contents/Resources/bin:$PATH"

log() {
    echo "[$(date +%H:%M:%S)] $1"
}

log "=== DOCKER-RESSOURCEN OPTIMIERUNG ==="
log ""

# Prüfe ob Container läuft
if ! docker ps | grep -q moode-builder; then
    log "⚠️  Container läuft nicht - starte zuerst: docker-compose up -d"
    exit 1
fi

# Aktuelle Ressourcen prüfen
log "Aktuelle Container-Ressourcen:"
docker stats moode-builder --no-stream --format "CPU: {{.CPUPerc}} | Memory: {{.MemUsage}}"

log ""
log "Optimierte Konfiguration:"
log "  - CPUs: 16 (max)"
log "  - Memory: 32GB (von 48GB verfügbar)"
log "  - Parallel Build: 16 Jobs"
log ""

# Container neu starten mit optimierten Ressourcen
log "Container mit optimierten Ressourcen neu starten..."
docker-compose -f docker-compose.build.yml up -d --force-recreate

sleep 3

log ""
log "Neue Container-Ressourcen:"
docker stats moode-builder --no-stream --format "CPU: {{.CPUPerc}} | Memory: {{.MemUsage}}"

log ""
log "✅ Docker-Ressourcen optimiert!"
log ""
log "Hinweis: Build läuft weiter, nutzt jetzt mehr Ressourcen"

