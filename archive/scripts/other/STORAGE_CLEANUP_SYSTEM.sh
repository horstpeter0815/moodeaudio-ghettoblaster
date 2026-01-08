#!/bin/bash
################################################################################
#
# STORAGE CLEANUP SYSTEM
# 
# Systematische Bereinigung und Strukturierung
# - Analysiert was gebraucht wird
# - Archiviert auf NAS
# - Löscht Garbage
# - Erstellt neue Struktur
#
################################################################################

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

LOG_FILE="$SCRIPT_DIR/logs/cleanup/cleanup-$(date +%Y%m%d_%H%M%S).log"
NAS_MOUNT="$HOME/fritz-nas-archive"
NAS_ARCHIVE="$NAS_MOUNT/hifiberry-project-archive"

mkdir -p "$(dirname "$LOG_FILE")"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

################################################################################
# 1. ANALYSE: Was brauchen wir?
################################################################################

analyze_storage() {
    log "=== SPEICHERPLATZ ANALYSE ==="
    
    # Gesamter Speicherplatz
    TOTAL_SPACE=$(df -h . | tail -1 | awk '{print $2}')
    USED_SPACE=$(df -h . | tail -1 | awk '{print $3}')
    AVAIL_SPACE=$(df -h . | tail -1 | awk '{print $4}')
    USED_PERCENT=$(df -h . | tail -1 | awk '{print $5}')
    
    log "Gesamt: $TOTAL_SPACE | Verwendet: $USED_SPACE ($USED_PERCENT) | Verfügbar: $AVAIL_SPACE"
    
    # Größte Verzeichnisse
    log ""
    log "Größte Verzeichnisse:"
    du -sh */ 2>/dev/null | sort -hr | head -10 | while read size dir; do
        log "  $size  $dir"
    done
    
    # Dateien nach Typ
    log ""
    log "Dateien nach Typ:"
    IMG_COUNT=$(find . -maxdepth 2 \( -name "*.img" -o -name "*.img.gz" -o -name "*.img.zip" \) 2>/dev/null | wc -l | tr -d ' ')
    LOG_COUNT=$(find . -maxdepth 2 -name "*.log" 2>/dev/null | wc -l | tr -d ' ')
    BAK_COUNT=$(find . -maxdepth 2 \( -name "*.bak" -o -name "*.backup" -o -name "*.old" \) 2>/dev/null | wc -l | tr -d ' ')
    
    log "  Images: $IMG_COUNT"
    log "  Logs: $LOG_COUNT"
    log "  Backups: $BAK_COUNT"
}

################################################################################
# 2. KATEGORISIERUNG: Was behalten, was löschen?
################################################################################

categorize_files() {
    log ""
    log "=== KATEGORISIERUNG ==="
    
    # Dateien die BEHALTEN werden
    KEEP_DIRS=(
        "imgbuild"
        "moode-source"
        "custom-components"
        "hifiberry-os"
        "complete-sim-test"
        "system-sim-test"
        "pi-sim-test"
        "drivers-repos"
        "services-repos"
        "kernel-build"
        "docs"
        "documentation"
    )
    
    # Dateien die LÖSCHEN werden
    DELETE_PATTERNS=(
        "*.bak"
        "*.backup"
        "*.old"
        "*.tmp"
    )
    
    # Dateien die ARCHIVIEREN werden
    ARCHIVE_PATTERNS=(
        "*.img"
        "*.img.gz"
        "*.img.zip"
    )
    
    log "✅ Behalten: ${#KEEP_DIRS[@]} Verzeichnisse"
    log "❌ Löschen: Backup/Temp-Dateien"
    log "📦 Archivieren: Images und alte Logs"
}

################################################################################
# 3. ARCHIVIERUNG: Auf NAS verschieben
################################################################################

archive_to_nas() {
    log ""
    log "=== ARCHIVIERUNG AUF NAS ==="
    
    # Prüfe NAS-Mount
    if ! mount | grep -q "$NAS_MOUNT"; then
        log "⚠️  NAS nicht gemountet, versuche zu mounten..."
        if [ -f "$SCRIPT_DIR/SETUP_NAS.sh" ]; then
            bash "$SCRIPT_DIR/SETUP_NAS.sh" || log "❌ NAS-Mount fehlgeschlagen"
        else
            log "❌ SETUP_NAS.sh nicht gefunden"
            return 1
        fi
    fi
    
    if ! mount | grep -q "$NAS_MOUNT"; then
        log "❌ NAS nicht verfügbar, überspringe Archivierung"
        return 1
    fi
    
    log "✅ NAS verfügbar: $NAS_MOUNT"
    
    # Erstelle Archiv-Struktur
    mkdir -p "$NAS_ARCHIVE/images"
    mkdir -p "$NAS_ARCHIVE/logs"
    mkdir -p "$NAS_ARCHIVE/history"
    mkdir -p "$NAS_ARCHIVE/temp/big-data-dumps"
    
    # Archiviere Images (außer aktuellste)
    log "📦 Archiviere alte Images..."
    IMAGE_COUNT=0
    find . -maxdepth 2 \( -name "*.img" -o -name "*.img.gz" -o -name "*.img.zip" \) -type f 2>/dev/null | \
        sort -t- -k2 -r | tail -n +2 | while read img; do
            if [ -f "$img" ]; then
                log "  → $img"
                mv "$img" "$NAS_ARCHIVE/images/" 2>/dev/null && IMAGE_COUNT=$((IMAGE_COUNT + 1)) || true
            fi
        done
    log "✅ $IMAGE_COUNT Images archiviert"
    
    # Archiviere alte Logs (>30 Tage)
    log "📦 Archiviere alte Logs (>30 Tage)..."
    LOG_COUNT=0
    find . -maxdepth 2 -name "*.log" -type f -mtime +30 2>/dev/null | while read logfile; do
        if [ -f "$logfile" ]; then
            log "  → $logfile"
            mv "$logfile" "$NAS_ARCHIVE/logs/" 2>/dev/null && LOG_COUNT=$((LOG_COUNT + 1)) || true
        fi
    done
    log "✅ $LOG_COUNT alte Logs archiviert"
}

