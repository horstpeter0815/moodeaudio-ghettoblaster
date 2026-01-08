#!/bin/bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  🤖 AUTOMATISCHER BUILD-MONITOR                               ║
# ╚══════════════════════════════════════════════════════════════╝
# Prüft Build-Status und kopiert Image automatisch wenn fertig

cd "/Users/andrevollmer/Library/Mobile Documents/com~apple~CloudDocs/Ablage/Roon filters/Bose Wave/OS/RPi4/moodeaudio/cursor"

LOG_FILE="build-monitor-$(date +%Y%m%d_%H%M%S).log"

log() {
    echo "[$(date +%Y-%m-%d %H:%M:%S)] $1" | tee -a "$LOG_FILE"
}

log "🤖 Build-Monitor gestartet"

# Prüfe ob Build-Prozess läuft
check_build_running() {
    if ps aux | grep "START_BUILD_WHEN_READY.sh" | grep -v grep >/dev/null; then
        return 0
    fi
    if docker exec moode-builder ps aux 2>/dev/null | grep -q "build.sh"; then
        return 0
    fi
    return 1
}

# Prüfe ob Image fertig ist
check_image_ready() {
    # Im Container prüfen
    if docker exec moode-builder test -f /workspace/imgbuild/pi-gen-64/deploy/*.img 2>/dev/null; then
        IMAGE_NAME=$(docker exec moode-builder ls -1t /workspace/imgbuild/pi-gen-64/deploy/*.img 2>/dev/null | head -1 | xargs basename 2>/dev/null)
        if [ -n "$IMAGE_NAME" ]; then
            echo "$IMAGE_NAME"
            return 0
        fi
    fi
    
    # Lokal prüfen
    if ls imgbuild/pi-gen-64/deploy/*.img 2>/dev/null | head -1; then
        return 0
    fi
    
    return 1
}

# Kopiere Image aus Container
copy_image_from_container() {
    log "📦 Kopiere Image aus Container..."
    
    CONTAINER_IMAGE=$(docker exec moode-builder ls -1t /workspace/imgbuild/pi-gen-64/deploy/*.img 2>/dev/null | head -1)
    
    if [ -z "$CONTAINER_IMAGE" ]; then
        log "❌ Kein Image im Container gefunden"
        return 1
    fi
    
    IMAGE_NAME=$(basename "$CONTAINER_IMAGE")
    LOCAL_PATH="imgbuild/pi-gen-64/deploy/$IMAGE_NAME"
    
    # Erstelle Verzeichnis falls nicht vorhanden
    mkdir -p imgbuild/pi-gen-64/deploy/
    
    log "Kopiere: $CONTAINER_IMAGE -> $LOCAL_PATH"
    docker cp "moode-builder:$CONTAINER_IMAGE" "$LOCAL_PATH"
    
    if [ -f "$LOCAL_PATH" ]; then
        log "✅ Image kopiert: $LOCAL_PATH"
        ls -lh "$LOCAL_PATH"
        return 0
    else
        log "❌ Image-Kopie fehlgeschlagen"
        return 1
    fi
}

# Erstelle Burn-Script
create_burn_script() {
    IMAGE_FILE=$(ls -1t imgbuild/pi-gen-64/deploy/*.img 2>/dev/null | head -1)
    
    if [ -z "$IMAGE_FILE" ]; then
        log "⚠️  Kein Image für Burn-Script gefunden"
        return 1
    fi
    
    FULL_IMAGE_PATH=$(cd "$(dirname "$IMAGE_FILE")" && pwd)/$(basename "$IMAGE_FILE")
    
    log "📝 Erstelle Burn-Script für: $FULL_IMAGE_PATH"
    
    cat > BURN_IMAGE_NOW.sh << 'BURNSCRIPT'
#!/bin/bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  💾 SD-KARTE BRENNEN - MOODE IMAGE                           ║
# ╚══════════════════════════════════════════════════════════════╝

cd "/Users/andrevollmer/Library/Mobile Documents/com~apple~CloudDocs/Ablage/Roon filters/Bose Wave/OS/RPi4/moodeaudio/cursor"

IMAGE_FILE="FULL_IMAGE_PATH_PLACEHOLDER"

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  💾 SD-KARTE BRENNEN                                         ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Prüfe ob Image existiert
if [ ! -f "$IMAGE_FILE" ]; then
    echo "❌ Image nicht gefunden: $IMAGE_FILE"
    exit 1
fi

echo "📦 Image: $IMAGE_FILE"
echo "📊 Größe: $(ls -lh "$IMAGE_FILE" | awk '{print $5}')"
echo ""

# Finde SD-Karte
echo "🔍 Suche SD-Karte..."
DISKS=$(diskutil list | grep -E "^/dev/disk" | grep -v "disk0" | awk '{print $1}')

if [ -z "$DISKS" ]; then
    echo "❌ Keine SD-Karte gefunden!"
    echo "   Bitte SD-Karte einstecken und Script erneut ausführen"
    exit 1
fi

echo "Gefundene Laufwerke:"
for disk in $DISKS; do
    SIZE=$(diskutil info "$disk" 2>/dev/null | grep "Disk Size" | awk '{print $3, $4}')
    echo "   $disk - $SIZE"
done

echo ""
read -p "SD-Karte auswählen (z.B. /dev/disk4): " SELECTED_DISK

if [ -z "$SELECTED_DISK" ]; then
    echo "❌ Keine Auswahl getroffen"
    exit 1
fi

# Prüfe ob Disk existiert
if ! diskutil list "$SELECTED_DISK" >/dev/null 2>&1; then
    echo "❌ Disk nicht gefunden: $SELECTED_DISK"
    exit 1
fi

echo ""
echo "⚠️  WARNUNG: Alle Daten auf $SELECTED_DISK werden gelöscht!"
read -p "Fortfahren? (ja/nein): " CONFIRM

if [ "$CONFIRM" != "ja" ]; then
    echo "❌ Abgebrochen"
    exit 1
fi

echo ""
echo "🔄 Unmounte Disk..."
diskutil unmountDisk "$SELECTED_DISK"

echo "🔥 Brenne Image auf SD-Karte..."
echo "   Das kann einige Minuten dauern..."
echo ""

sudo dd if="$IMAGE_FILE" of="$SELECTED_DISK" bs=1m status=progress

if [ $? -eq 0 ]; then
    echo ""
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║  ✅ IMAGE ERFOLGREICH GEBRANNT!                               ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo ""
    echo "📋 Nächste Schritte:"
    echo "   1. SD-Karte auswerfen: diskutil eject $SELECTED_DISK"
    echo "   2. SD-Karte in Pi einstecken"
    echo "   3. Pi booten"
    echo "   4. Web-UI öffnen: http://192.168.178.161"
    echo ""
else
    echo ""
    echo "❌ Fehler beim Brennen!"
    exit 1
fi
BURNSCRIPT

    # Ersetze Platzhalter
    sed -i '' "s|FULL_IMAGE_PATH_PLACEHOLDER|$FULL_IMAGE_PATH|g" BURN_IMAGE_NOW.sh
    chmod +x BURN_IMAGE_NOW.sh
    
    log "✅ Burn-Script erstellt: BURN_IMAGE_NOW.sh"
}

# Haupt-Loop
MAX_CHECKS=360  # 6 Stunden (alle 60 Sekunden)
CHECK_COUNT=0
BUILD_COMPLETE=false

log "⏳ Warte auf Build-Abschluss..."

while [ $CHECK_COUNT -lt $MAX_CHECKS ]; do
    sleep 60  # Alle 60 Sekunden prüfen
    
    CHECK_COUNT=$((CHECK_COUNT + 1))
    
    if [ $((CHECK_COUNT % 10)) -eq 0 ]; then
        log "⏳ Prüfe Build-Status... (Check $CHECK_COUNT/$MAX_CHECKS)"
    fi
    
    # Prüfe ob Build noch läuft
    if ! check_build_running; then
        log "✅ Build-Prozess beendet"
        
        # Warte kurz und prüfe dann Image
        sleep 10
        
        if IMAGE_NAME=$(check_image_ready); then
            log "✅ Image gefunden: $IMAGE_NAME"
            BUILD_COMPLETE=true
            break
        else
            log "⚠️  Build beendet, aber kein Image gefunden"
            log "Prüfe Log-Dateien für Details..."
            break
        fi
    fi
done

if [ "$BUILD_COMPLETE" = true ]; then
    log "🎉 Build erfolgreich abgeschlossen!"
    
    # Kopiere Image falls nötig
    if [ ! -f imgbuild/pi-gen-64/deploy/*.img ]; then
        copy_image_from_container
    fi
    
    # Erstelle Burn-Script
    create_burn_script
    
    log ""
    log "╔══════════════════════════════════════════════════════════════╗"
    log "║  ✅ ALLES FERTIG!                                             ║"
    log "╚══════════════════════════════════════════════════════════════╝"
    log ""
    log "📋 Nächste Schritte:"
    log "   1. SD-Karte einstecken"
    log "   2. ./BURN_IMAGE_NOW.sh ausführen"
    log "   3. Pi booten und testen"
    log ""
else
    log "⚠️  Build-Status unklar - bitte manuell prüfen"
    log "   ./CHECK_BUILD_STATUS.sh ausführen"
fi

