#!/bin/bash
# moOde Audio für Pi 4 auf SD-Karte brennen

SD_DEVICE="/dev/disk4"
MOODE_IMAGE=""
BACKUP_DIR="SD_CARD_BACKUPS/$(ls -t SD_CARD_BACKUPS/ | head -1)"

echo "=== MOODE AUDIO FÜR PI 4 BURN ==="
echo ""

# Prüfe ob SD-Karte gemountet ist
if mount | grep -q "$SD_DEVICE"; then
    echo "⚠️ SD-Karte ist noch gemountet. Unmounting..."
    diskutil unmountDisk "$SD_DEVICE" 2>/dev/null
    sleep 2
fi

# Prüfe ob Image vorhanden
if [ -z "$MOODE_IMAGE" ] || [ ! -f "$MOODE_IMAGE" ]; then
    echo "❌ moOde Image nicht gefunden!"
    echo ""
    echo "Bitte moOde Image herunterladen von:"
    echo "https://moodeaudio.org/"
    echo ""
    echo "Oder Image-Pfad angeben:"
    echo "MOODE_IMAGE=/path/to/moode-r900-arm64.img ./burn-moode-pi4.sh"
    exit 1
fi

echo "SD-Karte: $SD_DEVICE"
echo "Image: $MOODE_IMAGE"
echo "Backup: $BACKUP_DIR"
echo ""
read -p "Fortfahren? (y/N): " confirm

if [ "$confirm" != "y" ]; then
    echo "Abgebrochen."
    exit 0
fi

# Unmount SD-Karte
echo "Unmounting SD-Karte..."
diskutil unmountDisk "$SD_DEVICE" 2>/dev/null
sleep 2

# Brenne Image
echo "Brenne moOde Image auf SD-Karte..."
echo "Dies kann einige Minuten dauern..."
sudo dd if="$MOODE_IMAGE" of="$SD_DEVICE" bs=1m status=progress

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ moOde Image erfolgreich gebrannt!"
    echo ""
    echo "SD-Karte kann jetzt in Pi 4 verwendet werden."
    sync
else
    echo ""
    echo "❌ Fehler beim Brennen!"
    exit 1
fi

