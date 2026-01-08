#!/bin/bash
# Fix All Cloud-Init Hang Issues
# Entfernt After=moode-startup.service von allen Services die blockieren könnten

set -e

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  🔧 FIX ALL CLOUD-INIT HANG ISSUES                         ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

ROOT_MOUNT="/Volumes/rootfs"

if [ ! -d "$ROOT_MOUNT/etc/systemd/system" ]; then
    echo "❌ Root-Partition nicht gemountet!"
    echo "   Bitte zuerst mounten:"
    echo "   SD_DEVICE=\$(diskutil list | grep -E 'external.*physical' | head -1 | awk '{print \$NF}')"
    echo "   sudo mkdir -p /Volumes/rootfs"
    echo "   sudo mount -t ext4 /dev/\${SD_DEVICE}s2 /Volumes/rootfs"
    exit 1
fi

echo "✅ Root-Partition: $ROOT_MOUNT"
echo ""

# Finde alle Services die auf moode-startup.service warten
echo "🔍 Suche nach Services die auf moode-startup.service warten..."
SERVICES=$(find "$ROOT_MOUNT" -name "*.service" -type f -exec grep -l "After=moode-startup.service" {} \; 2>/dev/null)

if [ -z "$SERVICES" ]; then
    echo "✅ Keine Services gefunden die auf moode-startup.service warten!"
    echo "   Das Problem liegt woanders."
    exit 0
fi

echo "⚠️  Gefundene Services:"
echo "$SERVICES" | while read -r service; do
    echo "   • $service"
done
echo ""

# Fix anwenden
echo "🔧 Wende Fix an..."
echo "$SERVICES" | while read -r service; do
    echo ""
    echo "📋 Fix: $service"
    
    # Backup erstellen
    sudo cp "$service" "${service}.bak" 2>/dev/null || echo "   ⚠️  Backup benötigt sudo"
    
    # Fix anwenden
    sudo sed -i '' '/After=moode-startup.service/d' "$service" 2>/dev/null || {
        echo "   ⚠️  Fix benötigt sudo - bitte manuell ausführen:"
        echo "   sudo sed -i '' '/After=moode-startup.service/d' \"$service\""
        continue
    }
    
    echo "   ✅ After=moode-startup.service entfernt"
    
    # Zeige neue Konfiguration
    echo "   Neue Konfiguration:"
    grep -E "After=|Wants=|Requires=" "$service" || echo "   Keine Dependencies"
done

echo ""
echo "✅ Fix angewendet!"
echo ""
echo "📋 Zum Unmounten:"
echo "   sudo umount $ROOT_MOUNT"
echo "   diskutil eject /dev/\$(diskutil list | grep -E 'external.*physical' | head -1 | awk '{print \$NF}')"
echo ""

