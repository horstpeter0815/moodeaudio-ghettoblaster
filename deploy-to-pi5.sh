#!/bin/bash
################################################################################
# Deploy Image to Raspberry Pi 5
# Kopiert Image direkt auf Pi 5 und brennt es auf SD-Karte
################################################################################

set -e

IMAGE_FILE="2025-12-07-moode-r1001-arm64-lite.img"
PI_HOST="${1:-moode.local}"
PI_USER="${2:-pi}"

echo "=== DEPLOY IMAGE TO PI 5 ==="
echo "Host: $PI_HOST"
echo "User: $PI_USER"
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
    echo "   Versuche: raspberrypi.local oder IP-Adresse"
    exit 1
fi
echo "✅ Pi 5 erreichbar"

# Kopiere Image
echo ""
echo "2. Kopiere Image zu Pi 5..."
echo "   Das kann einige Minuten dauern (~5.2 GB)..."
scp "$IMAGE_FILE" "$PI_USER@$PI_HOST:/tmp/" || {
    echo "❌ Fehler beim Kopieren"
    exit 1
}
echo "✅ Image kopiert"

# Brenne auf SD-Karte (auf Pi 5)
echo ""
echo "3. Brenne Image auf SD-Karte (auf Pi 5)..."
echo "   ⚠️  WICHTIG: Stelle sicher dass SD-Karte in Pi 5 ist!"
ssh "$PI_USER@$PI_HOST" << 'PIEOF'
    # Finde SD-Karte
    SD_DEVICE=$(lsblk -d -o NAME,SIZE,TYPE | grep -E 'sd[a-z]|mmcblk[0-9]' | grep -v boot | head -1 | awk '{print $1}')
    
    if [ -z "$SD_DEVICE" ]; then
        echo "❌ Keine SD-Karte gefunden"
        exit 1
    fi
    
    echo "   Gefundene SD-Karte: /dev/$SD_DEVICE"
    echo "   ⚠️  Bist du sicher? (Dies wird alle Daten löschen!)"
    read -p "   Weiter? (yes/no): " confirm
    
    if [ "$confirm" != "yes" ]; then
        echo "   Abgebrochen"
        exit 1
    fi
    
    # Unmount
    sudo umount /dev/${SD_DEVICE}* 2>/dev/null || true
    
    # Brenne Image
    echo "   Brenne Image (dauert ~5-10 Minuten)..."
    sudo dd if=/tmp/2025-12-07-moode-r1001-arm64-lite.img of=/dev/$SD_DEVICE bs=4M status=progress
    
    # Sync
    sync
    
    echo "✅ Image gebrannt"
PIEOF

echo ""
echo "✅ DEPLOYMENT ABGESCHLOSSEN!"
echo "   SD-Karte ist bereit. System kann gebootet werden."

