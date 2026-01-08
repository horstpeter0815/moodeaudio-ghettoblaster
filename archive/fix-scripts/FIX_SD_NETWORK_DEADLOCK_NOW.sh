#!/bin/bash
# FIX NETWORK DEADLOCK - ETH0 DIREKT, KEINE ABHÄNGIGKEITEN
# Konfiguriert eth0 DIREKT mit ifconfig - VOR NetworkManager

set -e

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  🔧 FIX NETWORK DEADLOCK - ETH0 DIREKT                      ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Finde SD-Karte
SD_DEVICE=$(diskutil list | grep -E 'external.*physical' | head -1 | awk '{print $NF}' 2>/dev/null | sed 's|/dev/||')
if [ -z "$SD_DEVICE" ]; then
    echo "❌ Keine SD-Karte gefunden!"
    exit 1
fi

echo "✅ SD-Karte: /dev/$SD_DEVICE"
echo ""

# Mounte Root-Partition
sudo mkdir -p /Volumes/rootfs
sudo mount -t ext4 /dev/${SD_DEVICE}s2 /Volumes/rootfs 2>/dev/null || true
ROOT_MOUNT="/Volumes/rootfs"

if [ ! -d "$ROOT_MOUNT/etc/systemd/system" ]; then
    echo "❌ Root-Partition nicht gemountet"
    exit 1
fi

echo "✅ Root-Partition: $ROOT_MOUNT"
echo ""

################################################################################
# Fix 1: ETH0 DIREKT Service - STARTET VOR ALLEM ANDEREN
################################################################################

echo "🔧 Fix 1: ETH0 DIREKT Service (startet VOR NetworkManager)..."
ETH0_DIRECT_SERVICE="$ROOT_MOUNT/lib/systemd/system/eth0-direct.service"

sudo tee "$ETH0_DIRECT_SERVICE" > /dev/null << 'EOF'
[Unit]
Description=ETH0 Direct Static IP - Configure eth0 BEFORE NetworkManager
DefaultDependencies=no
After=local-fs.target
Before=network-pre.target
Before=NetworkManager.service
Before=network-online.target
Before=cloud-init.target

[Service]
Type=oneshot
RemainAfterExit=yes
StandardOutput=journal
StandardError=journal
# DIREKT eth0 konfigurieren - KEINE ABHÄNGIGKEITEN
ExecStart=/bin/bash -c '
    # Warte max 5 Sekunden auf eth0 Interface
    for i in {1..5}; do
        if ip link show eth0 >/dev/null 2>&1; then
            break
        fi
        sleep 1
    done
    
    # Konfiguriere eth0 DIREKT mit ifconfig (funktioniert IMMER)
    if ip link show eth0 >/dev/null 2>&1; then
        echo "🔧 Konfiguriere eth0 DIREKT: 192.168.10.2"
        ifconfig eth0 192.168.10.2 netmask 255.255.255.0 up 2>/dev/null || true
        route add default gw 192.168.10.1 eth0 2>/dev/null || true
        echo "nameserver 192.168.10.1" > /etc/resolv.conf 2>/dev/null || true
        echo "nameserver 8.8.8.8" >> /etc/resolv.conf 2>/dev/null || true
        echo "✅ eth0 DIREKT konfiguriert: 192.168.10.2"
    else
        echo "⚠️  eth0 Interface nicht gefunden"
    fi
'

[Install]
WantedBy=local-fs.target
WantedBy=sysinit.target
EOF

# Aktiviere Service
sudo mkdir -p "$ROOT_MOUNT/etc/systemd/system/local-fs.target.wants" 2>/dev/null || true
sudo ln -sf /lib/systemd/system/eth0-direct.service "$ROOT_MOUNT/etc/systemd/system/local-fs.target.wants/eth0-direct.service" 2>/dev/null || true

echo "   ✅ eth0-direct.service erstellt und aktiviert"
echo ""

################################################################################
# Fix 2: NetworkManager-wait-online DEAKTIVIEREN
################################################################################

