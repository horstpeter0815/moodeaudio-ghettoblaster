#!/bin/bash
################################################################################
# FAST SD CARD BURNING - Handles sparse files correctly
# 
# Uses conv=sparse to skip empty space, making it much faster
# Usage: sudo ./burn-sd-fast.sh
################################################################################

set -e

SD_DISK="/dev/disk4"
IMAGE_PATH="/Users/andrevollmer/Library/Mobile Documents/com~apple~CloudDocs/Ablage/Roon filters/Bose Wave/OS/RPI5/Moodeaudio/GhettoblasterPi5.img.gz"

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  ⚡ FAST SD CARD BURNING (mit sparse file support)            ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "SD-Karte: $SD_DISK"
echo "Image: $IMAGE_PATH"
echo ""

# Prüfe Image
if [ ! -f "$IMAGE_PATH" ]; then
    echo "❌ Image nicht gefunden: $IMAGE_PATH"
    exit 1
fi

# Prüfe Image-Größe
echo "=== IMAGE INFO ==="
COMPRESSED_SIZE=$(ls -lh "$IMAGE_PATH" | awk '{print $5}')
UNCOMPRESSED_SIZE=$(gunzip -l "$IMAGE_PATH" 2>/dev/null | tail -1 | awk '{print $2}')
UNCOMPRESSED_GB=$((UNCOMPRESSED_SIZE / 1024 / 1024 / 1024))

echo "Komprimiert: $COMPRESSED_SIZE"
echo "Entpackt: ~${UNCOMPRESSED_GB}GB"
echo ""

if [ "$UNCOMPRESSED_GB" -gt 10 ]; then
    echo "⚠️  WARNUNG: Image ist sehr groß (${UNCOMPRESSED_GB}GB)"
    echo "   Das Image enthält wahrscheinlich viel leeren Speicherplatz"
    echo "   Verwende conv=sparse um leeren Speicher zu überspringen"
    echo ""
fi

# Unmount SD-Karte
echo "=== UNMOUNT SD-KARTE ==="
diskutil unmountDisk "$SD_DISK" 2>/dev/null || true
sleep 2

# Brenne Image mit conv=sparse (überspringt leeren Speicher)
echo ""
echo "=== BRENNE IMAGE (FAST MODE) ==="
echo "Verwende conv=sparse - überspringt leeren Speicherplatz"
echo "Das sollte viel schneller sein!"
echo ""

# Use conv=sparse to skip empty blocks
gunzip -c "$IMAGE_PATH" | dd of="$SD_DISK" bs=4m conv=sparse status=progress

# Sync
echo ""
echo "=== SYNC ==="
sync

# Eject
echo ""
echo "=== EJECT SD-KARTE ==="
diskutil eject "$SD_DISK"

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  ✅ FERTIG! Image wurde erfolgreich gebrannt                   ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "Nächste Schritte:"
echo "  1. SD-Karte in Raspberry Pi 5 einstecken"
echo "  2. Pi booten"
echo "  3. Warte 30-60 Sekunden"
echo "  4. Konfiguriere: sudo ./configure-sd-complete.sh"
echo ""

