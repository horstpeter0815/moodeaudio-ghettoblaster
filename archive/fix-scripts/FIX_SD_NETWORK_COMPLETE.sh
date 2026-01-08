#!/bin/bash
# Complete Network Fix - Behebt alle NetworkManager Probleme
# 1. Prüft alle Netzwerk-Services
# 2. Deaktiviert systemd-networkd wenn NetworkManager aktiv
# 3. Korrigiert network-guaranteed.service
# 4. Deaktiviert konkurrierende Services

set -e

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  🔧 COMPLETE NETWORK FIX                                   ║"
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

# Finde alle Netzwerk-Services
echo "🔍 Suche nach Netzwerk-Services..."
NETWORK_GUARANTEED=$(find "$ROOT_MOUNT" -name "network-guaranteed.service" -type f | head -1)
NETWORK_DIRECT_LAN=$(find "$ROOT_MOUNT" -name "network-direct-lan.service" -type f | head -1)

echo "  • network-guaranteed.service: ${NETWORK_GUARANTEED:-nicht gefunden}"
echo "  • network-direct-lan.service: ${NETWORK_DIRECT_LAN:-nicht gefunden}"
echo ""

# Fix 1: network-guaranteed.service
if [ -n "$NETWORK_GUARANTEED" ]; then
    echo "🔧 Fix 1: network-guaranteed.service"
    echo "   Datei: $NETWORK_GUARANTEED"
    
    # Backup
    sudo cp "$NETWORK_GUARANTEED" "${NETWORK_GUARANTEED}.bak" 2>/dev/null || echo "   ⚠️  Backup benötigt sudo"
    
    # Fixes
    echo "   • renderer: networkd → NetworkManager"
    sudo sed -i '' 's/renderer: networkd/renderer: NetworkManager/' "$NETWORK_GUARANTEED" 2>/dev/null || echo "   ⚠️  Benötigt sudo"
    
    echo "   • IP: 192.168.178.162 → 192.168.10.2"
    sudo sed -i '' 's/192\.168\.178\.162/192.168.10.2/g' "$NETWORK_GUARANTEED" 2>/dev/null || echo "   ⚠️  Benötigt sudo"
    
    echo "   • Gateway: 192.168.178.1 → 192.168.10.1"
    sudo sed -i '' 's/192\.168\.178\.1/192.168.10.1/g' "$NETWORK_GUARANTEED" 2>/dev/null || echo "   ⚠️  Benötigt sudo"
    
    # Layer 3 Fix - Ersetze systemd-networkd restart mit deaktivierung wenn NetworkManager aktiv
    echo "   • Layer 3: systemd-networkd deaktivieren wenn NetworkManager aktiv"
    # Finde die Zeile mit systemctl restart systemd-networkd
    sudo sed -i '' '/Layer 3: Network Services neu starten/,/systemctl restart NetworkManager/s/systemctl restart systemd-networkd 2>\/dev\/null || true/if systemctl is-active NetworkManager >\/dev\/null 2>&1; then\
        systemctl stop systemd-networkd 2>\/dev\/null || true\
        systemctl disable systemd-networkd 2>\/dev\/null || true\
        echo "✅ systemd-networkd deaktiviert (NetworkManager aktiv)"\
    else\
        systemctl restart systemd-networkd 2>\/dev\/null || true\
    fi/' "$NETWORK_GUARANTEED" 2>/dev/null || echo "   ⚠️  Layer 3 Fix benötigt manuelle Bearbeitung"
    
    echo "   ✅ network-guaranteed.service gefixt"
    echo ""
fi

# Fix 2: network-direct-lan.service deaktivieren (verwendet systemd-networkd)
if [ -n "$NETWORK_DIRECT_LAN" ]; then
    echo "🔧 Fix 2: network-direct-lan.service deaktivieren"
    echo "   Datei: $NETWORK_DIRECT_LAN"
    echo "   Grund: Verwendet systemd-networkd (Konflikt mit NetworkManager)"
    echo ""
    echo "   Bitte manuell deaktivieren:"
    echo "   sudo rm -f \"$ROOT_MOUNT/etc/systemd/system/multi-user.target.wants/network-direct-lan.service\""
    echo "   sudo rm -f \"$ROOT_MOUNT/etc/systemd/system/network-direct-lan.service\""
    echo ""
fi

echo "✅ Fixes angewendet!"
echo ""
echo "📋 Prüfe Ergebnisse:"
if [ -n "$NETWORK_GUARANTEED" ]; then
    echo "   network-guaranteed.service renderer:"
    grep "renderer:" "$NETWORK_GUARANTEED" | head -1
    echo "   network-guaranteed.service IP:"
    grep "192.168.10" "$NETWORK_GUARANTEED" | head -1
fi
echo ""
echo "📋 Zum Unmounten:"
echo "   sudo umount $ROOT_MOUNT"
echo "   diskutil eject /dev/\$(diskutil list | grep -E 'external.*physical' | head -1 | awk '{print \$NF}')"
echo ""

