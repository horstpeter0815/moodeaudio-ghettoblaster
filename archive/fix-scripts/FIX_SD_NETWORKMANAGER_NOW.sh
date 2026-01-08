#!/bin/bash
# Fix NetworkManager-wait-online Problem on SD Card
# Behebt Netplan renderer Konflikt und IP-Adresse

set -e

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  🔧 FIX NETWORKMANAGER-WAIT-ONLINE (SD-KARTE)              ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Finde SD-Karte
SD_LINE=$(diskutil list | grep -E 'external.*physical' | head -1)
if [ -z "$SD_LINE" ]; then
    echo "❌ Keine SD-Karte gefunden!"
    exit 1
fi

SD_DEVICE=$(echo "$SD_LINE" | awk '{print $1}' | sed 's|/dev/||')
ROOT_MOUNT="/Volumes/rootfs"

echo "✅ SD-Karte: /dev/$SD_DEVICE"
echo ""

# Mounte Root-Partition
echo "1. Mounte Root-Partition..."
sudo mkdir -p "$ROOT_MOUNT"
sudo mount -t ext4 /dev/${SD_DEVICE}s2 "$ROOT_MOUNT" 2>/dev/null || echo "Bereits gemountet"
echo "✅ Root-Partition gemountet"
echo ""

# Finde network-guaranteed.service
NETWORK_GUARANTEED_FILE=$(find "$ROOT_MOUNT" -name "network-guaranteed.service" -type f | head -1)
if [ -z "$NETWORK_GUARANTEED_FILE" ]; then
    echo "❌ network-guaranteed.service nicht gefunden!"
    exit 1
fi

echo "2. Fix network-guaranteed.service..."
echo "   Datei: $NETWORK_GUARANTEED_FILE"
sudo cp "$NETWORK_GUARANTEED_FILE" "${NETWORK_GUARANTEED_FILE}.bak"
echo "   ✅ Backup erstellt"
echo ""

# Fix 1: Netplan renderer auf NetworkManager setzen
echo "3. Fix Netplan renderer: networkd → NetworkManager..."
sudo sed -i '' 's/renderer: networkd/renderer: NetworkManager/' "$NETWORK_GUARANTEED_FILE"
echo "   ✅ Netplan renderer auf NetworkManager gesetzt"
echo ""

# Fix 2: IP-Adresse korrigieren
echo "4. Fix IP-Adresse: 192.168.178.162 → 192.168.10.2..."
sudo sed -i '' 's/192\.168\.178\.162/192.168.10.2/g' "$NETWORK_GUARANTEED_FILE"
sudo sed -i '' 's/192\.168\.178\.1/192.168.10.1/g' "$NETWORK_GUARANTEED_FILE"
echo "   ✅ IP-Adresse korrigiert"
echo ""

# Fix 3: Entferne redundante/verwirrende Logik in Layer 3 (Zeilen 61-82)
echo "5. Fix redundante Logik in Layer 3..."
# Erstelle temporäre Datei mit korrigierter Logik
TEMP_FILE=$(mktemp)
# Kopiere alles bis Zeile 60
head -60 "$NETWORK_GUARANTEED_FILE" > "$TEMP_FILE"
# Füge vereinfachte Layer 3 Logik hinzu
cat >> "$TEMP_FILE" << 'LAYER3_EOF'
    # Layer 3: Network Services - NetworkManager aktivieren, systemd-networkd deaktivieren
    # CRITICAL FIX: Moode verwendet NetworkManager, daher systemd-networkd IMMER deaktivieren
    systemctl stop systemd-networkd 2>/dev/null || true
    systemctl disable systemd-networkd 2>/dev/null || true
    systemctl restart NetworkManager 2>/dev/null || true
    systemctl enable NetworkManager 2>/dev/null || true
    echo "✅ NetworkManager aktiviert (systemd-networkd deaktiviert)"
LAYER3_EOF
# Füge Rest der Datei ab Zeile 83 hinzu
tail -n +83 "$NETWORK_GUARANTEED_FILE" >> "$TEMP_FILE"
# Ersetze Original
sudo cp "$TEMP_FILE" "$NETWORK_GUARANTEED_FILE"
rm "$TEMP_FILE"
echo "   ✅ Redundante Logik entfernt, vereinfachte Version aktiviert"
echo ""

# Fix 4: NetworkManager explizit aktivieren
echo "6. NetworkManager explizit aktivieren..."
# Stelle sicher dass NetworkManager enabled wird
if ! grep -q "systemctl enable NetworkManager" "$NETWORK_GUARANTEED_FILE"; then
    sudo sed -i '' 's/systemctl restart NetworkManager 2>\/dev\/null || true/systemctl restart NetworkManager 2>\/dev\/null || true\
        systemctl enable NetworkManager 2>\/dev\/null || true/' "$NETWORK_GUARANTEED_FILE"
fi
echo "   ✅ NetworkManager enable hinzugefügt"
echo ""

# Verifikation
echo "7. Verifikation..."
echo "   Netplan renderer:"
grep "renderer:" "$NETWORK_GUARANTEED_FILE" | head -1
echo "   IP-Adressen:"
grep "192\.168\." "$NETWORK_GUARANTEED_FILE" | head -3
echo ""

# Unmount
echo "8. Unmounte SD-Karte..."
sudo umount "$ROOT_MOUNT" || true
echo "✅ SD-Karte unmounted"
echo ""

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  ✅ NETWORKMANAGER FIX ANGEWENDET                          ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "📋 Nächste Schritte:"
echo "  1. diskutil eject /dev/$SD_DEVICE"
echo "  2. SD-Karte in Pi einstecken"
echo "  3. Pi booten"
echo "  4. NetworkManager-wait-online sollte jetzt funktionieren"
echo ""

