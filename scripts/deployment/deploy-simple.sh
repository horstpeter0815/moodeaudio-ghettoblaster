#!/bin/bash
# Einfaches Deployment-Script - Passwort wird interaktiv abgefragt

PI_HOST="192.168.178.161"
PI_USER="pi"
IMAGE_FILE="2025-12-07-moode-r1001-arm64-lite.img"

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  🚀 DEPLOYMENT STARTET                                       ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

echo "📦 Schritt 1: Image kopieren..."
echo "   (Passwort wird abgefragt - verwende: DSD)"
scp "$IMAGE_FILE" "$PI_USER@$PI_HOST:/tmp/" || {
    echo "❌ Fehler beim Kopieren"
    exit 1
}
echo "✅ Image kopiert"
echo ""

echo "🔍 Schritt 2: SD-Karte finden..."
SD_DEVICE=$(ssh "$PI_USER@$PI_HOST" "lsblk -d -o NAME,SIZE,TYPE | grep -E 'sd[a-z]|mmcblk[0-9]' | grep -v boot | head -1 | awk '{print \$1}'")

if [ -z "$SD_DEVICE" ]; then
    echo "❌ Keine SD-Karte gefunden!"
    exit 1
fi

echo "✅ SD-Karte gefunden: /dev/$SD_DEVICE"
echo ""
echo "⚠️  WICHTIG: Alle Daten auf /dev/$SD_DEVICE werden gelöscht!"
read -p "   Wirklich fortfahren? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "   Abgebrochen"
    exit 0
fi

echo ""
echo "🔥 Schritt 3: Image brennen (dauert ~5-10 Minuten)..."
echo "   (Passwort wird nochmal abgefragt)"
ssh "$PI_USER@$PI_HOST" "sudo umount /dev/${SD_DEVICE}* 2>/dev/null || true; sudo dd if=/tmp/$IMAGE_FILE of=/dev/$SD_DEVICE bs=4M status=progress && sync" || {
    echo "❌ Fehler beim Brennen"
    exit 1
}

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  ✅ DEPLOYMENT ERFOLGREICH!                                  ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "📋 NÄCHSTE SCHRITTE:"
echo "1. SD-Karte aus Pi 5 entfernen"
echo "2. SD-Karte in Raspberry Pi 5 (Ziel-System) stecken"
echo "3. Hardware verbinden (AMP100, Display, Touchscreen)"
echo "4. System booten"
echo "5. Web-UI öffnen: http://moode.local"
echo ""
