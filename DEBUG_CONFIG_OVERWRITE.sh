#!/bin/bash
################################################################################
# DEBUG: Runtime-Logging für config.txt Überschreibungsproblem
#
# Instrumentiert worker.php und chkBootConfigTxt() um zu sehen:
# 1. Wann wird chkBootConfigTxt() aufgerufen?
# 2. Was wird geprüft?
# 3. Warum wird überschrieben?
# 4. Was ist der genaue Status?
#
################################################################################

set -e

LOG_FILE="/Users/andrevollmer/moodeaudio-cursor/.cursor/debug.log"

# Clear previous log
rm -f "$LOG_FILE" 2>/dev/null || true

echo "=== DEBUG: Runtime-Logging Setup ==="
echo ""
echo "Log-Datei: $LOG_FILE"
echo ""

# Check if SD card is mounted
SD_MOUNT=""
if [ -d "/Volumes/bootfs" ]; then
    SD_MOUNT="/Volumes/bootfs"
elif [ -d "/Volumes/boot" ]; then
    SD_MOUNT="/Volumes/boot"
fi

if [ -z "$SD_MOUNT" ]; then
    echo "❌ SD-Karte nicht gefunden"
    echo "Bitte SD-Karte einstecken und Script erneut ausführen"
    exit 1
fi

echo "SD-Karte: $SD_MOUNT"
echo ""

# Create debug script that will be executed on Pi
cat > "$SD_MOUNT/debug-config-overwrite.sh" << 'DEBUG_EOF'
#!/bin/bash
################################################################################
# DEBUG SCRIPT - Wird auf dem Pi ausgeführt
################################################################################

LOG_FILE="/tmp/config-debug.log"
BOOT_CONFIG="/boot/firmware/config.txt"

# Clear log
rm -f "$LOG_FILE" 2>/dev/null || true

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log "=== DEBUG SCRIPT START ==="
log ""

# Check current config.txt
log "=== CURRENT config.txt ANALYSIS ==="
if [ -f "$BOOT_CONFIG" ]; then
    log "config.txt exists: YES"
    log "config.txt size: $(stat -c%s "$BOOT_CONFIG" 2>/dev/null || stat -f%z "$BOOT_CONFIG" 2>/dev/null || echo 'unknown')"
    log ""
    log "Zeile 1: '$(head -1 "$BOOT_CONFIG")'"
    log "Zeile 2: '$(sed -n '2p' "$BOOT_CONFIG")'"
    log ""
    
    # Check Main Header
    if head -1 "$BOOT_CONFIG" | grep -q "This file is managed by moOde"; then
        log "Main Header in Zeile 1: YES"
    elif sed -n '2p' "$BOOT_CONFIG" | grep -q "This file is managed by moOde"; then
        log "Main Header in Zeile 2: YES"
    else
        log "Main Header: NOT FOUND"
    fi
    
    # Count headers
    HEADER_COUNT=0
    grep -q "^# This file is managed by moOde" "$BOOT_CONFIG" && HEADER_COUNT=$((HEADER_COUNT+1))
    grep -q "^# Device filters" "$BOOT_CONFIG" && HEADER_COUNT=$((HEADER_COUNT+1))
    grep -q "^# General settings" "$BOOT_CONFIG" && HEADER_COUNT=$((HEADER_COUNT+1))
    grep -q "^# Do not alter this section" "$BOOT_CONFIG" && HEADER_COUNT=$((HEADER_COUNT+1))
    grep -q "^# Audio overlays" "$BOOT_CONFIG" && HEADER_COUNT=$((HEADER_COUNT+1))
    
    log "Header Count: $HEADER_COUNT/5"
    log ""
else
    log "config.txt exists: NO"
fi

# Check if worker.php exists
if [ -f "/var/www/daemon/worker.php" ]; then
    log "worker.php exists: YES"
    
    # Check if chkBootConfigTxt is called
    if grep -q "chkBootConfigTxt" "/var/www/daemon/worker.php"; then
        log "chkBootConfigTxt() call found in worker.php: YES"
        
        # Find line number
        LINE=$(grep -n "chkBootConfigTxt" "/var/www/daemon/worker.php" | head -1 | cut -d: -f1)
        log "chkBootConfigTxt() called at line: $LINE"
    else
        log "chkBootConfigTxt() call found: NO"
    fi
else
    log "worker.php exists: NO"
fi

# Check if common.php exists
if [ -f "/var/www/inc/common.php" ]; then
    log "common.php exists: YES"
    
    # Check chkBootConfigTxt function
    if grep -q "function chkBootConfigTxt" "/var/www/inc/common.php"; then
        log "chkBootConfigTxt() function found: YES"
        
        # Check what it checks
        if grep -q '\$lines\[1\]' "/var/www/inc/common.php"; then
            log "chkBootConfigTxt() checks \$lines[1] (Zeile 2): YES"
        fi
        
        # Check header constants
        if grep -q "CFG_MAIN_FILE_HEADER" "/var/www/inc/common.php"; then
            log "CFG_MAIN_FILE_HEADER constant used: YES"
        fi
    else
        log "chkBootConfigTxt() function found: NO"
    fi
else
    log "common.php exists: NO"
fi

log ""
log "=== DEBUG SCRIPT END ==="
log ""
log "Log saved to: $LOG_FILE"
log "To view: cat $LOG_FILE"

DEBUG_EOF

chmod +x "$SD_MOUNT/debug-config-overwrite.sh"

echo "✅ Debug-Script erstellt: $SD_MOUNT/debug-config-overwrite.sh"
echo ""
echo "Nächste Schritte:"
echo "  1. SD-Karte sicher auswerfen"
echo "  2. SD-Karte in Pi einstecken"
echo "  3. Pi booten"
echo "  4. Nach Boot: SSH zum Pi verbinden"
echo "  5. Ausführen: sudo /boot/firmware/debug-config-overwrite.sh"
echo "  6. Log anzeigen: cat /tmp/config-debug.log"
echo ""

