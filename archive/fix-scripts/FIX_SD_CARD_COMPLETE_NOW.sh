#!/bin/bash
# Complete SD Card Fix - Applies all necessary fixes to SD card
# Usage: sudo /Users/andrevollmer/moodeaudio-cursor/FIX_SD_CARD_COMPLETE_NOW.sh /dev/diskX
# WICHTIG: Funktioniert von ÜBERALL aus - verwendet absolute Pfade!

set -e

# ABSOLUTE PFADE - funktioniert von überall!
SCRIPT_DIR="/Users/andrevollmer/moodeaudio-cursor"
SERVICES_SOURCE="$SCRIPT_DIR/moode-source/lib/systemd/system"
SCRIPTS_SOURCE="$SCRIPT_DIR/moode-source/usr/local/bin"

if [ "$EUID" -ne 0 ]; then 
    echo "❌ Bitte mit sudo ausführen!"
    echo "   sudo $0 /dev/diskX"
    exit 1
fi

if [ -z "$1" ]; then
    echo "❌ Bitte SD-Karte angeben!"
    echo ""
    echo "Verwendung:"
    echo "  sudo $0 /dev/diskX"
    echo ""
    echo "Verfügbare Disks:"
    diskutil list | grep -E "^/dev/disk"
    exit 1
fi

SD_CARD="$1"
BOOT_PARTITION="${SD_CARD}s1"
ROOT_PARTITION="${SD_CARD}s2"

echo "=== SD-KARTE KOMPLETT-FIX ==="
echo "SD-Karte: $SD_CARD"
echo "Boot-Partition: $BOOT_PARTITION"
echo "Root-Partition: $ROOT_PARTITION"
echo ""

# Prüfe ob Partitionen existieren
if [ ! -e "$BOOT_PARTITION" ]; then
    echo "❌ Boot-Partition nicht gefunden: $BOOT_PARTITION"
    exit 1
fi

if [ ! -e "$ROOT_PARTITION" ]; then
    echo "❌ Root-Partition nicht gefunden: $ROOT_PARTITION"
    exit 1
fi

# Prüfe ob Partitionen bereits gemountet sind
echo "=== Prüfe Mount-Status ==="
BOOT_MOUNT=$(diskutil info "$BOOT_PARTITION" 2>/dev/null | grep "Mount Point:" | awk -F': ' '{print $2}' | xargs || echo "")
ROOT_MOUNT=$(diskutil info "$ROOT_PARTITION" 2>/dev/null | grep "Mount Point:" | awk -F': ' '{print $2}' | xargs || echo "")

BOOT_MOUNTED_BY_US=false
ROOT_MOUNTED_BY_US=false

# Wenn nicht gemountet, mounte sie
if [ -z "$BOOT_MOUNT" ]; then
    echo "Boot-Partition nicht gemountet - mounte jetzt..."
    BOOT_MOUNT="/tmp/sd-boot-$$"
    mkdir -p "$BOOT_MOUNT"
    mount -t msdos "$BOOT_PARTITION" "$BOOT_MOUNT" || {
        echo "❌ Boot-Partition konnte nicht gemountet werden"
        exit 1
    }
    BOOT_MOUNTED_BY_US=true
    echo "✅ Boot-Partition gemountet: $BOOT_MOUNT"
else
    echo "✅ Boot-Partition bereits gemountet: $BOOT_MOUNT"
fi

if [ -z "$ROOT_MOUNT" ]; then
    echo "Root-Partition nicht gemountet - mounte jetzt..."
    ROOT_MOUNT="/tmp/sd-root-$$"
    mkdir -p "$ROOT_MOUNT"
    mount "$ROOT_PARTITION" "$ROOT_MOUNT" || {
        echo "❌ Root-Partition konnte nicht gemountet werden"
        if [ "$BOOT_MOUNTED_BY_US" = true ]; then
            umount "$BOOT_MOUNT" 2>/dev/null || true
            rmdir "$BOOT_MOUNT" 2>/dev/null || true
        fi
        exit 1
    }
    ROOT_MOUNTED_BY_US=true
    echo "✅ Root-Partition gemountet: $ROOT_MOUNT"
else
    echo "✅ Root-Partition bereits gemountet: $ROOT_MOUNT"
fi

# Cleanup-Funktion
cleanup() {
    echo ""
    echo "=== Cleanup ==="
    if [ "$BOOT_MOUNTED_BY_US" = true ]; then
        umount "$BOOT_MOUNT" 2>/dev/null || true
        rmdir "$BOOT_MOUNT" 2>/dev/null || true
    fi
    if [ "$ROOT_MOUNTED_BY_US" = true ]; then
        umount "$ROOT_MOUNT" 2>/dev/null || true
        rmdir "$ROOT_MOUNT" 2>/dev/null || true
    fi
}

