#!/bin/bash
################################################################################
#
# AUTOMATED CLEANUP SCHEDULE
# 
# Führt Cleanup automatisch aus:
# - Täglich: Log-Rotation
# - Wöchentlich: Storage Cleanup
# - Monatlich: NAS Temp Cleanup (2-4 Wochen)
#
################################################################################

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

CLEANUP_SCRIPT="$SCRIPT_DIR/STORAGE_CLEANUP_SYSTEM.sh"
LOG_FILE="$SCRIPT_DIR/logs/system/cleanup-schedule.log"

mkdir -p "$(dirname "$LOG_FILE")"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Tägliche Log-Rotation
daily_log_rotation() {
    log "=== TÄGLICHE LOG-ROTATION ==="
    
    # Verschiebe alte Logs (>7 Tage) ins Archiv
    find "$SCRIPT_DIR/logs" -name "*.log" -type f -mtime +7 2>/dev/null | while read logfile; do
        ARCHIVE_DIR="$SCRIPT_DIR/logs/archive/$(date +%Y-%m)"
        mkdir -p "$ARCHIVE_DIR"
        mv "$logfile" "$ARCHIVE_DIR/" 2>/dev/null && \
            log "  → Archiviert: $logfile" || true
    done
    
    log "✅ Log-Rotation abgeschlossen"
}

# Wöchentliches Storage Cleanup
weekly_cleanup() {
    log "=== WÖCHENTLICHES STORAGE CLEANUP ==="
    
    if [ -f "$CLEANUP_SCRIPT" ]; then
        bash "$CLEANUP_SCRIPT" >> "$LOG_FILE" 2>&1
        log "✅ Storage Cleanup abgeschlossen"
    else
        log "❌ Cleanup-Script nicht gefunden: $CLEANUP_SCRIPT"
    fi
}

# Monatliches NAS Temp Cleanup
monthly_nas_cleanup() {
    log "=== MONATLICHES NAS TEMP CLEANUP ==="
    
    NAS_MOUNT="$HOME/fritz-nas-archive"
    NAS_ARCHIVE="$NAS_MOUNT/hifiberry-project-archive/temp/big-data-dumps"
    
    if mount | grep -q "$NAS_MOUNT"; then
        # Lösche Dateien älter als 2 Wochen
        DEL_COUNT=$(find "$NAS_ARCHIVE" -type f -mtime +14 2>/dev/null | wc -l | tr -d ' ')
        find "$NAS_ARCHIVE" -type f -mtime +14 -delete 2>/dev/null
        log "✅ $DEL_COUNT Temp-Dateien gelöscht (älter als 2 Wochen)"
    else
        log "⚠️  NAS nicht gemountet"
    fi
}

# Hauptfunktion
main() {
    log "╔══════════════════════════════════════════════════════════════╗"
    log "║  📅 AUTOMATED CLEANUP SCHEDULE                              ║"
    log "╚══════════════════════════════════════════════════════════════╝"
    log ""
    
    # Täglich
    daily_log_rotation
    
    # Wöchentlich (jeden Sonntag)
    if [ "$(date +%u)" = "7" ]; then
        weekly_cleanup
    fi
    
    # Monatlich (am 1. des Monats)
    if [ "$(date +%d)" = "01" ]; then
        monthly_nas_cleanup
    fi
    
    log ""
    log "=== SCHEDULE ABGESCHLOSSEN ==="
}

main "$@"

