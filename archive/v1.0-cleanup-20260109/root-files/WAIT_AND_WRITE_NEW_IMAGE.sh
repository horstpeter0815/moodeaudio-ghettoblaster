#!/bin/bash
################################################################################
#
# Wait for New Build and Write to SD Card
# Wartet auf neues Image und schreibt es automatisch auf SD-Karte
#
################################################################################

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  ⏳ WARTE AUF NEUES IMAGE & SCHREIBE AUF SD-KARTE           ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Finde neuestes existierendes Image (als Referenz)
LATEST_IMAGE=$(ls -t imgbuild/deploy/moode-r1001-arm64-*.img 2>/dev/null | head -1)
if [ -n "$LATEST_IMAGE" ]; then
    LATEST_TIMESTAMP=$(basename "$LATEST_IMAGE" | grep -oE '[0-9]{8}_[0-9]{6}' | head -1)
    echo "📦 Aktuelles Image: $(basename "$LATEST_IMAGE")"
    echo "   Timestamp: $LATEST_TIMESTAMP"
    echo ""
    echo "⏳ Warte auf neues Image (neuerer Timestamp)..."
    echo ""
else
    echo "⚠️  Kein existierendes Image gefunden"
    echo "⏳ Warte auf erstes Image..."
    echo ""
    LATEST_TIMESTAMP=""
fi

# Finde SD-Karte
SD_LINE=$(diskutil list | grep -E 'external.*physical' | head -1)
if [ -z "$SD_LINE" ]; then
    echo "❌ Keine SD-Karte gefunden!"
    echo "   Bitte SD-Karte einstecken."
    echo "   Script wird weiterlaufen und warten..."
    echo ""
    SD_DEVICE=""
else
    SD_DEVICE=$(echo "$SD_LINE" | awk '{print $1}' | sed 's|/dev/||')
    echo "✅ SD-Karte gefunden: /dev/$SD_DEVICE"
    echo ""
fi

# Prüfe ob Build läuft
BUILD_RUNNING=true
if ! docker ps | grep -q moode-builder; then
    echo "⚠️  Docker Container läuft nicht - Build möglicherweise abgeschlossen"
    BUILD_RUNNING=false
fi

# Warte auf neues Image
CHECK_COUNT=0
MAX_CHECKS=1440  # 24 Stunden (alle 60 Sekunden)

while [ $CHECK_COUNT -lt $MAX_CHECKS ]; do
    CHECK_COUNT=$((CHECK_COUNT + 1))
    
    # Prüfe ob neues Image vorhanden
    NEW_IMAGE=$(ls -t imgbuild/deploy/moode-r1001-arm64-*.img 2>/dev/null | head -1)
    
    if [ -n "$NEW_IMAGE" ]; then
        NEW_TIMESTAMP=$(basename "$NEW_IMAGE" | grep -oE '[0-9]{8}_[0-9]{6}' | head -1)
        
        # Prüfe ob Image neu ist (neuerer Timestamp)
        if [ -z "$LATEST_TIMESTAMP" ] || [ "$NEW_TIMESTAMP" \> "$LATEST_TIMESTAMP" ]; then
            echo "✅ NEUES IMAGE GEFUNDEN!"
            echo "   $(basename "$NEW_IMAGE")"
            echo "   Größe: $(ls -lh "$NEW_IMAGE" | awk '{print $5}')"
            echo ""
            
            # Prüfe ob Image vollständig ist (nicht gerade geschrieben)
            sleep 5
            if [ -f "$NEW_IMAGE" ]; then
                echo "📋 Image ist vollständig"
                echo ""
                
                # Prüfe SD-Karte nochmal
                if [ -z "$SD_DEVICE" ]; then
                    SD_LINE=$(diskutil list | grep -E 'external.*physical' | head -1)
                    if [ -n "$SD_LINE" ]; then
                        SD_DEVICE=$(echo "$SD_LINE" | awk '{print $1}' | sed 's|/dev/||')
                        echo "✅ SD-Karte jetzt gefunden: /dev/$SD_DEVICE"
                        echo ""
                    else
                        echo "❌ SD-Karte immer noch nicht gefunden!"
                        echo "   Bitte SD-Karte einstecken und Script erneut ausführen"
                        exit 1
                    fi
                fi
                
                # Schreibe Image auf SD-Karte
                echo "╔══════════════════════════════════════════════════════════════╗"
                echo "║  💾 SCHREIBE IMAGE AUF SD-KARTE                              ║"
                echo "╚══════════════════════════════════════════════════════════════╝"
                echo ""
                
                # Verwende WRITE_IMAGE_TO_SD.sh wenn vorhanden (hat bereits sudo-Logik)
                if [ -f "$SCRIPT_DIR/WRITE_IMAGE_TO_SD.sh" ]; then
                    echo "📋 Verwende WRITE_IMAGE_TO_SD.sh..."
                    sudo "$SCRIPT_DIR/WRITE_IMAGE_TO_SD.sh"
                else
                    # Fallback: Direktes Schreiben
                    if [ "$EUID" -ne 0 ]; then
                        echo "⚠️  Benötige sudo-Rechte zum Schreiben..."
                        echo "   Führe aus: sudo $0"
                        exit 1
                    fi
                    
                    # Unmount SD-Karte
                    echo "📋 Unmounte SD-Karte..."
                    diskutil unmountDisk /dev/$SD_DEVICE 2>/dev/null || true
                    sleep 2
                    
                    # Schreibe Image
                    echo "💾 Schreibe Image auf /dev/r$SD_DEVICE..."
                    echo "   Dies kann 5-10 Minuten dauern..."
                    echo ""
                    
                    dd if="$NEW_IMAGE" of=/dev/r$SD_DEVICE bs=1m status=progress
                fi
                
                if [ $? -eq 0 ]; then
                    echo ""
                    echo "✅ IMAGE ERFOLGREICH GESCHRIEBEN!"
                    echo ""
                    echo "📋 Nächste Schritte:"
                    echo "   1. SD-Karte auswerfen: diskutil eject /dev/$SD_DEVICE"
                    echo "   2. SD-Karte in Raspberry Pi einstecken"
                    echo "   3. Pi booten"
                    echo "   4. SSH-Zugriff prüfen: ssh andre@192.168.10.2"
                    echo ""
                    exit 0
                else
                    echo ""
                    echo "❌ FEHLER beim Schreiben!"
                    exit 1
                fi
            fi
        fi
    fi
    
    # Zeige Fortschritt alle 5 Minuten
    if [ $((CHECK_COUNT % 5)) -eq 0 ]; then
        MINUTES=$((CHECK_COUNT))
        echo "[$MINUTES min] Warte auf neues Image... (Build läuft)"
        
        # Prüfe Build-Status
        if docker exec moode-builder bash -c "ps aux | grep build.sh | grep -v grep" >/dev/null 2>&1; then
            echo "   ✅ Build läuft noch"
        else
            echo "   ⚠️  Build-Prozess nicht gefunden - möglicherweise abgeschlossen"
        fi
    fi
    
    # Warte 60 Sekunden
    sleep 60
done

echo ""
echo "❌ Timeout erreicht (24 Stunden)"
echo "   Build hat zu lange gedauert"
exit 1

