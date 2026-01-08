#!/bin/bash
# Fix NetworkManager Wait Failure
# Behebt den Konflikt zwischen systemd-networkd und NetworkManager

set -e

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  🔧 FIX NETWORKMANAGER WAIT FAILURE                        ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Finde Root-Partition
ROOT_MOUNT=""
if mount | grep -q "rootfs"; then
    ROOT_MOUNT=$(mount | grep rootfs | awk '{print $3}' | head -1)
else
    echo "❌ Root-Partition nicht gemountet!"
    echo "   Bitte SD-Karte einstecken und mounten:"
    echo "   SD_DEVICE=\$(diskutil list | grep -E 'external.*physical' | head -1 | awk '{print \$NF}')"
    echo "   sudo mkdir -p /Volumes/rootfs"
    echo "   sudo mount -t ext4 /dev/\${SD_DEVICE}s2 /Volumes/rootfs"
    exit 1
fi

echo "✅ Root-Partition: $ROOT_MOUNT"
echo ""

# Finde network-guaranteed.service
NETWORK_FILE=$(find "$ROOT_MOUNT" -name "network-guaranteed.service" -type f | head -1)

if [ -z "$NETWORK_FILE" ]; then
    echo "❌ network-guaranteed.service nicht gefunden!"
    exit 1
fi

echo "✅ network-guaranteed.service gefunden: $NETWORK_FILE"
echo ""

# Backup erstellen
echo "📋 Erstelle Backup..."
sudo cp "$NETWORK_FILE" "${NETWORK_FILE}.bak" 2>/dev/null || echo "⚠️  Backup benötigt sudo"

# Fix 1: renderer: networkd → renderer: NetworkManager
echo "🔧 Fix 1: renderer: networkd → renderer: NetworkManager"
sudo sed -i '' 's/renderer: networkd/renderer: NetworkManager/' "$NETWORK_FILE" 2>/dev/null || {
    echo "⚠️  Fix benötigt sudo - bitte manuell ausführen:"
    echo "sudo sed -i '' 's/renderer: networkd/renderer: NetworkManager/' \"$NETWORK_FILE\""
    exit 1
}
echo "✅ renderer auf NetworkManager gesetzt"
echo ""

# Fix 2: Layer 3 - systemd-networkd deaktivieren wenn NetworkManager aktiv
echo "🔧 Fix 2: Layer 3 - systemd-networkd deaktivieren wenn NetworkManager aktiv"
# Ersetze den problematischen Teil
sudo sed -i '' '/Layer 3: Network Services neu starten/,/systemctl restart NetworkManager/s/systemctl restart systemd-networkd 2>\/dev\/null || true/# CRITICAL FIX: Deaktiviere systemd-networkd if NetworkManager is active\
    if systemctl is-active NetworkManager >\/dev\/null 2>&1; then\
        systemctl stop systemd-networkd 2>\/dev\/null || true\
        systemctl disable systemd-networkd 2>\/dev\/null || true\
        echo "✅ systemd-networkd deaktiviert (NetworkManager aktiv)"\
    else\
        systemctl restart systemd-networkd 2>\/dev\/null || true\
    fi/' "$NETWORK_FILE" 2>/dev/null || {
    echo "⚠️  Komplexer Fix benötigt manuelle Bearbeitung"
    echo "   Bitte öffne die Datei und ändere Layer 3 manuell"
}

echo "✅ Fix angewendet!"
echo ""

# Zeige neue Konfiguration
echo "📋 Neue Konfiguration:"
echo "   Netplan renderer:"
grep -A 2 "renderer:" "$NETWORK_FILE" | head -3
echo ""
echo "   Layer 3:"
grep -A 8 "Layer 3" "$NETWORK_FILE" | head -9
echo ""

echo "✅ Fertig!"
echo ""
echo "📋 Zum Unmounten:"
echo "   sudo umount $ROOT_MOUNT"
echo "   diskutil eject /dev/\$(diskutil list | grep -E 'external.*physical' | head -1 | awk '{print \$NF}')"
echo ""

