#!/bin/bash

# Write Image to SD Card Script
# Schreibt das neueste Moode Image auf die SD-Karte

set -e

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  💾 IMAGE AUF SD-KARTE SCHREIBEN                            ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Finde SD-Karte - suche nach externen physischen Geräten
SD_LINE=$(diskutil list | grep -E 'external.*physical' | head -1)
if [ -z "$SD_LINE" ]; then
    echo "❌ Keine SD-Karte gefunden!"
    echo "   Bitte SD-Karte einstecken und erneut versuchen."
    exit 1
fi

# Extrahiere Gerätenamen (z.B. "disk4" aus "/dev/disk4 (external, physical):")
SD_DEVICE=$(echo "$SD_LINE" | awk '{print $1}' | sed 's|/dev/||')

echo "✅ SD-Karte gefunden: /dev/$SD_DEVICE"
echo ""

# Finde neuestes Image (prüfe auch ZIP-Files)
IMAGE_FILE=$(ls -t /Users/andrevollmer/moodeaudio-cursor/imgbuild/deploy/moode-r1001-arm64-*.img 2>/dev/null | head -1)
if [ -z "$IMAGE_FILE" ]; then
    # Prüfe ob ZIP-File vorhanden ist und entpacke es
    ZIP_FILE=$(ls -t /Users/andrevollmer/moodeaudio-cursor/imgbuild/deploy/image_moode-r1001-arm64-*.zip 2>/dev/null | head -1)
    if [ -n "$ZIP_FILE" ]; then
        echo "📦 Image ist im ZIP-File, entpacke..."
        cd /Users/andrevollmer/moodeaudio-cursor/imgbuild/deploy
        unzip -o "$ZIP_FILE"
        IMAGE_FILE=$(ls -t /Users/andrevollmer/moodeaudio-cursor/imgbuild/deploy/moode-r1001-arm64-*.img 2>/dev/null | head -1)
        cd - > /dev/null
    fi
fi

if [ -z "$IMAGE_FILE" ]; then
    echo "❌ Kein Image gefunden!"
    echo "   Bitte zuerst Build ausführen."
    exit 1
fi

echo "📦 Image: $(basename "$IMAGE_FILE")"
echo "   Größe: $(ls -lh "$IMAGE_FILE" | awk '{print $5}')"
echo ""

# Bestätigung
echo "⚠️  WICHTIG: Dies wird ALLE Daten auf /dev/$SD_DEVICE löschen!"
read -p "Fortfahren? (j/n): " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Jj]$ ]]; then
    echo "❌ Abgebrochen."
    exit 1
fi

# Unmount SD-Karte
echo ""
echo "🔌 Unmounte SD-Karte..."
diskutil unmountDisk force /dev/$SD_DEVICE || true
sleep 2

# Prüfe ob noch gemountet
if diskutil info /dev/$SD_DEVICE | grep -q "Mounted:.*Yes"; then
    echo "⚠️  SD-Karte ist noch gemountet. Versuche alle Partitionen zu unmounten..."
    diskutil unmount /dev/${SD_DEVICE}s1 2>/dev/null || true
    diskutil unmount /dev/${SD_DEVICE}s2 2>/dev/null || true
    diskutil unmountDisk force /dev/$SD_DEVICE || true
    sleep 2
fi

# Schreibe Image
echo ""
echo "💾 Schreibe Image auf SD-Karte..."
echo "   Dies kann 5-10 Minuten dauern..."
echo "   Verwende /dev/r${SD_DEVICE} für bessere Performance..."
echo ""

sudo dd if="$IMAGE_FILE" of=/dev/r${SD_DEVICE} bs=1m status=progress

# Sync
echo ""
echo "🔄 Synchronisiere..."
sync

# Eject
echo ""
echo "✅ Fertig! Image wurde erfolgreich geschrieben."
echo ""
echo "📋 Nächste Schritte:"
echo "   1. SD-Karte auswerfen: diskutil eject /dev/$SD_DEVICE"
echo "   2. SD-Karte in Pi einstecken"
echo "   3. Pi booten"
echo ""

