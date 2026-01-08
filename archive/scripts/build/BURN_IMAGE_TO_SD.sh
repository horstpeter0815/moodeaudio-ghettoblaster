#!/bin/bash
################################################################################
#
# BURN_IMAGE_TO_SD.sh
#
# Brennt das neueste Image auf die SD-Karte
#
################################################################################

set -e

# Absoluter Pfad zum Projektverzeichnis
PROJECT_DIR="/Users/andrevollmer/Library/Mobile Documents/com~apple~CloudDocs/Ablage/Roon filters/Bose Wave/OS/RPi4/moodeaudio/cursor"

# Falls Script im Projektverzeichnis liegt, verwende das
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -d "$SCRIPT_DIR/imgbuild" ]; then
    PROJECT_DIR="$SCRIPT_DIR"
fi

cd "$PROJECT_DIR"

echo "═══════════════════════════════════════"
echo "  🔥 IMAGE AUF SD-KARTE BRENNEN"
echo "═══════════════════════════════════════"
echo ""
echo "Projekt-Verzeichnis: $PROJECT_DIR"
echo ""

# Finde SD-Karte
echo "1. Suche SD-Karte..."
SD_DISK=""
for disk in $(diskutil list | grep -E "^/dev/disk[0-9]+" | awk '{print $1}'); do
    if diskutil info "$disk" 2>/dev/null | grep -q "Removable Media.*Removable"; then
        SIZE=$(diskutil info "$disk" 2>/dev/null | grep "Disk Size" | awk '{print $3, $4}')
        if [ -n "$SIZE" ]; then
            SD_DISK="$disk"
            echo "   ✅ SD-Karte gefunden: $SD_DISK ($SIZE)"
            break
        fi
    fi
done

if [ -z "$SD_DISK" ]; then
    echo "   ❌ Keine SD-Karte gefunden!"
    echo "   💡 Bitte SD-Karte einstecken und erneut versuchen."
    exit 1
fi

# Finde neuestes Image
echo ""
echo "2. Suche neuestes Image..."
IMAGE_DIR="$PROJECT_DIR/imgbuild/deploy"
if [ ! -d "$IMAGE_DIR" ]; then
    echo "   ❌ Deploy-Verzeichnis nicht gefunden: $IMAGE_DIR"
    echo "   Projekt-Verzeichnis: $PROJECT_DIR"
    exit 1
fi

NEWEST_IMAGE=$(ls -t "$IMAGE_DIR"/*.img 2>/dev/null | head -n 1)
if [ -z "$NEWEST_IMAGE" ]; then
    echo "   ❌ Kein Image gefunden in $IMAGE_DIR"
    exit 1
fi

IMAGE_SIZE=$(du -h "$NEWEST_IMAGE" | cut -f1)
echo "   ✅ Image gefunden: $(basename "$NEWEST_IMAGE")"
echo "   Größe: $IMAGE_SIZE"

# Warnung
echo ""
echo "⚠️  WICHTIG:"
echo "   - Dies überschreibt die SD-Karte komplett!"
echo "   - Alle Daten auf der SD-Karte werden gelöscht!"
echo "   - SD-Karte: $SD_DISK"
echo "   - Image: $NEWEST_IMAGE"
echo ""
echo "   ✅ Automatisch fortfahren..."
# Automatisch fortfahren - Benutzer hat bereits bestätigt

# Unmounte SD-Karte
echo ""
echo "3. Unmounte SD-Karte..."
if diskutil unmountDisk "$SD_DISK" 2>&1; then
    echo "   ✅ SD-Karte unmounted"
else
    echo "   ⚠️  Konnte nicht unmounten (möglicherweise bereits unmounted)"
fi

# Warte kurz
sleep 2

# Brenne Image
echo ""
echo "4. Brenne Image auf SD-Karte..."
echo "   (Dies kann 5-10 Minuten dauern...)"
echo ""

# Verwende rdisk für schnellere Schreibgeschwindigkeit
SD_RDISK="${SD_DISK/disk/rdisk}"

if [ ! -e "$SD_RDISK" ]; then
    echo "   ⚠️  rdisk nicht verfügbar, verwende disk"
    SD_RDISK="$SD_DISK"
fi

sudo dd if="$NEWEST_IMAGE" of="$SD_RDISK" bs=1m status=progress

# Sync
echo ""
echo "5. Synchronisiere..."
sync

# Prüfe Ergebnis
echo ""
echo "6. Prüfe Ergebnis..."
if diskutil list "$SD_DISK" | grep -q "FAT32\|Linux"; then
    echo "   ✅ Image erfolgreich gebrannt!"
    echo ""
    echo "   Partitionen:"
    diskutil list "$SD_DISK" | grep -E "FAT32|Linux" | head -5
else
    echo "   ⚠️  Unerwartetes Ergebnis - bitte prüfen"
fi

echo ""
echo "═══════════════════════════════════════"
echo "  ✅ FERTIG!"
echo "═══════════════════════════════════════"
echo ""
echo "SD-Karte ist bereit für den Pi!"
echo "   - SD-Karte in Pi einstecken"
echo "   - Pi booten lassen"
echo "   - Serial Console überwachen"
echo ""

