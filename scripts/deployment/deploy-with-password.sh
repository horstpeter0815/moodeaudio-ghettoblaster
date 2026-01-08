#!/bin/bash
################################################################################
# Deploy Image - Mit Passwort
################################################################################

PI_HOST="192.168.178.161"
PI_USER="pi"
PI_PASS="DSD"
IMAGE_FILE="2025-12-07-moode-r1001-arm64-lite.img"

echo "🚀 Starte Deployment..."

# Prüfe Image
if [ ! -f "$IMAGE_FILE" ]; then
    echo "❌ Image nicht gefunden"
    exit 1
fi

# Prüfe sshpass
if ! command -v sshpass >/dev/null 2>&1; then
    echo "❌ sshpass nicht installiert"
    echo "   Installiere mit: brew install hudochenkov/sshpass/sshpass"
    exit 1
fi

echo "📦 Kopiere Image..."
sshpass -p "$PI_PASS" scp -o StrictHostKeyChecking=no "$IMAGE_FILE" "$PI_USER@$PI_HOST:/tmp/" || {
    echo "❌ Fehler beim Kopieren"
    exit 1
}
echo "✅ Image kopiert"

echo "🔍 Suche SD-Karte..."
SD_DEVICE=$(sshpass -p "$PI_PASS" ssh -o StrictHostKeyChecking=no "$PI_USER@$PI_HOST" "lsblk -d -o NAME,SIZE,TYPE | grep -E 'sd[a-z]|mmcblk[0-9]' | grep -v boot | head -1 | awk '{print \$1}'")

if [ -z "$SD_DEVICE" ]; then
    echo "❌ Keine SD-Karte gefunden!"
    exit 1
fi

echo "✅ SD-Karte: /dev/$SD_DEVICE"
echo "🔥 Brenne Image (dauert ~5-10 Min)..."
sshpass -p "$PI_PASS" ssh -o StrictHostKeyChecking=no "$PI_USER@$PI_HOST" "sudo umount /dev/${SD_DEVICE}* 2>/dev/null || true; sudo dd if=/tmp/$IMAGE_FILE of=/dev/$SD_DEVICE bs=4M status=progress && sync"

echo ""
echo "✅ FERTIG! SD-Karte aus Pi 5 entfernen und in Ziel-System stecken."

