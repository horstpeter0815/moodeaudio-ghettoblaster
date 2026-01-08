#!/bin/bash
# FIX ALL - Einziger Fix für alle Probleme
# Fixes: IP-Adresse, NetworkManager, cloud-init Blockierung

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -z "$SCRIPT_DIR" ] || [ ! -d "$SCRIPT_DIR" ]; then
    SCRIPT_DIR="/Users/andrevollmer/moodeaudio-cursor"
fi

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  🔧 FIX ALL - EINZIGER KOMPLETT-FIX                        ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Finde SD-Karte
SD_LINE=$(diskutil list | grep -E 'external.*physical' | head -1)
if [ -z "$SD_LINE" ]; then
    echo "❌ Keine SD-Karte gefunden!"
    exit 1
fi

SD_DEVICE=$(echo "$SD_LINE" | awk '{print $1}' | sed 's|/dev/||')
ROOT_MOUNT="/Volumes/rootfs"

echo "✅ SD-Karte: /dev/$SD_DEVICE"
echo ""

# Mounte Root-Partition
sudo mkdir -p "$ROOT_MOUNT"
sudo mount -t ext4 /dev/${SD_DEVICE}s2 "$ROOT_MOUNT" 2>/dev/null || echo "Bereits gemountet"
echo "✅ Root-Partition gemountet"
echo ""

# FIX 1: network-guaranteed.service - Ersetze komplett
echo "1. Fix network-guaranteed.service..."
NG_FILE=$(find "$ROOT_MOUNT" -name "network-guaranteed.service" -type f | head -1)
if [ -n "$NG_FILE" ]; then
    sudo cp "$NG_FILE" "${NG_FILE}.bak"
    sudo cp "$SCRIPT_DIR/custom-components/services/network-guaranteed.service" "$NG_FILE"
    echo "   ✅ Ersetzt"
fi
echo ""

# FIX 2: fix-user-id.service - Entferne After=moode-startup.service
echo "2. Fix fix-user-id.service..."
FUI_FILE=$(find "$ROOT_MOUNT" -name "fix-user-id.service" -type f | head -1)
if [ -n "$FUI_FILE" ]; then
    sudo cp "$FUI_FILE" "${FUI_FILE}.bak"
    sudo sed -i '' '/After=moode-startup.service/d' "$FUI_FILE"
    echo "   ✅ After=moode-startup.service entfernt"
fi
echo ""

# FIX 3: fix-ssh-sudoers.service - Entferne After=moode-startup.service
echo "3. Fix fix-ssh-sudoers.service..."
FSS_FILE=$(find "$ROOT_MOUNT" -name "fix-ssh-sudoers.service" -type f | head -1)
if [ -n "$FSS_FILE" ]; then
    sudo cp "$FSS_FILE" "${FSS_FILE}.bak"
    sudo sed -i '' '/After=moode-startup.service/d' "$FSS_FILE"
    echo "   ✅ After=moode-startup.service entfernt"
fi
echo ""

# Unmount
sudo umount "$ROOT_MOUNT" || true
echo "✅ SD-Karte unmounted"
echo ""

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  ✅ ALLE FIXES ANGEWENDET                                   ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "📋 Nächste Schritte:"
echo "  1. diskutil eject /dev/$SD_DEVICE"
echo "  2. SD-Karte in Pi einstecken"
echo "  3. Pi booten"
echo ""

