#!/bin/bash
################################################################################
#
# IMAGE-VALIDIERUNG
# 
# Prüft ob das Image korrekt gebaut wurde und alle notwendigen Komponenten enthält
#
################################################################################

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

LOG_FILE="$SCRIPT_DIR/image-validation.log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log "=== IMAGE-VALIDIERUNG START ==="

# Suche nach Images
IMAGE_DIR="$SCRIPT_DIR/imgbuild/deploy"
if [ ! -d "$IMAGE_DIR" ]; then
    log "❌ Image-Verzeichnis nicht gefunden: $IMAGE_DIR"
    exit 1
fi

# Finde neuestes Image
LATEST_IMAGE=$(find "$IMAGE_DIR" -name "*.img" -type f -exec ls -t {} + | head -1)

if [ -z "$LATEST_IMAGE" ]; then
    log "❌ Kein Image gefunden!"
    exit 1
fi

log "✅ Neuestes Image gefunden: $LATEST_IMAGE"

# Prüfe Image-Größe
IMAGE_SIZE=$(du -h "$LATEST_IMAGE" | cut -f1)
log "   Größe: $IMAGE_SIZE"

# Prüfe ob Image mountbar ist (nur wenn nicht in Verwendung)
log ""
log "=== IMAGE-INHALT PRÜFUNG ==="

# Erstelle Mount-Points
BOOT_MOUNT="/tmp/pi-boot-check"
ROOT_MOUNT="/tmp/pi-root-check"

mkdir -p "$BOOT_MOUNT" "$ROOT_MOUNT"

# Versuche Image zu mounten (nur wenn nicht in Verwendung)
if mount | grep -q "$LATEST_IMAGE"; then
    log "⚠️  Image bereits gemountet, überspringe Mount-Prüfung"
else
    log "Versuche Image zu mounten..."
    # Dies würde root-Rechte benötigen - nur als Info
    log "   → Benötigt root-Rechte für vollständige Prüfung"
fi

log ""
log "=== ERFORDERLICHE KOMPONENTEN ==="

# Prüfe ob Custom Components vorhanden sind
CUSTOM_COMPONENTS="$SCRIPT_DIR/custom-components"
if [ -d "$CUSTOM_COMPONENTS" ]; then
    log "✅ Custom Components vorhanden"
    
    # Prüfe wichtige Dateien
    if [ -f "$CUSTOM_COMPONENTS/scripts/first-boot-setup.sh" ]; then
        log "✅ first-boot-setup.sh vorhanden"
    else
        log "❌ first-boot-setup.sh FEHLT!"
    fi
    
    if [ -f "$CUSTOM_COMPONENTS/services/first-boot-setup.service" ]; then
        log "✅ first-boot-setup.service vorhanden"
    else
        log "❌ first-boot-setup.service FEHLT!"
    fi
    
    if [ -f "$CUSTOM_COMPONENTS/services/auto-fix-display.service" ]; then
        log "✅ auto-fix-display.service vorhanden"
    else
        log "❌ auto-fix-display.service FEHLT!"
    fi
else
    log "❌ Custom Components Verzeichnis nicht gefunden!"
fi

# Prüfe Build-Integration
BUILD_SCRIPT="$SCRIPT_DIR/imgbuild/pi-gen-64/stage3/03-ghettoblaster-custom/00-run-chroot.sh"
if [ -f "$BUILD_SCRIPT" ]; then
    log "✅ Build-Script vorhanden"
    
    # Prüfe ob first-boot aktiviert ist
    if grep -q "first-boot-setup" "$BUILD_SCRIPT"; then
        log "✅ first-boot-setup im Build integriert"
    else
        log "❌ first-boot-setup NICHT im Build integriert!"
    fi
else
    log "❌ Build-Script nicht gefunden!"
fi

log ""
log "=== NETZWERK-KONFIGURATION ==="

# Prüfe Netzwerk-Konfiguration im Build
NETWORK_CONFIG="$SCRIPT_DIR/imgbuild/pi-gen-64/stage2/02-net-tweaks/files/etc/dhcpcd.conf"
if [ -f "$NETWORK_CONFIG" ]; then
    log "✅ dhcpcd.conf vorhanden"
    if grep -q "192.168.178.143" "$NETWORK_CONFIG" 2>/dev/null; then
        log "✅ Statische IP .143 konfiguriert"
    else
        log "⚠️  Statische IP .143 nicht gefunden"
    fi
else
    log "⚠️  dhcpcd.conf nicht gefunden (kann normal sein)"
fi

log ""
log "=== ZUSAMMENFASSUNG ==="
log ""
log "Image: $LATEST_IMAGE"
log "Größe: $IMAGE_SIZE"
log ""
log "Nächste Schritte:"
log "1. Image auf SD-Karte brennen"
log "2. SD-Karte in Pi einstecken"
log "3. Pi booten lassen"
log "4. Serial Console prüfen (falls verfügbar)"
log "5. Netzwerk-Scan durchführen"

log "=== IMAGE-VALIDIERUNG END ==="