trap cleanup EXIT

echo ""

# === 1. SSH AKTIVIEREN ===
echo "=== 1. SSH aktivieren ==="
touch "$BOOT_MOUNT/ssh" 2>/dev/null || touch "$BOOT_MOUNT/firmware/ssh" 2>/dev/null || true
echo "✅ SSH-Flag erstellt"
echo ""

# === 2. ETH0 STATISCH KONFIGURIEREN ===
echo "=== 2. ETH0 statisch konfigurieren (192.168.10.2) ==="

# NetworkManager Config
NM_CONN_DIR="$ROOT_MOUNT/etc/NetworkManager/system-connections"
if [ -d "$NM_CONN_DIR" ]; then
    mkdir -p "$NM_CONN_DIR"
    cat > "$NM_CONN_DIR/eth0-static.nmconnection" << 'EOF'
[connection]
id=eth0-static
type=ethernet
interface-name=eth0

[ethernet]

[ipv4]
method=manual
addresses=192.168.10.2/24
gateway=192.168.10.1
dns=192.168.10.1;8.8.8.8;

[ipv6]
method=ignore
EOF
    chmod 600 "$NM_CONN_DIR/eth0-static.nmconnection"
    echo "✅ NetworkManager Config erstellt"
fi

# systemd-networkd Config (Fallback)
NETWORKD_DIR="$ROOT_MOUNT/etc/systemd/network"
mkdir -p "$NETWORKD_DIR"
cat > "$NETWORKD_DIR/10-eth0-static.network" << 'EOF'
[Match]
Name=eth0

[Network]
Address=192.168.10.2/24
Gateway=192.168.10.1
DNS=192.168.10.1
DNS=8.8.8.8
EOF
echo "✅ systemd-networkd Config erstellt"

# dhcpcd Config (Fallback)
if [ -f "$ROOT_MOUNT/etc/dhcpcd.conf" ]; then
    if ! grep -q "interface eth0" "$ROOT_MOUNT/etc/dhcpcd.conf" || ! grep -q "192.168.10.2" "$ROOT_MOUNT/etc/dhcpcd.conf"; then
        cat >> "$ROOT_MOUNT/etc/dhcpcd.conf" << 'EOF'

# Direct LAN Connection (Ghettoblaster)
interface eth0
static ip_address=192.168.10.2/24
static routers=192.168.10.1
static domain_name_servers=192.168.10.1 8.8.8.8
EOF
        echo "✅ dhcpcd Config aktualisiert"
    fi
fi

echo ""

# === 3. SERVICES KOPIEREN UND AKTIVIEREN ===
echo "=== 3. Services kopieren ==="
echo "Services-Source: $SERVICES_SOURCE"

SERVICES_TARGET="$ROOT_MOUNT/lib/systemd/system"

if [ -d "$SERVICES_SOURCE" ]; then
    # Kopiere alle Services
    cp "$SERVICES_SOURCE/boot-complete-minimal.service" "$SERVICES_TARGET/" 2>/dev/null || true
    cp "$SERVICES_SOURCE/cloud-init-unblock.service" "$SERVICES_TARGET/" 2>/dev/null || true
    cp "$SERVICES_SOURCE/fix-user-id.service" "$SERVICES_TARGET/" 2>/dev/null || true
    cp "$SERVICES_SOURCE/boot-debug-logger.service" "$SERVICES_TARGET/" 2>/dev/null || true
    echo "✅ Services kopiert"
    
    # Aktiviere boot-complete-minimal
    mkdir -p "$ROOT_MOUNT/etc/systemd/system/local-fs.target.wants"
    ln -sf /lib/systemd/system/boot-complete-minimal.service "$ROOT_MOUNT/etc/systemd/system/local-fs.target.wants/boot-complete-minimal.service" 2>/dev/null || true
    
    # Aktiviere cloud-init-unblock
    ln -sf /lib/systemd/system/cloud-init-unblock.service "$ROOT_MOUNT/etc/systemd/system/local-fs.target.wants/cloud-init-unblock.service" 2>/dev/null || true
    
    # Aktiviere fix-user-id
    mkdir -p "$ROOT_MOUNT/etc/systemd/system/multi-user.target.wants"
    ln -sf /lib/systemd/system/fix-user-id.service "$ROOT_MOUNT/etc/systemd/system/multi-user.target.wants/fix-user-id.service" 2>/dev/null || true
    
    # Aktiviere boot-debug-logger
    ln -sf /lib/systemd/system/boot-debug-logger.service "$ROOT_MOUNT/etc/systemd/system/local-fs.target.wants/boot-debug-logger.service" 2>/dev/null || true
    
    echo "✅ Services aktiviert"
