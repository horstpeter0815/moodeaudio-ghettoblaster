#!/bin/bash
# Fix Cloud-Init Hang - Final Version with Auto-Mount Detection

set -e

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  🔧 FIX CLOUD-INIT HANG (SD-KARTE)                         ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Finde SD-Karte
SD_DEVICE=$(diskutil list | grep -E 'external.*physical' | head -1 | awk '{print $NF}' 2>/dev/null | sed 's|/dev/||')
if [ -z "$SD_DEVICE" ]; then
    echo "❌ Keine SD-Karte gefunden!"
    echo "   Bitte SD-Karte einstecken und erneut versuchen."
    exit 1
fi

echo "✅ SD-Karte gefunden: /dev/$SD_DEVICE"
echo ""

# Prüfe ob Root-Partition bereits gemountet ist
ROOT_MOUNT=""
if mount | grep -q "disk${SD_DEVICE#disk}.*ext4\|rootfs"; then
    ROOT_MOUNT=$(mount | grep -E "disk${SD_DEVICE#disk}.*ext4|rootfs" | awk '{print $3}' | head -1)
    echo "✅ Root-Partition bereits gemountet: $ROOT_MOUNT"
else
    echo "📋 Root-Partition muss gemountet werden..."
    echo "   Führe aus:"
    echo "   sudo mkdir -p /Volumes/rootfs"
    echo "   sudo mount -t ext4 /dev/${SD_DEVICE}s2 /Volumes/rootfs"
    echo ""
    echo "   Dann dieses Script erneut ausführen."
    exit 1
fi

# Prüfe ob Verzeichnis existiert
if [ ! -d "$ROOT_MOUNT/usr/lib/systemd/system" ] && [ ! -d "$ROOT_MOUNT/etc/systemd/system" ]; then
    echo "❌ Root-Partition nicht korrekt gemountet!"
    echo "   Gefunden: $ROOT_MOUNT"
    echo "   Erwartet: /Volumes/rootfs mit /usr/lib/systemd/system oder /etc/systemd/system"
    exit 1
fi

echo "✅ Root-Partition OK: $ROOT_MOUNT"
echo ""

# Finde fix-ssh-sudoers.service
FIX_SSH_SUDOERS_FILE=$(find "$ROOT_MOUNT" -name "fix-ssh-sudoers.service" -type f 2>/dev/null | head -1)

if [ -z "$FIX_SSH_SUDOERS_FILE" ]; then
    echo "⚠️  fix-ssh-sudoers.service nicht gefunden"
    echo "   Suche nach anderen Services die auf moode-startup warten..."
    
    # Suche alle Services
    SERVICES=$(find "$ROOT_MOUNT" -name "*.service" -type f -exec grep -l "After=moode-startup.service" {} \; 2>/dev/null | head -5)
    
    if [ -z "$SERVICES" ]; then
        echo "✅ Keine Services gefunden die auf moode-startup.service warten!"
        echo "   Das Problem liegt woanders."
        exit 0
    fi
    
    echo "⚠️  Gefundene Services:"
    echo "$SERVICES" | while read -r service; do
        echo "   • $service"
    done
else
    echo "✅ fix-ssh-sudoers.service gefunden: $FIX_SSH_SUDOERS_FILE"
    echo ""
    echo "Aktuelle Konfiguration:"
    grep -E "After=|Wants=|Requires=" "$FIX_SSH_SUDOERS_FILE" || echo "Keine Dependencies"
    echo ""
    
    # Prüfe ob Fix bereits angewendet wurde
    if ! grep -q "After=moode-startup.service" "$FIX_SSH_SUDOERS_FILE"; then
        echo "✅ After=moode-startup.service bereits entfernt!"
        echo "   Das Problem liegt woanders."
        exit 0
    fi
    
    echo "🔧 Wende Fix an..."
    echo "   Bitte ausführen:"
    echo "   sudo sed -i '' '/After=moode-startup.service/d' \"$FIX_SSH_SUDOERS_FILE\""
    echo ""
    echo "   Dann prüfen:"
    echo "   grep 'After=' \"$FIX_SSH_SUDOERS_FILE\""
fi

echo ""
echo "📋 Zum Unmounten (nach dem Fix):"
echo "   sudo umount $ROOT_MOUNT"
echo "   diskutil eject /dev/$SD_DEVICE"
echo ""

