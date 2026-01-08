#!/bin/bash
################################################################################
#
# FIX SD CARD SERVICE BLOCK
#
# Analysiert SD-Karte und deaktiviert problematische Services
# die den Display-Boot blockieren könnten
#
################################################################################

set -e

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  🔧 SD-KARTE SERVICE-BLOCK FIXEN                            ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Finde SD-Karte
SD_LINE=$(diskutil list | grep -E 'external.*physical' | head -1)
if [ -z "$SD_LINE" ]; then
    echo "❌ Keine SD-Karte gefunden!"
    echo "   Bitte SD-Karte einstecken und erneut versuchen."
    exit 1
fi

SD_DEVICE=$(echo "$SD_LINE" | awk '{print $1}' | sed 's|/dev/||')
echo "✅ SD-Karte gefunden: /dev/$SD_DEVICE"
echo ""

# Mount SD-Karte
echo "🔌 Mounte SD-Karte..."
diskutil mountDisk /dev/$SD_DEVICE 2>/dev/null || true
sleep 2

# Finde Boot-Partition
BOOT_MOUNT=$(diskutil info /dev/${SD_DEVICE}s1 2>/dev/null | grep "Mount Point" | awk -F': ' '{print $2}' | xargs)
if [ -z "$BOOT_MOUNT" ]; then
    echo "❌ Boot-Partition nicht gefunden!"
    exit 1
fi

echo "✅ Boot-Partition: $BOOT_MOUNT"
echo ""

# Finde Root-Partition (für chroot)
ROOT_MOUNT=$(diskutil info /dev/${SD_DEVICE}s2 2>/dev/null | grep "Mount Point" | awk -F': ' '{print $2}' | xargs)
if [ -z "$ROOT_MOUNT" ]; then
    echo "⚠️  Root-Partition nicht gemountet - mounte manuell..."
    echo "   sudo mkdir -p /Volumes/rootfs"
    echo "   sudo mount -t ext4 /dev/${SD_DEVICE}s2 /Volumes/rootfs"
    ROOT_MOUNT="/Volumes/rootfs"
fi

echo "📋 Analysiere Services..."
echo ""

# Prüfe welche SSH-Services aktiviert sind
echo "🔍 SSH-Services auf SD-Karte:"
if [ -d "$ROOT_MOUNT/etc/systemd/system/multi-user.target.wants" ]; then
    ls -la "$ROOT_MOUNT/etc/systemd/system/multi-user.target.wants" | grep -E 'ssh|fix' || echo "  Keine SSH-Services gefunden"
else
    echo "  multi-user.target.wants nicht gefunden"
fi

echo ""
echo "🔍 Services in /etc/systemd/system:"
if [ -d "$ROOT_MOUNT/etc/systemd/system" ]; then
    ls -la "$ROOT_MOUNT/etc/systemd/system" | grep -E 'ssh|fix' | head -10 || echo "  Keine Services gefunden"
else
    echo "  /etc/systemd/system nicht gefunden"
fi

echo ""
echo "📋 PROBLEM: fix-ssh-service könnte Display blockieren"
echo ""
echo "🔧 Lösungen:"
echo ""
echo "1. Deaktiviere fix-ssh-service:"
echo "   sudo rm -f $ROOT_MOUNT/etc/systemd/system/multi-user.target.wants/fix-ssh-service.service"
echo ""
echo "2. Prüfe Service-Definition:"
echo "   sudo cat $ROOT_MOUNT/etc/systemd/system/fix-ssh-service.service"
echo ""
echo "3. Deaktiviere alle SSH-Services außer ssh-guaranteed:"
echo "   sudo rm -f $ROOT_MOUNT/etc/systemd/system/multi-user.target.wants/fix-ssh-service.service"
echo "   sudo rm -f $ROOT_MOUNT/etc/systemd/system/multi-user.target.wants/fix-ssh-sudoers.service"
echo ""

# Frage ob fixen
echo "🔧 Optionen:"
echo "  1. Deaktiviere fix-ssh-service (empfohlen)"
echo "  2. Installiere korrigierte Version (ohne moode-startup dependency)"
echo "  3. Beides"
echo ""
read -p "Wähle Option (1/2/3/n für abbrechen): " -n 1 -r
echo ""
if [[ $REPLY =~ ^[123]$ ]]; then
    echo ""
    
    if [[ $REPLY == "1" || $REPLY == "3" ]]; then
        echo "🔧 Deaktiviere fix-ssh-service..."
        sudo rm -f "$ROOT_MOUNT/etc/systemd/system/multi-user.target.wants/fix-ssh-service.service" 2>/dev/null || true
        sudo rm -f "$ROOT_MOUNT/etc/systemd/system/multi-user.target.wants/fix-ssh-sudoers.service" 2>/dev/null || true
        echo "✅ fix-ssh-service deaktiviert"
    fi
    
    if [[ $REPLY == "2" || $REPLY == "3" ]]; then
        echo "🔧 Installiere korrigierte Version..."
        SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
        if [ -f "$SCRIPT_DIR/custom-components/services/fix-ssh-service.service" ]; then
            sudo cp "$SCRIPT_DIR/custom-components/services/fix-ssh-service.service" "$ROOT_MOUNT/etc/systemd/system/" 2>/dev/null || true
            sudo ln -sf /etc/systemd/system/fix-ssh-service.service "$ROOT_MOUNT/etc/systemd/system/multi-user.target.wants/fix-ssh-service.service" 2>/dev/null || true
            echo "✅ Korrigierte Version installiert (ohne moode-startup dependency)"
        else
            echo "⚠️  Korrigierte Version nicht gefunden"
        fi
    fi
    
    echo ""
    echo "📋 ssh-guaranteed.service bleibt aktiv (sollte ausreichen)"
    echo ""
    echo "✅ Fertig! SD-Karte kann jetzt wieder verwendet werden."
else
    echo "❌ Abgebrochen."
fi

echo ""
echo "📋 Nächste Schritte:"
echo "   1. SD-Karte auswerfen: diskutil eject /dev/$SD_DEVICE"
echo "   2. SD-Karte in Pi einstecken"
echo "   3. Pi booten"
echo ""

