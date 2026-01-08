#!/bin/bash
################################################################################
# Brenne Image direkt auf SD-Karte am Mac
################################################################################

IMAGE_FILE="2025-12-07-moode-r1001-arm64-lite.img"

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  🔥 IMAGE AUF SD-KARTE BRENNEN (MAC)                          ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Prüfe Image
if [ ! -f "$IMAGE_FILE" ]; then
    echo "❌ Image nicht gefunden: $IMAGE_FILE"
    exit 1
fi

echo "📋 Verfügbare Geräte:"
diskutil list | grep -E "^/dev/disk" | awk '{print "   " $0}'
echo ""

echo "🔍 Suche SD-Karte..."
SD_DISKS=$(diskutil list | grep -E "^/dev/disk" | awk '{print $1}' | grep -v "disk0")

if [ -z "$SD_DISKS" ]; then
    echo "❌ Keine SD-Karte gefunden!"
    echo "   Bitte SD-Karte einstecken und erneut versuchen"
    exit 1
fi

echo "✅ Gefundene Geräte:"
for disk in $SD_DISKS; do
    SIZE=$(diskutil info $disk 2>/dev/null | grep "Disk Size" | awk '{print $3, $4}')
    echo "   $disk - $SIZE"
done
echo ""

read -p "📝 SD-Karte auswählen (z.B. disk2): " SD_DISK

if [ -z "$SD_DISK" ]; then
    echo "❌ Keine Disk angegeben"
    exit 1
fi

# Prüfe ob Disk existiert
if ! diskutil list "$SD_DISK" >/dev/null 2>&1; then
    echo "❌ Disk nicht gefunden: $SD_DISK"
    exit 1
fi

echo ""
echo "⚠️  WICHTIG: Alle Daten auf $SD_DISK werden gelöscht!"
read -p "   Wirklich fortfahren? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "   Abgebrochen"
    exit 0
fi

echo ""
echo "📤 Unmounte Disk..."
diskutil unmountDisk "$SD_DISK" || {
    echo "⚠️  Unmount fehlgeschlagen - versuche trotzdem weiter..."
}

echo ""
echo "🔥 Brenne Image (dauert ~5-10 Minuten)..."
echo "   Image: $IMAGE_FILE"
echo "   Target: /dev/r${SD_DISK#/dev/}"
echo ""

sudo dd if="$IMAGE_FILE" of="/dev/r${SD_DISK#/dev/}" bs=4m status=progress

if [ $? -eq 0 ]; then
    echo ""
    echo "🔄 Sync..."
    sync
    
    echo ""
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║  ✅ IMAGE ERFOLGREICH GEBRANNT!                               ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo ""
    echo "📋 NÄCHSTE SCHRITTE:"
    echo "1. SD-Karte sicher auswerfen"
    echo "2. SD-Karte in Raspberry Pi 5 stecken"
    echo "3. Hardware verbinden (AMP100, Display, Touchscreen)"
    echo "4. System booten (~1-2 Minuten)"
    echo "5. Web-UI öffnen: http://moode.local"
    echo ""
else
    echo ""
    echo "❌ Fehler beim Brennen!"
    exit 1
fi

