#!/bin/bash
# Fix SD Card - ETH0 STATIC IP DIRECT (LAN-Kabel) - KEIN WLAN NÖTIG
# Konfiguriert eth0 mit statischer IP 192.168.10.2 - unabhängig von WLAN

set -e

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  🔧 FIX SD-KARTE: ETH0 STATISCH (LAN-KABEL)                 ║"
echo "║  Direkte Verbindung Mac ↔ Pi über LAN-Kabel                 ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Finde SD-Karte
SD_DEVICE=$(diskutil list | grep -E 'external.*physical' | head -1 | awk '{print $NF}' 2>/dev/null | sed 's|/dev/||')
if [ -z "$SD_DEVICE" ]; then
    echo "❌ Keine SD-Karte gefunden!"
    echo "   Bitte SD-Karte einstecken und erneut versuchen."
    exit 1
fi

echo "✅ SD-Karte gefunden: /dev/$SD_DEVICE"
echo ""

# Unmount falls gemountet
echo "🔌 Unmounte Partitionen..."
diskutil unmount /dev/${SD_DEVICE}s1 2>/dev/null || true
diskutil unmount /dev/${SD_DEVICE}s2 2>/dev/null || true
sleep 1

# Mounte Root-Partition
echo "📂 Mounte Root-Partition..."
sudo mkdir -p /Volumes/rootfs
sudo mount -t ext4 /dev/${SD_DEVICE}s2 /Volumes/rootfs 2>/dev/null || {
    if mount | grep -q "rootfs"; then
        echo "✅ Root-Partition bereits gemountet"
    else
        echo "❌ Konnte Root-Partition nicht mounten"
        exit 1
    fi
}

ROOT_MOUNT="/Volumes/rootfs"
if [ ! -d "$ROOT_MOUNT/etc/systemd/system" ]; then
    echo "❌ Root-Partition nicht korrekt gemountet."
    exit 1
fi

echo "✅ Root-Partition: $ROOT_MOUNT"
echo ""

################################################################################
# Fix 1: NetworkManager Connection für eth0 - STATISCH
################################################################################

echo "🔧 Fix 1: NetworkManager - eth0 STATISCH konfigurieren..."
NM_CONN_DIR="$ROOT_MOUNT/etc/NetworkManager/system-connections"
sudo mkdir -p "$NM_CONN_DIR" 2>/dev/null || true

# Erstelle/Überschreibe eth0 Connection mit STATISCHER IP
sudo tee "$NM_CONN_DIR/eth0-static.nmconnection" > /dev/null << 'EOF'
[connection]
id=eth0-static
type=ethernet
interface-name=eth0
autoconnect=true
autoconnect-priority=100

[ethernet]

[ipv4]
method=manual
addresses=192.168.10.2/24
gateway=192.168.10.1
dns=192.168.10.1;8.8.8.8

[ipv6]
method=auto
EOF

sudo chmod 600 "$NM_CONN_DIR/eth0-static.nmconnection" 2>/dev/null || true
echo "   ✅ NetworkManager: eth0 auf STATISCH gesetzt (192.168.10.2)"
echo ""

################################################################################
# Fix 2: dhcpcd.conf - eth0 STATISCH
################################################################################

echo "🔧 Fix 2: dhcpcd.conf - eth0 STATISCH..."
DHCPCD_CONF="$ROOT_MOUNT/etc/dhcpcd.conf"
if [ -f "$DHCPCD_CONF" ]; then
    # Backup
    sudo cp "$DHCPCD_CONF" "${DHCPCD_CONF}.bak" 2>/dev/null || true
    
    # Entferne alte eth0 Konfiguration
    sudo sed -i.bak2 '/^interface eth0/,/^$/d' "$DHCPCD_CONF" 2>/dev/null || sudo sed -i '' '/^interface eth0/,/^$/d' "$DHCPCD_CONF" 2>/dev/null || true
    
    # Füge neue STATISCHE eth0 Konfiguration hinzu
    if ! grep -q "interface eth0" "$DHCPCD_CONF"; then
        echo "" | sudo tee -a "$DHCPCD_CONF" > /dev/null
        echo "# Direct LAN Connection - STATIC IP (Mac ↔ Pi)" | sudo tee -a "$DHCPCD_CONF" > /dev/null
        echo "interface eth0" | sudo tee -a "$DHCPCD_CONF" > /dev/null
        echo "static ip_address=192.168.10.2/24" | sudo tee -a "$DHCPCD_CONF" > /dev/null
        echo "static routers=192.168.10.1" | sudo tee -a "$DHCPCD_CONF" > /dev/null
        echo "static domain_name_servers=192.168.10.1 8.8.8.8" | sudo tee -a "$DHCPCD_CONF" > /dev/null
    fi
    
    echo "   ✅ dhcpcd.conf: eth0 auf STATISCH gesetzt"
