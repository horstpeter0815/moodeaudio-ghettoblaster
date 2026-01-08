#!/bin/bash
# Fix NetworkManager Wait Failure - Complete Fix
# Behebt Konflikt + korrigiert IP-Adresse

set -e

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  🔧 FIX NETWORKMANAGER - COMPLETE FIX                       ║"
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

# Fix 2: IP-Adresse korrigieren: 192.168.178.162 → 192.168.10.2
echo "🔧 Fix 2: IP-Adresse korrigieren (192.168.178.162 → 192.168.10.2)"
sudo sed -i '' 's/192\.168\.178\.162/192.168.10.2/g' "$NETWORK_FILE" 2>/dev/null || {
    echo "⚠️  IP-Fix benötigt sudo"
    exit 1
}
echo "✅ IP-Adresse korrigiert"
echo ""

# Fix 3: Gateway korrigieren: 192.168.178.1 → 192.168.10.1
echo "🔧 Fix 3: Gateway korrigieren (192.168.178.1 → 192.168.10.1)"
sudo sed -i '' 's/192\.168\.178\.1/192.168.10.1/g' "$NETWORK_FILE" 2>/dev/null || {
    echo "⚠️  Gateway-Fix benötigt sudo"
    exit 1
}
echo "✅ Gateway korrigiert"
echo ""

# Fix 4: Layer 3 - systemd-networkd deaktivieren wenn NetworkManager aktiv
echo "🔧 Fix 4: Layer 3 - systemd-networkd deaktivieren wenn NetworkManager aktiv"
# Ersetze die problematische Zeile
sudo sed -i '' 's/systemctl restart systemd-networkd 2>\/dev\/null || true/if systemctl is-active NetworkManager >\/dev\/null 2>&1; then\
        systemctl stop systemd-networkd 2>\/dev\/null || true\
        systemctl disable systemd-networkd 2>\/dev\/null || true\
        echo "✅ systemd-networkd deaktiviert (NetworkManager aktiv)"\
    else\
        systemctl restart systemd-networkd 2>\/dev\/null || true\
    fi/' "$NETWORK_FILE" 2>/dev/null || {
    echo "⚠️  Layer 3 Fix benötigt manuelle Bearbeitung"
    echo "   Bitte öffne die Datei und ändere Layer 3 manuell:"
    echo "   Ersetze: systemctl restart systemd-networkd"
    echo "   Mit: if systemctl is-active NetworkManager; then systemctl stop systemd-networkd; systemctl disable systemd-networkd; else systemctl restart systemd-networkd; fi"
}

echo "✅ Fix angewendet!"
echo ""

# Zeige neue Konfiguration
echo "📋 Neue Konfiguration:"
echo "   Netplan renderer:"
grep -A 2 "renderer:" "$NETWORK_FILE" | head -3
echo ""
echo "   IP-Adresse:"
grep "192.168.10" "$NETWORK_FILE" | head -3
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

