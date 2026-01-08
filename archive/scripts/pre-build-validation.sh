#!/bin/bash
################################################################################
#
# Pre-Build Validation - Prüft ALLES bevor der Build startet
#
################################################################################

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

export PATH="/Applications/Docker.app/Contents/Resources/bin:$PATH"

ERRORS=0
WARNINGS=0

log() {
    echo "[$(date +%H:%M:%S)] $1"
}

error() {
    echo "❌ ERROR: $1"
    ERRORS=$((ERRORS + 1))
}

warning() {
    echo "⚠️  WARNING: $1"
    WARNINGS=$((WARNINGS + 1))
}

success() {
    echo "✅ $1"
}

log "=== PRE-BUILD VALIDATION ==="
log ""

# 1. Docker prüfen
log "1. Docker prüfen..."
if ! docker info >/dev/null 2>&1; then
    error "Docker läuft nicht"
else
    success "Docker läuft"
fi

# 2. Container prüfen
log ""
log "2. Container prüfen..."
if ! docker ps | grep -q moode-builder; then
    error "Container moode-builder läuft nicht"
else
    success "Container läuft"
fi

# 3. Build-Dateien prüfen
log ""
log "3. Build-Dateien prüfen..."

PACKAGES_FILE="imgbuild/moode-cfg/stage3_01-moode-install_01-packages"
if [ ! -f "$PACKAGES_FILE" ]; then
    error "Paket-Datei nicht gefunden: $PACKAGES_FILE"
else
    success "Paket-Datei gefunden"
    
    # Prüfe moode-player Version
    MOODE_VERSION=$(grep "^moode-player=" "$PACKAGES_FILE" | cut -d'=' -f2)
    if [ "$MOODE_VERSION" = "10.0.1-1moode1" ]; then
        error "Falsche moode-player Version: $MOODE_VERSION (sollte 10.0.0-1moode1 sein)"
    elif [ "$MOODE_VERSION" = "10.0.0-1moode1" ]; then
        success "moode-player Version korrekt: $MOODE_VERSION"
    else
        warning "Unbekannte moode-player Version: $MOODE_VERSION"
    fi
fi

# 4. Prüfe ob Datei im Container korrekt ist
log ""
log "4. Container-Dateien prüfen..."
CONTAINER_VERSION=$(docker exec moode-builder bash -c "grep '^moode-player=' /workspace/imgbuild/moode-cfg/stage3_01-moode-install_01-packages 2>/dev/null | cut -d'=' -f2" || echo "")
if [ "$CONTAINER_VERSION" = "10.0.1-1moode1" ]; then
    error "Container hat noch falsche Version: $CONTAINER_VERSION"
    log "   → Datei muss neu gemountet werden oder Container neu starten"
elif [ "$CONTAINER_VERSION" = "10.0.0-1moode1" ]; then
    success "Container hat korrekte Version: $CONTAINER_VERSION"
else
    warning "Container-Version unklar: '$CONTAINER_VERSION'"
fi

# 5. Work-Verzeichnis prüfen
log ""
log "5. Work-Verzeichnis prüfen..."
if docker exec moode-builder bash -c "[ -d '/tmp/pi-gen-work' ]" 2>/dev/null; then
    SIZE=$(docker exec moode-builder bash -c "du -sh /tmp/pi-gen-work 2>/dev/null | cut -f1" || echo "unbekannt")
    warning "Work-Verzeichnis existiert bereits ($SIZE) - sollte gelöscht werden für sauberen Start"
else
    success "Work-Verzeichnis ist leer (gut für sauberen Start)"
fi

# 6. Build-Script prüfen
log ""
log "6. Build-Script prüfen..."
if docker exec moode-builder bash -c "[ -f '/workspace/imgbuild/pi-gen-64/build.sh' ]" 2>/dev/null; then
    success "build.sh gefunden"
else
    error "build.sh nicht gefunden"
fi

# 7. Prüfe ob Build bereits läuft
log ""
log "7. Laufende Builds prüfen..."
if docker exec moode-builder pgrep -f "build.sh" >/dev/null 2>&1; then
    error "Build läuft bereits - muss zuerst gestoppt werden"
else
    success "Kein Build läuft"
fi

# 8. Disk Space prüfen
log ""
log "8. Disk Space prüfen..."
AVAILABLE=$(docker exec moode-builder bash -c "df -h /tmp | tail -1 | awk '{print \$4}'" 2>/dev/null || echo "unbekannt")
log "   Verfügbarer Platz: $AVAILABLE"
if [ "$AVAILABLE" != "unbekannt" ]; then
    # Extrahiere Zahl (z.B. "50G" -> 50)
    NUM=$(echo "$AVAILABLE" | sed 's/[^0-9]//g')
    if [ -n "$NUM" ] && [ "$NUM" -lt 20 ]; then
        warning "Wenig Disk Space: $AVAILABLE (empfohlen: >20GB)"
    else
        success "Ausreichend Disk Space: $AVAILABLE"
    fi
fi

# Zusammenfassung
log ""
log "=== VALIDATION SUMMARY ==="
log "Fehler: $ERRORS"
log "Warnungen: $WARNINGS"
log ""

if [ $ERRORS -gt 0 ]; then
    error "VALIDATION FEHLGESCHLAGEN - Build sollte NICHT gestartet werden!"
    exit 1
elif [ $WARNINGS -gt 0 ]; then
    warning "VALIDATION mit Warnungen - Build kann gestartet werden, aber Warnungen beachten"
    exit 0
else
    success "VALIDATION ERFOLGREICH - Build kann gestartet werden!"
    exit 0
fi

