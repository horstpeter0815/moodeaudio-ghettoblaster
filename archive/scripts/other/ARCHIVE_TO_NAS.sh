#!/bin/bash
################################################################################
#
# ARCHIVE TO FRITZ NAS
# 
# Verschiebt alte/archivierte Dateien zum Fritz NAS
# (Langsam, daher nur für Archive, nicht für aktive Arbeit)
#
################################################################################

set -e

# NAS Konfiguration
NAS_HOST="${NAS_HOST:-fritz.box}"
NAS_SHARE="${NAS_SHARE:-archive}"
NAS_USER="${NAS_USER:-admin}"
NAS_PASS="${NAS_PASS:-}"
MOUNT_POINT="$HOME/fritz-nas-archive"

PROJECT_DIR="/Users/andrevollmer/Library/Mobile Documents/com~apple~CloudDocs/Ablage/Roon filters/Bose Wave/OS/RPi4/moodeaudio/cursor"
ARCHIVE_DIR="$MOUNT_POINT/hifiberry-project-archive"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

log "=== ARCHIVE TO FRITZ NAS ==="

################################################################################
# 1. NAS mounten
################################################################################

log "Mounting Fritz NAS..."

# Prüfe ob bereits gemountet
if mount | grep -q "$MOUNT_POINT"; then
    log "✅ NAS bereits gemountet"
else
    # Erstelle Mount-Point
    mkdir -p "$MOUNT_POINT"
    
    # Versuche zu mounten
    if [ -z "$NAS_PASS" ]; then
        log "⚠️  NAS_PASS nicht gesetzt, versuche ohne Passwort..."
        mount_smbfs "//guest@$NAS_HOST/$NAS_SHARE" "$MOUNT_POINT" 2>/dev/null || {
            log "❌ Mount fehlgeschlagen"
            log "Bitte manuell mounten oder NAS_PASS setzen"
            exit 1
        }
    else
        mount_smbfs "//$NAS_USER:$NAS_PASS@$NAS_HOST/$NAS_SHARE" "$MOUNT_POINT" || {
            log "❌ Mount fehlgeschlagen"
            exit 1
        }
    fi
    
    log "✅ NAS gemountet"
fi

################################################################################
# 2. Archiv-Verzeichnis erstellen
################################################################################

log "Creating archive directory..."
mkdir -p "$ARCHIVE_DIR"
log "✅ Archive directory ready"

################################################################################
# 3. Was soll archiviert werden?
################################################################################

log ""
log "=== ARCHIVIERUNGS-OPTIONEN ==="
log ""
log "1. Alte Build-Logs und temporäre Dateien"
log "2. Alte Kernel-Builds (falls vorhanden)"
log "3. Alte Dokumentation/Backups"
log "4. Komplettes Projekt-Backup"
log ""

# Standard: Alte Logs und temporäre Dateien
ARCHIVE_ITEMS=(
    "$PROJECT_DIR/*.log"
    "$PROJECT_DIR/imgbuild/deploy/*.log"
    "$PROJECT_DIR/complete-sim-logs"
    "$PROJECT_DIR/system-sim-test"
)

################################################################################
# 4. Archivierung durchführen
################################################################################

log "Starting archive process..."
TOTAL_SIZE=0

for item in "${ARCHIVE_ITEMS[@]}"; do
    if [ -e "$item" ]; then
        SIZE=$(du -sk "$item" 2>/dev/null | awk '{print $1}')
        TOTAL_SIZE=$((TOTAL_SIZE + SIZE))
        
        log "Archiving: $item ($(du -sh "$item" 2>/dev/null | awk '{print $1}'))"
        
        # Kopiere mit rsync (besser für Netzwerk)
        rsync -av --progress "$item" "$ARCHIVE_DIR/" 2>&1 | tail -3
        
        log "✅ Archived: $item"
    fi
done

log ""
log "=== ARCHIVE COMPLETE ==="
log "Total archived: $(du -sh "$ARCHIVE_DIR" 2>/dev/null | awk '{print $1}')"
log ""
log "Archive location: $ARCHIVE_DIR"
log ""
log "⚠️  WICHTIG: NAS ist langsam - nur für Archive nutzen!"
log "   Für aktive Arbeit weiterhin lokalen Speicher verwenden."

################################################################################
# 5. Optional: Alte lokale Dateien löschen nach Archivierung
################################################################################

read -p "Alte Dateien nach Archivierung löschen? (j/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Jj]$ ]]; then
    log "Lösche archivierte Dateien lokal..."
    for item in "${ARCHIVE_ITEMS[@]}"; do
        if [ -e "$item" ]; then
            rm -rf "$item"
            log "✅ Gelöscht: $item"
        fi
    done
    
    log ""
    log "=== SPEICHERPLATZ NACH BEREINIGUNG ==="
    df -h /System/Volumes/Data | tail -1
fi

log ""
log "=== DONE ==="