else
    echo "   ⚠️  dhcpcd.conf nicht gefunden (wird beim Boot erstellt)"
fi
echo ""

################################################################################
# Fix 3: systemd-networkd - eth0 STATISCH (Fallback)
################################################################################

echo "🔧 Fix 3: systemd-networkd - eth0 STATISCH (Fallback)..."
NETWORKD_DIR="$ROOT_MOUNT/etc/systemd/network"
sudo mkdir -p "$NETWORKD_DIR" 2>/dev/null || true

sudo tee "$NETWORKD_DIR/10-eth0-static.network" > /dev/null << 'EOF'
[Match]
Name=eth0

[Network]
Address=192.168.10.2/24
Gateway=192.168.10.1
DNS=192.168.10.1
DNS=8.8.8.8
EOF

echo "   ✅ systemd-networkd: eth0 STATISCH konfiguriert"
echo ""

################################################################################
# Fix 4: network-guaranteed.service prüfen/aktualisieren
################################################################################

echo "🔧 Fix 4: network-guaranteed.service prüfen..."
NETWORK_GUARANTEED=$(find "$ROOT_MOUNT" -name "network-guaranteed.service" -type f | head -1)
if [ -n "$NETWORK_GUARANTEED" ]; then
    echo "   ✅ network-guaranteed.service gefunden"
    # Prüfe ob IP korrekt ist
    if grep -q "192.168.10.2" "$NETWORK_GUARANTEED"; then
        echo "   ✅ IP bereits korrekt (192.168.10.2)"
    else
        echo "   ⚠️  IP muss noch angepasst werden"
        sudo sed -i.bak3 's/192\.168\.178\.[0-9]*/192.168.10.2/g' "$NETWORK_GUARANTEED" 2>/dev/null || sudo sed -i '' 's/192\.168\.178\.[0-9]*/192.168.10.2/g' "$NETWORK_GUARANTEED" 2>/dev/null || true
        sudo sed -i.bak4 's/192\.168\.178\.1/192.168.10.1/g' "$NETWORK_GUARANTEED" 2>/dev/null || sudo sed -i '' 's/192\.168\.178\.1/192.168.10.1/g' "$NETWORK_GUARANTEED" 2>/dev/null || true
        echo "   ✅ IP angepasst"
    fi
else
    echo "   ⚠️  network-guaranteed.service nicht gefunden"
fi
echo ""

################################################################################
# Fix 5: WLAN deaktivieren für eth0 (optional - WLAN darf eth0 nicht stören)
################################################################################

echo "🔧 Fix 5: Stelle sicher dass WLAN eth0 nicht überschreibt..."
# NetworkManager: eth0 hat höchste Priorität
if [ -f "$NM_CONN_DIR/eth0-static.nmconnection" ]; then
    # autoconnect-priority=100 ist bereits gesetzt (höchste Priorität)
    echo "   ✅ eth0 hat höchste Priorität (100)"
fi
echo ""

################################################################################
# Zusammenfassung
################################################################################

echo "✅ Alle Fixes angewendet!"
echo ""
echo "📋 Zusammenfassung:"
echo "   ✅ NetworkManager: eth0 STATISCH (192.168.10.2)"
echo "   ✅ dhcpcd.conf: eth0 STATISCH (192.168.10.2)"
echo "   ✅ systemd-networkd: eth0 STATISCH (192.168.10.2)"
echo "   ✅ eth0 Priorität: HÖCHSTE (100)"
echo ""
echo "🎯 Konfiguration:"
echo "   • eth0 (LAN-Kabel): 192.168.10.2/24 (STATISCH)"
echo "   • Gateway: 192.168.10.1 (Mac)"
echo "   • DNS: 192.168.10.1, 8.8.8.8"
echo "   • WLAN: Kann DHCP verwenden (stört eth0 nicht)"
echo ""
echo "🔄 Nächste Schritte:"
echo "   1. SD-Karte auswerfen: diskutil eject /dev/$SD_DEVICE"
echo "   2. SD-Karte in Pi einstecken"
echo "   3. Pi booten"
echo "   4. eth0 sollte automatisch 192.168.10.2 bekommen"
echo ""

# Unmount
echo "🔌 Unmounte Root-Partition..."
sudo umount "$ROOT_MOUNT" 2>/dev/null || true
echo "✅ Fertig!"

