#!/bin/bash
# Aggressive Fix - Entfernt fix-ssh-service komplett und alle redundanten SSH-Services

set -e

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  🔧 AGGRESSIVE FIX - ENTFERNT ALLE PROBLEMATISCHEN SERVICES ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Mounte Root-Partition
echo "1. Mounte Root-Partition..."
sudo mkdir -p /Volumes/rootfs
sudo mount -t ext4 /dev/disk4s2 /Volumes/rootfs 2>/dev/null || echo "Root-Partition bereits gemountet"

ROOT_MOUNT="/Volumes/rootfs"

echo ""
echo "2. Entferne fix-ssh-service KOMPLETT..."
# Entferne Service-Datei
sudo rm -f "$ROOT_MOUNT/etc/systemd/system/fix-ssh-service.service"
# Entferne Symlink
sudo rm -f "$ROOT_MOUNT/etc/systemd/system/multi-user.target.wants/fix-ssh-service.service"
echo "✅ fix-ssh-service komplett entfernt"

echo ""
echo "3. Entferne fix-ssh-sudoers (redundant, ssh-guaranteed macht das auch)..."
sudo rm -f "$ROOT_MOUNT/etc/systemd/system/multi-user.target.wants/fix-ssh-sudoers.service"
echo "✅ fix-ssh-sudoers entfernt"

echo ""
echo "4. Prüfe welche SSH-Services noch aktiv sind..."
echo "Aktive SSH-Services:"
ls -la "$ROOT_MOUNT/etc/systemd/system/multi-user.target.wants" 2>/dev/null | grep -E 'ssh|fix' || echo "Keine SSH-Services gefunden"

echo ""
echo "5. Stelle sicher dass ssh-guaranteed aktiv ist..."
if [ ! -L "$ROOT_MOUNT/etc/systemd/system/multi-user.target.wants/ssh-guaranteed.service" ]; then
    echo "⚠️  ssh-guaranteed.service nicht aktiv - sollte aktiv sein!"
else
    echo "✅ ssh-guaranteed.service ist aktiv (gut!)"
fi

echo ""
echo "✅ Aggressiver Fix abgeschlossen!"
echo ""
echo "📋 Was wurde gemacht:"
echo "  • fix-ssh-service KOMPLETT entfernt (Service + Symlink)"
echo "  • fix-ssh-sudoers entfernt (redundant)"
echo "  • ssh-guaranteed.service bleibt aktiv (sollte ausreichen)"
echo ""
echo "📋 Nächste Schritte:"
echo "  sudo umount /Volumes/rootfs"
echo "  diskutil eject /dev/disk4"
echo "  SD-Karte in Pi einstecken"
echo "  Pi booten - Display sollte jetzt funktionieren!"
echo ""

