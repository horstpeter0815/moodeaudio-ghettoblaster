#!/bin/bash
# Restore Original Network Configuration
# Stellt den ursprünglichen funktionierenden Zustand wieder her

set -e

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  🔄 RESTORE ORIGINAL NETWORK CONFIGURATION                  ║"
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
sudo cp "$NETWORK_FILE" "${NETWORK_FILE}.bak2" 2>/dev/null || echo "⚠️  Backup benötigt sudo"

# Restore 1: renderer: NetworkManager → renderer: networkd
echo "🔧 Restore 1: renderer: NetworkManager → renderer: networkd"
sudo sed -i '' 's/renderer: NetworkManager/renderer: networkd/' "$NETWORK_FILE" 2>/dev/null || {
    echo "⚠️  Restore benötigt sudo - bitte manuell ausführen:"
    echo "sudo sed -i '' 's/renderer: NetworkManager/renderer: networkd/' \"$NETWORK_FILE\""
    exit 1
}
echo "✅ renderer auf networkd zurückgesetzt"
echo ""

# Restore 2: IP-Adresse: 192.168.10.2 → 192.168.178.162
echo "🔧 Restore 2: IP-Adresse: 192.168.10.2 → 192.168.178.162"
sudo sed -i '' 's/192\.168\.10\.2/192.168.178.162/g' "$NETWORK_FILE" 2>/dev/null || {
    echo "⚠️  IP-Restore benötigt sudo"
    exit 1
}
echo "✅ IP-Adresse zurückgesetzt"
echo ""

# Restore 3: Gateway: 192.168.10.1 → 192.168.178.1
echo "🔧 Restore 3: Gateway: 192.168.10.1 → 192.168.178.1"
sudo sed -i '' 's/192\.168\.10\.1/192.168.178.1/g' "$NETWORK_FILE" 2>/dev/null || {
    echo "⚠️  Gateway-Restore benötigt sudo"
    exit 1
}
echo "✅ Gateway zurückgesetzt"
echo ""

# Restore 4: Layer 3 - Zurück zu beiden Services aktiv
echo "🔧 Restore 4: Layer 3 - systemd-networkd UND NetworkManager beide aktiv"
# Ersetze den komplexen if-Statement zurück zu einfachem restart
sudo sed -i '' '/Layer 3: Network Services neu starten/,/systemctl restart NetworkManager/s/if systemctl is-active NetworkManager >\/dev\/null 2>&1; then\
        systemctl stop systemd-networkd 2>\/dev\/null || true\
        systemctl disable systemd-networkd 2>\/dev\/null || true\
        echo "✅ systemd-networkd deaktiviert (NetworkManager aktiv)"\
    else\
        systemctl restart systemd-networkd 2>\/dev\/null || true\
    fi/systemctl restart systemd-networkd 2>\/dev\/null || true/' "$NETWORK_FILE" 2>/dev/null || {
    echo "⚠️  Layer 3 Restore benötigt manuelle Bearbeitung"
    echo "   Bitte öffne die Datei und ändere Layer 3 zurück zu:"
    echo "   systemctl restart systemd-networkd 2>/dev/null || true"
    echo "   systemctl restart NetworkManager 2>/dev/null || true"
}

echo "✅ Restore angewendet!"
echo ""

# Zeige neue Konfiguration
echo "📋 Neue Konfiguration (ursprünglich funktionierend):"
echo "   Netplan renderer:"
grep -A 2 "renderer:" "$NETWORK_FILE" | head -3
echo ""
echo "   IP-Adresse:"
grep "192.168.178" "$NETWORK_FILE" | head -3
echo ""
echo "   Layer 3:"
grep -A 3 "Layer 3" "$NETWORK_FILE" | head -4
echo ""

echo "✅ Fertig - Zurück zum ursprünglichen funktionierenden Zustand!"
echo ""
echo "📋 Zum Unmounten:"
echo "   sudo umount $ROOT_MOUNT"
echo "   diskutil eject /dev/\$(diskutil list | grep -E 'external.*physical' | head -1 | awk '{print \$NF}')"
echo ""

