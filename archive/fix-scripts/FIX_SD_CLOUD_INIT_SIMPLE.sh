#!/bin/bash
# Fix Cloud-Init Hang - Simplified Version
# Führt die Befehle aus, die der Benutzer manuell ausführen kann

set -e

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  🔧 FIX CLOUD-INIT HANG (SD-KARTE)                         ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Finde SD-Karte
SD_DEVICE=$(diskutil list | grep -E 'external.*physical' | head -1 | awk '{print $NF}' 2>/dev/null)
if [ -z "$SD_DEVICE" ]; then
    echo "❌ Keine SD-Karte gefunden!"
    exit 1
fi

echo "✅ SD-Karte gefunden: /dev/$SD_DEVICE"
echo ""

# Prüfe ob Root-Partition bereits gemountet ist
ROOT_MOUNT=""
if mount | grep -q "disk4s2.*ext4"; then
    ROOT_MOUNT=$(mount | grep "disk4s2.*ext4" | awk '{print $3}' | head -1)
    echo "✅ Root-Partition bereits gemountet: $ROOT_MOUNT"
else
    echo "📋 Root-Partition muss gemountet werden:"
    echo "   sudo mkdir -p /Volumes/rootfs"
    echo "   sudo mount -t ext4 /dev/${SD_DEVICE}s2 /Volumes/rootfs"
    echo ""
    echo "   Dann dieses Script erneut ausführen."
    exit 1
fi

# Fix anwenden
echo "🔧 Wende Fix an..."
FIX_USER_ID_FILE=$(find "$ROOT_MOUNT" -name "fix-user-id.service" -type f | head -1)
if [ -n "$FIX_USER_ID_FILE" ]; then
    echo "   Service-Datei: $FIX_USER_ID_FILE"
    
    # Backup erstellen
    sudo cp "$FIX_USER_ID_FILE" "${FIX_USER_ID_FILE}.bak" 2>/dev/null || {
        echo "   ⚠️  Backup benötigt sudo - überspringe Backup"
    }
    
    # Fix anwenden (benötigt sudo)
    echo "   Entferne After=moode-startup.service..."
    sudo sed -i '' '/After=moode-startup.service/d' "$FIX_USER_ID_FILE" 2>/dev/null || {
        echo "   ⚠️  Fix benötigt sudo - bitte manuell ausführen:"
        echo "   sudo sed -i '' '/After=moode-startup.service/d' \"$FIX_USER_ID_FILE\""
        exit 1
    }
    
    echo "   ✅ Fix angewendet!"
    echo ""
    echo "   Neue Konfiguration:"
    grep -E "After=|Wants=|Requires=" "$FIX_USER_ID_FILE" || echo "   Keine Dependencies"
else
    echo "   ⚠️  fix-user-id.service nicht gefunden"
fi

echo ""
echo "✅ Fertig!"
echo ""
echo "📋 Zum Unmounten:"
echo "   sudo umount $ROOT_MOUNT"
echo "   diskutil eject /dev/$SD_DEVICE"