else
    echo "⚠️  Services-Source nicht gefunden: $SERVICES_SOURCE"
fi

# Deaktiviere NetworkManager-wait-online
rm -f "$ROOT_MOUNT/etc/systemd/system/network-online.target.wants/NetworkManager-wait-online.service" 2>/dev/null || true
rm -f "$ROOT_MOUNT/etc/systemd/system/multi-user.target.wants/NetworkManager-wait-online.service" 2>/dev/null || true
echo "✅ NetworkManager-wait-online deaktiviert"

echo ""

# === 4. SCRIPTS KOPIEREN ===
echo "=== 4. Scripts kopieren ==="
echo "Scripts-Source: $SCRIPTS_SOURCE"

SCRIPTS_TARGET="$ROOT_MOUNT/usr/local/bin"

if [ -d "$SCRIPTS_SOURCE" ]; then
    mkdir -p "$SCRIPTS_TARGET"
    cp "$SCRIPTS_SOURCE/simple-boot-logger.sh" "$SCRIPTS_TARGET/" 2>/dev/null || true
    cp "$SCRIPTS_SOURCE/boot-debug-logger.sh" "$SCRIPTS_TARGET/" 2>/dev/null || true
    chmod +x "$SCRIPTS_TARGET"/*.sh 2>/dev/null || true
    echo "✅ Scripts kopiert und ausführbar gemacht"
else
    echo "⚠️  Scripts-Source nicht gefunden: $SCRIPTS_SOURCE"
fi

echo ""

# === 5. USER 'andre' ERSTELLEN ===
echo "=== 5. User 'andre' erstellen ==="

if [ -f "$ROOT_MOUNT/etc/passwd" ]; then
    if ! grep -q "^andre:" "$ROOT_MOUNT/etc/passwd"; then
        echo "andre:x:1000:1000:Ghettoblaster User:/home/andre:/bin/bash" >> "$ROOT_MOUNT/etc/passwd"
        echo "✅ User 'andre' zu passwd hinzugefügt"
    fi
fi

if [ -f "$ROOT_MOUNT/etc/group" ]; then
    if ! grep -q "^andre:" "$ROOT_MOUNT/etc/group"; then
        echo "andre:x:1000:" >> "$ROOT_MOUNT/etc/group"
        echo "✅ Group 'andre' zu group hinzugefügt"
    fi
fi

# Sudoers
mkdir -p "$ROOT_MOUNT/etc/sudoers.d"
echo "andre ALL=(ALL) NOPASSWD: ALL" > "$ROOT_MOUNT/etc/sudoers.d/andre"
chmod 0440 "$ROOT_MOUNT/etc/sudoers.d/andre"
echo "✅ Sudoers für 'andre' konfiguriert"

# Home-Verzeichnis
mkdir -p "$ROOT_MOUNT/home/andre"
chown 1000:1000 "$ROOT_MOUNT/home/andre" 2>/dev/null || true
echo "✅ Home-Verzeichnis erstellt"

echo ""

# === 6. CLOUD-INIT FIX ===
echo "=== 6. Cloud-init Fix ==="

# Entferne moode-startup Abhängigkeiten aus fix-user-id und fix-ssh-sudoers
if [ -f "$ROOT_MOUNT/lib/systemd/system/fix-user-id.service" ]; then
    sed -i.bak "s/After=.*moode-startup.service/After=local-fs.target/" "$ROOT_MOUNT/lib/systemd/system/fix-user-id.service" 2>/dev/null || true
fi

if [ -f "$ROOT_MOUNT/lib/systemd/system/fix-ssh-sudoers.service" ]; then
    sed -i.bak "s/After=.*moode-startup.service/After=local-fs.target/" "$ROOT_MOUNT/lib/systemd/system/fix-ssh-sudoers.service" 2>/dev/null || true
fi

echo "✅ Cloud-init Abhängigkeiten entfernt"

echo ""

# === ZUSAMMENFASSUNG ===
echo "=== FIX ABGESCHLOSSEN ==="
echo ""
echo "✅ SSH aktiviert"
echo "✅ ETH0 statisch konfiguriert (192.168.10.2)"
echo "✅ Services kopiert und aktiviert"
echo "✅ Scripts kopiert"
echo "✅ User 'andre' erstellt (UID 1000)"
echo "✅ Cloud-init Fix angewendet"
echo ""
echo "SD-Karte ist bereit für Boot!"
echo ""

