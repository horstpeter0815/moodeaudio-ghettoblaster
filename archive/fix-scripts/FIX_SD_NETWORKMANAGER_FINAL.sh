#!/bin/bash
# Fix NetworkManager-wait-online on SD Card - FINAL FIX
# Ersetzt network-guaranteed.service mit korrigierter Version

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -z "$SCRIPT_DIR" ] || [ ! -d "$SCRIPT_DIR" ]; then
    SCRIPT_DIR="/Users/andrevollmer/moodeaudio-cursor"
fi

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  🔧 FIX NETWORKMANAGER-WAIT-ONLINE (SD-KARTE FINAL)        ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "Script-Verzeichnis: $SCRIPT_DIR"
echo ""

# Finde SD-Karte
SD_LINE=$(diskutil list | grep -E 'external.*physical' | head -1)
if [ -z "$SD_LINE" ]; then
    echo "❌ Keine SD-Karte gefunden!"
    echo "   Bitte SD-Karte einstecken und erneut versuchen."
    exit 1
fi

SD_DEVICE=$(echo "$SD_LINE" | awk '{print $1}' | sed 's|/dev/||')
ROOT_MOUNT="/Volumes/rootfs"

echo "✅ SD-Karte: /dev/$SD_DEVICE"
echo ""

# Mounte Root-Partition
echo "1. Mounte Root-Partition..."
sudo mkdir -p "$ROOT_MOUNT"
sudo mount -t ext4 /dev/${SD_DEVICE}s2 "$ROOT_MOUNT" 2>/dev/null || echo "Bereits gemountet"
echo "✅ Root-Partition gemountet"
echo ""

# Finde network-guaranteed.service
NETWORK_GUARANTEED_FILE=$(find "$ROOT_MOUNT" -name "network-guaranteed.service" -type f | head -1)
if [ -z "$NETWORK_GUARANTEED_FILE" ]; then
    echo "❌ network-guaranteed.service nicht gefunden!"
    exit 1
fi

echo "2. Fix network-guaranteed.service..."
echo "   Datei: $NETWORK_GUARANTEED_FILE"
sudo cp "$NETWORK_GUARANTEED_FILE" "${NETWORK_GUARANTEED_FILE}.bak"
echo "   ✅ Backup erstellt"
echo ""

# Ersetze mit korrigierter Version aus custom-components
CORRECTED_FILE="$SCRIPT_DIR/custom-components/services/network-guaranteed.service"
if [ ! -f "$CORRECTED_FILE" ]; then
    echo "❌ Korrigierte Datei nicht gefunden: $CORRECTED_FILE"
    exit 1
fi

echo "3. Ersetze mit korrigierter Version..."
sudo cp "$CORRECTED_FILE" "$NETWORK_GUARANTEED_FILE"
echo "   ✅ Datei ersetzt"
echo ""

# Verifikation
echo "4. Verifikation..."
echo "   Netplan renderer:"
grep "renderer:" "$NETWORK_GUARANTEED_FILE" | head -1
echo "   IP-Adressen:"
grep "192\.168\." "$NETWORK_GUARANTEED_FILE" | head -3
echo ""

# Unmount
echo "5. Unmounte SD-Karte..."
sudo umount "$ROOT_MOUNT" || true
echo "✅ SD-Karte unmounted"
echo ""

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  ✅ NETWORKMANAGER FIX ANGEWENDET                          ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "📋 Nächste Schritte:"
echo "  1. diskutil eject /dev/$SD_DEVICE"
echo "  2. SD-Karte in Pi einstecken"
echo "  3. Pi booten"
echo "  4. NetworkManager-wait-online sollte jetzt funktionieren"
echo ""

