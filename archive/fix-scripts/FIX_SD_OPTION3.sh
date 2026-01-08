#!/bin/bash
# Quick Fix Script - Option 3: Deaktiviere fix-ssh-service UND installiere korrigierte Version

set -e

echo "🔧 Option 3: Beides..."
echo ""

# Mounte Root-Partition
echo "1. Mounte Root-Partition..."
sudo mkdir -p /Volumes/rootfs
sudo mount -t ext4 /dev/disk4s2 /Volumes/rootfs 2>/dev/null || echo "Root-Partition bereits gemountet"

ROOT_MOUNT="/Volumes/rootfs"
# Get absolute path to script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Fallback to current directory if script is run with relative path
if [ ! -f "$SCRIPT_DIR/custom-components/services/fix-ssh-service.service" ]; then
    SCRIPT_DIR="/Users/andrevollmer/moodeaudio-cursor"
fi

# Deaktiviere alten fix-ssh-service
echo ""
echo "2. Deaktiviere alten fix-ssh-service..."
sudo rm -f "$ROOT_MOUNT/etc/systemd/system/multi-user.target.wants/fix-ssh-service.service"
echo "✅ fix-ssh-service deaktiviert"

# Installiere korrigierte Version
echo ""
echo "3. Installiere korrigierte Version..."
sudo cp "$SCRIPT_DIR/custom-components/services/fix-ssh-service.service" "$ROOT_MOUNT/etc/systemd/system/"
sudo ln -sf /etc/systemd/system/fix-ssh-service.service "$ROOT_MOUNT/etc/systemd/system/multi-user.target.wants/fix-ssh-service.service"
echo "✅ Korrigierte Version installiert"

# Prüfe Installation
echo ""
echo "4. Prüfe Installation..."
sudo cat "$ROOT_MOUNT/etc/systemd/system/fix-ssh-service.service" | grep -E "After=|Description=" | head -3

echo ""
echo "✅ Fertig!"
echo ""
echo "📋 Nächste Schritte:"
echo "  sudo umount /Volumes/rootfs"
echo "  diskutil eject /dev/disk4"
echo ""

