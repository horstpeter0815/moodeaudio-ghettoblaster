#!/bin/bash
################################################################################
# Brenne Ghettoblaster Image auf SD-Karte
################################################################################

set -e

IMAGE_PATH="/Users/andrevollmer/Library/Mobile Documents/com~apple~CloudDocs/Ablage/Roon filters/Bose Wave/OS/RPI5/Moodeaudio/GhettoblasterPi5.img.gz"

echo "=== GHETTOBLASTER IMAGE AUF SD-KARTE BRENNEN ==="
echo ""

# Prüfe ob Image existiert
if [ ! -f "$IMAGE_PATH" ]; then
    echo "❌ Image nicht gefunden: $IMAGE_PATH"
    exit 1
fi

echo "✅ Image gefunden:"
ls -lh "$IMAGE_PATH"
echo ""

# Warte auf SD-Karte
echo "=== WARTE AUF SD-KARTE ==="
echo "Bitte SD-Karte einstecken..."
echo ""

SD_FOUND=false
for i in {1..30}; do
    # Finde externe SD-Karte
    SD_DISK=$(diskutil list | grep -E "^/dev/disk[0-9]+" | grep -v "synthesized" | awk '{print $1}' | while read disk; do
        if diskutil info "$disk" 2>/dev/null | grep -q "Removable Media\|External"; then
            echo "$disk"
            break
        fi
    done)
    
    if [ -n "$SD_DISK" ]; then
        SD_FOUND=true
        break
    fi
    
    echo -n "."
    sleep 1
done
echo ""

if [ "$SD_FOUND" = false ]; then
    echo "❌ Keine SD-Karte gefunden"
    echo ""
    echo "Bitte SD-Karte einstecken und Script erneut ausführen"
    exit 1
fi

echo "✅ SD-Karte gefunden: $SD_DISK"
echo ""

# Zeige SD-Karte Info
echo "=== SD-KARTE INFO ==="
diskutil info "$SD_DISK" | grep -E "Device Node|Disk Size|Removable|Protocol"
echo ""

# Sicherheitsabfrage
echo "⚠️  WICHTIG: Alle Daten auf $SD_DISK werden gelöscht!"
read -p "Fortfahren? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "Abgebrochen"
    exit 0
fi

# Unmount SD-Karte
echo ""
echo "=== UNMOUNT SD-KARTE ==="
diskutil unmountDisk "$SD_DISK" || true
sleep 2

# Brenne Image (entpackt während des Brennens)
echo ""
echo "=== BRENNE IMAGE ==="
echo "Entpacke und brenne gleichzeitig (1.5GB komprimiert -> ~3-5GB)..."
echo "Das kann 5-15 Minuten dauern..."
echo ""

gunzip -c "$IMAGE_PATH" | sudo dd of="$SD_DISK" bs=4m status=progress

# Sync
echo ""
echo "=== SYNC ==="
sync

# Eject
echo ""
echo "=== EJECT SD-KARTE ==="
diskutil eject "$SD_DISK"

echo ""
echo "✅ FERTIG! Image wurde auf SD-Karte gebrannt"
echo ""
echo "Nächste Schritte:"
echo "1. SD-Karte auswerfen"
echo "2. SD-Karte in Raspberry Pi 5 einstecken"
echo "3. Pi booten"

