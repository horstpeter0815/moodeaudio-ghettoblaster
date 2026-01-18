#!/bin/bash
# Brenne Ghettoblaster Image auf SD-Karte (muss mit sudo ausgeführt werden)

set -e

SD_DISK="/dev/disk4"
IMAGE_PATH="/Users/andrevollmer/Library/Mobile Documents/com~apple~CloudDocs/Ablage/Roon filters/Bose Wave/OS/RPI5/Moodeaudio/GhettoblasterPi5.img.gz"

echo "=== BRENNE IMAGE AUF SD-KARTE ==="
echo "SD-Karte: $SD_DISK"
echo "Image: $IMAGE_PATH"
echo ""

# Prüfe Image
if [ ! -f "$IMAGE_PATH" ]; then
    echo "❌ Image nicht gefunden: $IMAGE_PATH"
    exit 1
fi

echo "✅ Image gefunden (1.5GB)"
echo ""

# Unmount SD-Karte
echo "Unmount SD-Karte..."
diskutil unmountDisk "$SD_DISK" 2>/dev/null || true
sleep 2

# Brenne Image
echo ""
echo "=== BRENNE IMAGE ==="
echo "Das kann 5-15 Minuten dauern..."
echo ""

# Use conv=sparse to skip empty space (much faster!)
gunzip -c "$IMAGE_PATH" | dd of="$SD_DISK" bs=4m conv=sparse status=progress

# Sync
echo ""
echo "Sync..."
sync

# Eject
echo ""
echo "Eject SD-Karte..."
diskutil eject "$SD_DISK"

echo ""
echo "✅ FERTIG! Image wurde erfolgreich gebrannt"
echo ""
echo "Nächste Schritte:"
echo "1. SD-Karte in Raspberry Pi 5 einstecken"
echo "2. Pi booten"
echo "3. Warte 30-60 Sekunden auf Boot"

