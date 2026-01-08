#!/bin/bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  🔥 IMAGE AUF SD-KARTE BRENNEN                              ║
# ╚══════════════════════════════════════════════════════════════╝

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

IMAGE_FILE="/Users/andrevollmer/Library/Mobile Documents/com~apple~CloudDocs/Ablage/Roon filters/Bose Wave/OS/RPi4/moodeaudio/cursor/imgbuild/deploy/2025-12-07-moode-r1001-arm64-lite.img"
SD_DISK="/dev/disk4"
SD_DISK_RAW="/dev/rdisk4"

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  🔥 IMAGE AUF SD-KARTE BRENNEN                              ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Prüfe Image
if [ ! -f "$IMAGE_FILE" ]; then
    echo "❌ ERROR: Image nicht gefunden: $IMAGE_FILE"
    exit 1
fi

IMAGE_SIZE=$(ls -lh "$IMAGE_FILE" | awk '{print $5}')
echo "✅ Image gefunden: $IMAGE_FILE ($IMAGE_SIZE)"
echo ""

# Prüfe SD-Karte
if [ ! -e "$SD_DISK" ]; then
    echo "❌ ERROR: SD-Karte nicht gefunden: $SD_DISK"
    echo "Bitte SD-Karte einstecken und erneut versuchen."
    exit 1
fi

SD_SIZE=$(diskutil info $SD_DISK 2>/dev/null | grep "Disk Size" | awk '{print $3, $4}')
echo "✅ SD-Karte gefunden: $SD_DISK ($SD_SIZE)"
echo ""

# Sicherheitsabfrage
echo "⚠️  WICHTIG:"
echo "   - Alle Daten auf $SD_DISK werden gelöscht!"
echo "   - Dieser Vorgang kann 5-10 Minuten dauern!"
echo ""
read -p "Fortfahren? (ja/nein): " CONFIRM

if [ "$CONFIRM" != "ja" ]; then
    echo "❌ Abgebrochen."
    exit 1
fi

# Unmount
echo ""
echo "📤 Unmounte SD-Karte..."
diskutil unmountDisk $SD_DISK 2>/dev/null || true
sleep 2

# Brenne Image
echo ""
echo "🔥 Brenne Image auf $SD_DISK_RAW..."
echo "   (Dies kann 5-10 Minuten dauern - bitte nicht unterbrechen!)"
echo ""

sudo dd if="$IMAGE_FILE" of="$SD_DISK_RAW" bs=1m status=progress

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Image erfolgreich gebrannt!"
    sync
    echo ""
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║  ✅ ERFOLGREICH ABGESCHLOSSEN                               ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo ""
    echo "📋 NÄCHSTE SCHRITTE:"
    echo "   1. SD-Karte aus Mac entfernen"
    echo "   2. SD-Karte in Raspberry Pi einstecken"
    echo "   3. Pi einschalten"
    echo "   4. Warte 1-2 Minuten bis Pi gebootet ist"
    echo "   5. Öffne Web-UI: http://192.168.178.161"
    echo ""
else
    echo ""
    echo "❌ ERROR: Image-Brennen fehlgeschlagen!"
    exit 1
fi

