#!/bin/bash
# 🔥 BRENNE IMAGE JETZT - Führe dieses Script aus!

cd "/Users/andrevollmer/Library/Mobile Documents/com~apple~CloudDocs/Ablage/Roon filters/Bose Wave/OS/RPi4/moodeaudio/cursor"

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  🔥 IMAGE AUF SD-KARTE BRENNEN                               ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "✅ SD-Karte gefunden: /dev/disk4 (63.9 GB)"
echo ""
echo "⚠️  WICHTIG: Alle Daten werden gelöscht!"
echo ""
echo "🔥 Starte Brennen..."
echo ""

# Unmount
diskutil unmountDisk /dev/disk4

# Brennen
sudo dd if=2025-12-07-moode-r1001-arm64-lite.img of=/dev/rdisk4 bs=4m status=progress

# Sync
sync

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  ✅ FERTIG!                                                  ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "📋 NÄCHSTE SCHRITTE:"
echo "1. SD-Karte sicher auswerfen"
echo "2. SD-Karte in Raspberry Pi 5 stecken"
echo "3. Hardware verbinden"
echo "4. System booten"
echo "5. Web-UI: http://moode.local"
echo ""

