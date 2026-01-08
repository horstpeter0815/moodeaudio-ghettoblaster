#!/bin/bash
################################################################################
# Burn Image on Raspberry Pi 5
# Wird auf dem Pi 5 ausgeführt
################################################################################

IMAGE_FILE="/tmp/2025-12-07-moode-r1001-arm64-lite.img"

echo "=== BURN IMAGE ON PI 5 ==="
echo ""

# Prüfe ob Image existiert
if [ ! -f "$IMAGE_FILE" ]; then
    echo "❌ Image nicht gefunden: $IMAGE_FILE"
    echo "   Bitte zuerst Image kopieren!"
    exit 1
fi

# Finde SD-Karte
echo "1. Suche SD-Karte..."
SD_DEVICES=$(lsblk -d -o NAME,SIZE,TYPE | grep -E 'sd[a-z]|mmcblk[0-9]' | grep -v boot)

if [ -z "$SD_DEVICES" ]; then
    echo "❌ Keine SD-Karte gefunden"
    echo "   Bitte SD-Karte einstecken und erneut versuchen"
    exit 1
fi

echo "   Gefundene Geräte:"
echo "$SD_DEVICES"
echo ""

# Wähle SD-Karte
echo "2. Wähle SD-Karte..."
read -p "   Device-Name (z.B. sda, mmcblk0): " SD_DEVICE

if [ -z "$SD_DEVICE" ]; then
    echo "❌ Kein Device angegeben"
    exit 1
fi

# Prüfe ob Device existiert
if [ ! -e "/dev/$SD_DEVICE" ]; then
    echo "❌ Device nicht gefunden: /dev/$SD_DEVICE"
    exit 1
fi

# Warnung
echo ""
echo "⚠️  WICHTIG:"
echo "   Device: /dev/$SD_DEVICE"
echo "   Alle Daten auf diesem Device werden gelöscht!"
echo ""
read -p "   Wirklich fortfahren? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "   Abgebrochen"
    exit 0
fi

# Unmount
echo ""
echo "3. Unmounte Device..."
sudo umount /dev/${SD_DEVICE}* 2>/dev/null || true
sleep 2

# Brenne Image
echo ""
echo "4. Brenne Image (dauert ~5-10 Minuten)..."
echo "   Image: $IMAGE_FILE"
echo "   Target: /dev/$SD_DEVICE"
echo ""
sudo dd if="$IMAGE_FILE" of=/dev/$SD_DEVICE bs=4M status=progress

# Sync
echo ""
echo "5. Sync..."
sync

echo ""
echo "✅ IMAGE ERFOLGREICH GEBRANNT!"
echo ""
echo "Nächste Schritte:"
echo "1. SD-Karte aus Pi 5 entfernen"
echo "2. SD-Karte in Raspberry Pi 5 (Ziel-System) stecken"
echo "3. System booten"
echo "4. Web-UI öffnen: http://moode.local oder IP-Adresse"
echo "5. Features testen"