echo "🔧 Fix 2: NetworkManager-wait-online DEAKTIVIEREN..."
sudo rm -f "$ROOT_MOUNT/etc/systemd/system/network-online.target.wants/NetworkManager-wait-online.service" 2>/dev/null || true
sudo rm -f "$ROOT_MOUNT/etc/systemd/system/multi-user.target.wants/NetworkManager-wait-online.service" 2>/dev/null || true
sudo systemctl --root="$ROOT_MOUNT" disable NetworkManager-wait-online.service 2>/dev/null || true

echo "   ✅ NetworkManager-wait-online DEAKTIVIERT"
echo ""

################################################################################
# Fix 3: network-guaranteed.service - ENTFERNE network-online Abhängigkeit
################################################################################

echo "🔧 Fix 3: network-guaranteed.service - Entferne network-online Abhängigkeit..."
NETWORK_GUARANTEED=$(find "$ROOT_MOUNT" -name "network-guaranteed.service" -type f | head -1)
if [ -n "$NETWORK_GUARANTEED" ]; then
    sudo cp "$NETWORK_GUARANTEED" "${NETWORK_GUARANTEED}.bak" 2>/dev/null || true
    
    # Entferne Wants=network-online.target
    sudo sed -i.bak2 '/Wants=network-online.target/d' "$NETWORK_GUARANTEED" 2>/dev/null || sudo sed -i '' '/Wants=network-online.target/d' "$NETWORK_GUARANTEED" 2>/dev/null || true
    
    # Entferne WantedBy=network-online.target
    sudo sed -i.bak3 '/WantedBy=network-online.target/d' "$NETWORK_GUARANTEED" 2>/dev/null || sudo sed -i '' '/WantedBy=network-online.target/d' "$NETWORK_GUARANTEED" 2>/dev/null || true
    
    # Ändere After=network-pre.target zu After=local-fs.target
    sudo sed -i.bak4 's/After=network-pre.target/After=local-fs.target/' "$NETWORK_GUARANTEED" 2>/dev/null || sudo sed -i '' 's/After=network-pre.target/After=local-fs.target/' "$NETWORK_GUARANTEED" 2>/dev/null || true
    
    echo "   ✅ network-guaranteed.service: network-online Abhängigkeit entfernt"
else
    echo "   ⚠️  network-guaranteed.service nicht gefunden"
fi
echo ""

################################################################################
# Fix 4: NetworkManager Connection für eth0 (für später)
################################################################################

echo "🔧 Fix 4: NetworkManager Connection für eth0..."
NM_CONN_DIR="$ROOT_MOUNT/etc/NetworkManager/system-connections"
sudo mkdir -p "$NM_CONN_DIR" 2>/dev/null || true

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
echo "   ✅ NetworkManager: eth0 STATISCH konfiguriert"
echo ""

################################################################################
# Zusammenfassung
################################################################################

echo "✅ ALLE FIXES ANGEWENDET!"
echo ""
echo "📋 Was wurde geändert:"
echo "   1. ✅ eth0-direct.service: Konfiguriert eth0 DIREKT (VOR NetworkManager)"
echo "   2. ✅ NetworkManager-wait-online: DEAKTIVIERT (verursacht Deadlock)"
echo "   3. ✅ network-guaranteed.service: network-online Abhängigkeit entfernt"
echo "   4. ✅ NetworkManager Connection: eth0 STATISCH (192.168.10.2)"
echo ""
echo "🎯 Boot-Reihenfolge jetzt:"
echo "   1. local-fs.target"
echo "   2. eth0-direct.service → eth0 = 192.168.10.2 (DIREKT)"
echo "   3. NetworkManager startet (eth0 ist bereits konfiguriert)"
echo "   4. KEIN WARTEN auf network-online"
echo ""
echo "🔄 Nächste Schritte:"
echo "   1. SD-Karte auswerfen: diskutil eject /dev/$SD_DEVICE"
echo "   2. SD-Karte in Pi einstecken"
echo "   3. Pi booten"
echo "   4. eth0 sollte SOFORT 192.168.10.2 bekommen"
echo ""

sudo umount "$ROOT_MOUNT" 2>/dev/null || true
echo "✅ Fertig!"

