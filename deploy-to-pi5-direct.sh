#!/bin/bash
################################################################################
# Deploy Image direkt auf Raspberry Pi 5
# IP: 192.168.178.161
################################################################################

set -e

IMAGE_FILE="2025-12-07-moode-r1001-arm64-lite.img"
PI_HOST="192.168.178.161"
PI_USER="pi"

echo "=== DEPLOY IMAGE TO PI 5 ==="
echo "Host: $PI_HOST"
echo "Image: $IMAGE_FILE"
echo ""

# Prüfe ob Image existiert
if [ ! -f "$IMAGE_FILE" ]; then
    echo "❌ Image nicht gefunden: $IMAGE_FILE"
    exit 1
fi

# Prüfe Verbindung
echo "1. Prüfe Verbindung zu $PI_HOST..."
if ! ping -c 2 "$PI_HOST" >/dev/null 2>&1; then
    echo "❌ Pi 5 nicht erreichbar: $PI_HOST"
    exit 1
fi
echo "✅ Pi 5 erreichbar"

# Prüfe verfügbaren Platz auf Pi
echo ""
echo "2. Prüfe verfügbaren Platz auf Pi 5..."
AVAILABLE=$(ssh "$PI_USER@$PI_HOST" "df /tmp | tail -1 | awk '{print \$4}'")
echo "   Verfügbar: $AVAILABLE KB"

# Kopiere Image
echo ""
echo "3. Kopiere Image zu Pi 5..."
echo "   Das kann einige Minuten dauern (~5.2 GB)..."
echo "   Bitte warten..."
scp -o Compression=no "$IMAGE_FILE" "$PI_USER@$PI_HOST:/tmp/" || {
    echo "❌ Fehler beim Kopieren"
    exit 1
}
echo "✅ Image kopiert"

echo ""
echo "✅ IMAGE KOPIERT!"
echo ""
echo "Nächste Schritte:"
echo "1. SD-Karte in Pi 5 einstecken (falls nicht schon)"
echo "2. SSH zu Pi 5: ssh pi@192.168.178.161"
echo "3. SD-Karte finden: lsblk"
echo "4. Image brennen: sudo dd if=/tmp/$IMAGE_FILE of=/dev/sdX bs=4M status=progress"
echo ""
echo "Oder verwende das interaktive Script:"
echo "  ssh pi@192.168.178.161 'bash -s' < burn-image-on-pi.sh"