################################################################################
# 4. LÖSCHUNG: Garbage entfernen
################################################################################

delete_garbage() {
    log ""
    log "=== LÖSCHUNG VON GARBAGE ==="
    
    # Backup-Dateien
    log "🗑️  Lösche Backup-Dateien..."
    DEL_COUNT=0
    find . -maxdepth 3 \( -name "*.bak" -o -name "*.backup" -o -name "*.old" -o -name "*.tmp" \) -type f 2>/dev/null | while read file; do
        # Überspringe wichtige Backups
        if [[ "$file" != *"INTEGRATE_CUSTOM_COMPONENTS.sh.bak"* ]] && \
           [[ "$file" != *"custom-components"* ]]; then
            log "  → $file"
            rm -f "$file" 2>/dev/null && DEL_COUNT=$((DEL_COUNT + 1)) || true
        fi
    done
    log "✅ $DEL_COUNT Backup-Dateien gelöscht"
    
    # Alte Build-Logs (>7 Tage)
    log "🗑️  Lösche alte Build-Logs (>7 Tage)..."
    BUILD_LOG_COUNT=0
    find . -maxdepth 2 -name "*build*.log" -type f -mtime +7 2>/dev/null | while read logfile; do
        log "  → $logfile"
        rm -f "$logfile" 2>/dev/null && BUILD_LOG_COUNT=$((BUILD_LOG_COUNT + 1)) || true
    done
    log "✅ $BUILD_LOG_COUNT alte Build-Logs gelöscht"
}

################################################################################
# 5. STRUKTURIERUNG: Neue Ordnerstruktur
################################################################################

create_structure() {
    log ""
    log "=== ERSTELLE NEUE STRUKTUR ==="
    
    # Erstelle neue Struktur
    mkdir -p build/images
    mkdir -p build/logs
    mkdir -p build/temp
    mkdir -p logs/autonomous
    mkdir -p logs/build
    mkdir -p logs/test
    mkdir -p logs/system
    mkdir -p tests/unit
    mkdir -p tests/integration
    mkdir -p tests/simulation
    mkdir -p docs/theory
    mkdir -p docs/guides
    mkdir -p docs/active
    mkdir -p scripts/build
    mkdir -p scripts/deploy
    mkdir -p scripts/maintenance
    
    log "✅ Neue Struktur erstellt"
    
    # Verschiebe aktuelle Logs
    log "📁 Organisiere aktuelle Logs..."
    if [ -f "autonomous-work.log" ]; then
        mv "autonomous-work.log" "logs/autonomous/autonomous-work-$(date +%Y%m%d).log" 2>/dev/null || true
    fi
    
    # Verschiebe Test-Suite
    if [ -d "complete-sim-test" ]; then
        cp -r "complete-sim-test" "tests/simulation/" 2>/dev/null || true
    fi
}

################################################################################
# 6. NAS TEMP CLEANUP: Nach 2-4 Wochen löschen
################################################################################

cleanup_nas_temp() {
    log ""
    log "=== NAS TEMP CLEANUP ==="
    
    if ! mount | grep -q "$NAS_MOUNT"; then
        log "⚠️  NAS nicht gemountet, überspringe"
        return 1
    fi
    
    TEMP_DIR="$NAS_ARCHIVE/temp/big-data-dumps"
    
    if [ ! -d "$TEMP_DIR" ]; then
        log "⚠️  Temp-Verzeichnis existiert nicht"
        return 0
    fi
    
    # Lösche Dateien älter als 2 Wochen (14 Tage)
    log "🗑️  Lösche Temp-Dateien älter als 2 Wochen..."
    DEL_COUNT=0
    find "$TEMP_DIR" -type f -mtime +14 2>/dev/null | while read file; do
        log "  → $file"
        rm -f "$file" 2>/dev/null && DEL_COUNT=$((DEL_COUNT + 1)) || true
    done
    log "✅ $DEL_COUNT Temp-Dateien gelöscht"
    
    # Lösche leere Verzeichnisse
    find "$TEMP_DIR" -type d -empty -delete 2>/dev/null || true
}

################################################################################
# MAIN
################################################################################

main() {
    log "╔══════════════════════════════════════════════════════════════╗"
    log "║  🧹 STORAGE CLEANUP SYSTEM START                            ║"
    log "╚══════════════════════════════════════════════════════════════╝"
    log ""
    
    analyze_storage
    categorize_files
    archive_to_nas
    delete_garbage
    create_structure
    cleanup_nas_temp
    
    log ""
    log "=== CLEANUP ABGESCHLOSSEN ==="
    log "📋 Log: $LOG_FILE"
    
    # Zeige Ergebnis
    log ""
    log "=== ERGEBNIS ==="
    TOTAL_SPACE=$(df -h . | tail -1 | awk '{print $2}')
    USED_SPACE=$(df -h . | tail -1 | awk '{print $3}')
    AVAIL_SPACE=$(df -h . | tail -1 | awk '{print $4}')
    USED_PERCENT=$(df -h . | tail -1 | awk '{print $5}')
    log "Gesamt: $TOTAL_SPACE | Verwendet: $USED_SPACE ($USED_PERCENT) | Verfügbar: $AVAIL_SPACE"
}

# Führe aus
main "$@"

