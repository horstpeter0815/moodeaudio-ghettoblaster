#!/bin/bash
################################################################################
#
# AUTONOMOUS ARCHIVE SYSTEM
# 
# Archiviert automatisch alte Dateien auf NAS
# Läuft kontinuierlich im Hintergrund
#
################################################################################

set -e

PROJECT_DIR="/Users/andrevollmer/Library/Mobile Documents/com~apple~CloudDocs/Ablage/Roon filters/Bose Wave/OS/RPi4/moodeaudio/cursor"
LOG_FILE="/tmp/autonomous-archive-$(date +%Y%m%d).log"
# NAS Mount-Point (prüfe beide mögliche Orte)
if [ -d "/Volumes/IllerNAS" ]; then
    NAS_MOUNT_POINT="/Volumes/IllerNAS"
elif [ -d "/Users/andrevollmer/fritz-nas-archive" ]; then
    NAS_MOUNT_POINT="/Users/andrevollmer/fritz-nas-archive"
else
    NAS_MOUNT_POINT="/Volumes/IllerNAS"  # Standard
fi
ARCHIVE_DIR="$NAS_MOUNT_POINT/hifiberry-project-archive"

# Prüfe ob NAS gemountet ist
check_nas_mounted() {
    # Prüfe beide mögliche Mount-Points
    if mount | grep -q "IllerNAS" || [ -d "/Volumes/IllerNAS" ] || [ -d "/Users/andrevollmer/fritz-nas-archive" ]; then
        # Setze korrekten Mount-Point
        if [ -d "/Volumes/IllerNAS" ]; then
            NAS_MOUNT_POINT="/Volumes/IllerNAS"
        elif [ -d "/Users/andrevollmer/fritz-nas-archive" ]; then
            NAS_MOUNT_POINT="/Users/andrevollmer/fritz-nas-archive"
        fi
        ARCHIVE_DIR="$NAS_MOUNT_POINT/hifiberry-project-archive"
        return 0
    else
        return 1
    fi
}

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

archive_old_files() {
    log "=== ARCHIVE CYCLE START ==="
    
    # Prüfe NAS
    if ! check_nas_mounted; then
        log "⚠️  NAS nicht gemountet, überspringe Archivierung"
        return 1
    fi
    
    log "✅ NAS verfügbar: $NAS_MOUNT_POINT"
    
    # Erstelle Archiv-Verzeichnis
    mkdir -p "$ARCHIVE_DIR"
    
    # 1. Alte Log-Dateien (>7 Tage)
    log "Archiviere alte Log-Dateien..."
    find "$PROJECT_DIR" -name "*.log" -type f -mtime +7 -exec rsync -av {} "$ARCHIVE_DIR/logs/" \; 2>&1 | tail -3 | tee -a "$LOG_FILE"
    
    # 2. Alte Build-Artefakte (>30 Tage)
    log "Archiviere alte Build-Artefakte..."
    find "$PROJECT_DIR/imgbuild/deploy" -type f -mtime +30 -exec rsync -av {} "$ARCHIVE_DIR/builds/" \; 2>&1 | tail -3 | tee -a "$LOG_FILE"
    
    # 3. Alte Simulation-Logs
    log "Archiviere Simulation-Logs..."
    if [ -d "$PROJECT_DIR/complete-sim-logs" ]; then
        rsync -av "$PROJECT_DIR/complete-sim-logs/" "$ARCHIVE_DIR/sim-logs/" 2>&1 | tail -3 | tee -a "$LOG_FILE"
    fi
    
    # 4. Große temporäre Dateien
    log "Archiviere temporäre Dateien..."
    find "$PROJECT_DIR" -name "*.tmp" -o -name "*.bak" -o -name "*~" -type f -mtime +7 -exec rsync -av {} "$ARCHIVE_DIR/temp/" \; 2>&1 | tail -3 | tee -a "$LOG_FILE"
    
    log "✅ Archivierung abgeschlossen"
    
    # Zeige Archiv-Größe
    ARCHIVE_SIZE=$(du -sh "$ARCHIVE_DIR" 2>/dev/null | awk '{print $1}')
    log "Archiv-Größe: $ARCHIVE_SIZE"
    
    return 0
}

# Haupt-Loop
log "=== AUTONOMOUS ARCHIVE SYSTEM STARTED ==="
log "NAS Mount Point: $NAS_MOUNT_POINT"
log "Archive Directory: $ARCHIVE_DIR"
log "Check interval: 1 hour"

while true; do
    archive_old_files
    
    # Warte 1 Stunde bis zum nächsten Check
    log "Warte 1 Stunde bis zum nächsten Archivierungs-Cycle..."
    sleep 3600
done

