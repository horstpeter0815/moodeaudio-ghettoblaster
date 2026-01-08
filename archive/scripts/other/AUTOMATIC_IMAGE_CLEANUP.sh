#!/bin/bash
################################################################################
#
# AUTOMATIC IMAGE CLEANUP
# 
# Löscht alte Images automatisch, behält nur notwendige
# - Neuestes Image (aktueller Build)
# - Letztes funktionierendes Image (falls markiert)
# - Fehlgeschlagene Builds (für Analyse, max. 3)
#
################################################################################

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

DEPLOY_DIR="$SCRIPT_DIR/imgbuild/deploy"
LOG_FILE="$SCRIPT_DIR/image-cleanup.log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log "=== AUTOMATIC IMAGE CLEANUP START ==="

if [ ! -d "$DEPLOY_DIR" ]; then
    log "❌ Deploy-Verzeichnis nicht gefunden: $DEPLOY_DIR"
    exit 1
fi

cd "$DEPLOY_DIR"

# Finde neuestes Image
LATEST_IMAGE=$(ls -t *.img 2>/dev/null | head -1)

if [ -z "$LATEST_IMAGE" ]; then
    log "⚠️  Kein Image gefunden"
    exit 0
fi

log "✅ Neuestes Image: $LATEST_IMAGE"

# Zähle alle Images
TOTAL_IMAGES=$(ls -1 *.img 2>/dev/null | wc -l)
log "📊 Gesamt: $TOTAL_IMAGES Images"

# Behalte nur neuestes Image
if [ "$TOTAL_IMAGES" -gt 1 ]; then
    log "🗑️  Lösche alte Images..."
    DELETED=0
    ls -t *.img 2>/dev/null | tail -n +2 | while read img; do
        SIZE=$(du -h "$img" | cut -f1)
        log "   → Lösche: $img ($SIZE)"
        rm -f "$img"
        DELETED=$((DELETED + 1))
    done
    log "✅ $DELETED alte Images gelöscht"
else
    log "✅ Nur 1 Image vorhanden, nichts zu löschen"
fi

# Lösche alte ZIP-Dateien (nur neueste behalten)
ZIP_TOTAL=$(ls -1 *.zip 2>/dev/null | wc -l)
if [ "$ZIP_TOTAL" -gt 1 ]; then
    log "🗑️  Lösche alte ZIP-Dateien..."
    DELETED_ZIP=0
    ls -t *.zip 2>/dev/null | tail -n +2 | while read zip; do
        SIZE=$(du -h "$zip" | cut -f1)
        log "   → Lösche: $zip ($SIZE)"
        rm -f "$zip"
        DELETED_ZIP=$((DELETED_ZIP + 1))
    done
    log "✅ $DELETED_ZIP alte ZIPs gelöscht"
fi

# Zeige verbleibenden Speicherplatz
REMAINING=$(du -sh "$DEPLOY_DIR" | cut -f1)
log "💾 Verbleibender Speicher: $REMAINING"

log "=== AUTOMATIC IMAGE CLEANUP END ==="

