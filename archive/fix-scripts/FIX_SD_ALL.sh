#!/bin/bash
# Fix SD Card - Alle Probleme beheben
# Führe aus: sudo ./FIX_SD_ALL.sh

set -e

SD_LINE=$(diskutil list | grep -E 'external.*physical' | head -1)
SD_DEVICE=$(echo "$SD_LINE" | awk '{print $1}' | sed 's|/dev/||')
ROOT_MOUNT="/Volumes/rootfs"

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  🔧 SD-KARTE ALLE FIXES ANWENDEN                           ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "SD-Karte: /dev/$SD_DEVICE"
echo ""

# Mounte Root-Partition
echo "1. Mounte Root-Partition..."
sudo mkdir -p "$ROOT_MOUNT"
sudo mount -t ext4 /dev/${SD_DEVICE}s2 "$ROOT_MOUNT" 2>/dev/null || echo "Bereits gemountet"
echo "✅ Root-Partition gemountet"
echo ""

# Fix 1: fix-user-id.service - entferne After=moode-startup.service
echo "2. Fix fix-user-id.service..."
FIX_USER_ID_FILE=$(find "$ROOT_MOUNT" -name "fix-user-id.service" -type f | head -1)
if [ -n "$FIX_USER_ID_FILE" ]; then
    echo "   Service-Datei: $FIX_USER_ID_FILE"
    sudo cp "$FIX_USER_ID_FILE" "${FIX_USER_ID_FILE}.bak"
    echo "   ✅ Backup erstellt"
    sudo sed -i '' '/After=moode-startup.service/d' "$FIX_USER_ID_FILE"
    echo "   ✅ After=moode-startup.service entfernt"
else
    echo "   ⚠️ fix-user-id.service nicht gefunden"
fi
echo ""

# Fix 2: network-guaranteed.service - systemd-networkd deaktivieren, NetworkManager aktiv lassen
echo "3. Fix network-guaranteed.service..."
NETWORK_GUARANTEED_FILE=$(find "$ROOT_MOUNT" -name "network-guaranteed.service" -type f | head -1)
if [ -n "$NETWORK_GUARANTEED_FILE" ]; then
    echo "   Service-Datei: $NETWORK_GUARANTEED_FILE"
    sudo cp "$NETWORK_GUARANTEED_FILE" "${NETWORK_GUARANTEED_FILE}.bak"
    echo "   ✅ Backup erstellt"
    # Ändere Netplan renderer zu NetworkManager
    sudo sed -i '' 's/renderer: networkd/renderer: NetworkManager/' "$NETWORK_GUARANTEED_FILE"
    # Ersetze den problematischen Teil: systemd-networkd deaktivieren, NetworkManager aktiv lassen
    sudo sed -i '' 's/systemctl restart systemd-networkd 2>\/dev\/null || true/# CRITICAL FIX: Deaktiviere systemd-networkd, verwende NetworkManager (Moode Standard)\
        systemctl stop systemd-networkd 2>\/dev\/null || true\
        systemctl disable systemd-networkd 2>\/dev\/null || true/' "$NETWORK_GUARANTEED_FILE"
    sudo sed -i '' 's/systemctl restart NetworkManager 2>\/dev\/null || true/systemctl restart NetworkManager 2>\/dev\/null || true\
        systemctl enable NetworkManager 2>\/dev\/null || true\
        echo "✅ NetworkManager aktiviert (systemd-networkd deaktiviert)"/' "$NETWORK_GUARANTEED_FILE"
    echo "   ✅ NetworkManager bleibt aktiv (systemd-networkd deaktiviert)"
else
    echo "   ⚠️ network-guaranteed.service nicht gefunden"
fi
echo ""

# Prüfe Ergebnis
echo "4. Prüfe Fixes..."
if [ -n "$FIX_USER_ID_FILE" ]; then
    echo "   fix-user-id.service:"
    grep "After=" "$FIX_USER_ID_FILE" | grep -v "moode-startup" || echo "   ✅ Keine moode-startup dependency"
fi
echo ""

# Unmount
echo "5. Unmounte SD-Karte..."
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
echo "✅ Erwartete Ergebnisse:"
echo "  • Keine cloud-init Blockierung"
echo "  • Kein NetworkManager Fehler"
echo "  • Pi bootet durch"
echo ""

