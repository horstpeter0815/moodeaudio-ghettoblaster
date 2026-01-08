#!/bin/bash
# Fix Network Syntax Errors
# Korrigiert die korrupten Zeilen in network-guaranteed.service

set -e

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  🔧 FIX NETWORK SYNTAX ERRORS                               ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Finde Root-Partition
ROOT_MOUNT=""
if mount | grep -q "rootfs"; then
    ROOT_MOUNT=$(mount | grep rootfs | awk '{print $3}' | head -1)
else
    echo "❌ Root-Partition nicht gemountet!"
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
sudo cp "$NETWORK_FILE" "${NETWORK_FILE}.bak3" 2>/dev/null || echo "⚠️  Backup benötigt sudo"

# Fix 1: Zeile 61 - Korrigiere '2>    systemctl restart systemd-networkd 2>/dev/null || true1' zu '2>&1'
echo "🔧 Fix 1: Korrigiere Layer 3 Syntax-Fehler..."
sudo sed -i '' 's/>\/dev\/null 2>    systemctl restart systemd-networkd 2>\/dev\/null || true1; then/>\/dev\/null 2>\&1; then/' "$NETWORK_FILE" 2>/dev/null || {
    echo "⚠️  Fix 1 benötigt sudo - bitte manuell ausführen"
    exit 1
}

# Fix 2: Zeile 68 - Korrigiere '2>systemctl restart NetworkManager 2>/dev/null || true1' zu '2>&1'
echo "🔧 Fix 2: Korrigiere NetworkManager Syntax-Fehler..."
sudo sed -i '' 's/>\/dev\/null 2>systemctl restart NetworkManager 2>\/dev\/null || true1; then/>\/dev\/null 2>\&1; then/' "$NETWORK_FILE" 2>/dev/null || {
    echo "⚠️  Fix 2 benötigt sudo - bitte manuell ausführen"
    exit 1
}

echo "✅ Syntax-Fehler korrigiert!"
echo ""

# Prüfe ob Fix erfolgreich war
echo "📋 Prüfe korrigierte Zeilen..."
echo "Layer 3:"
grep -A 2 "Layer 3" "$NETWORK_FILE" | grep "if systemctl" | head -1
echo ""
echo "NetworkManager Check:"
grep -A 2 "CRITICAL FIX" "$NETWORK_FILE" | grep "if systemctl" | head -1
echo ""

echo "✅ Fertig!"
echo ""
echo "📋 Zum Unmounten:"
echo "   sudo umount $ROOT_MOUNT"
echo "   diskutil eject /dev/\$(diskutil list | grep -E 'external.*physical' | head -1 | awk '{print \$NF}')"
echo ""

