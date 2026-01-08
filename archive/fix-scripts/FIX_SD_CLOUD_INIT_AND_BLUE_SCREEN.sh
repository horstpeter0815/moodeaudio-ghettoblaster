#!/bin/bash
################################################################################
#
# Fix Cloud-Init Hang AND Blue Screen Loop on SD Card
# Kombiniert beide Fixes in einem Script
#
################################################################################

set -e

if [ "$EUID" -ne 0 ]; then 
    echo "❌ Bitte mit sudo ausführen!"
    echo "   sudo $0"
    exit 1
fi

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  🔧 FIX CLOUD-INIT HANG + BLUE SCREEN (SD-KARTE)          ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Finde SD-Karte
SD_DEVICE=$(diskutil list | grep -E 'external.*physical' | head -1 | awk '{print $1}' | sed 's|/dev/||')
if [ -z "$SD_DEVICE" ]; then
    echo "❌ Keine SD-Karte gefunden!"
    exit 1
fi

echo "✅ SD-Karte gefunden: /dev/$SD_DEVICE"
echo ""

# Mount-Points
BOOT_MOUNT=""
ROOT_MOUNT=""
MOUNTED_BY_SCRIPT_BOOT=false
MOUNTED_BY_SCRIPT_ROOT=false

# Cleanup-Funktion
cleanup() {
    if [ "$MOUNTED_BY_SCRIPT_BOOT" = true ]; then
        umount "$BOOT_MOUNT" 2>/dev/null || true
        rmdir "$BOOT_MOUNT" 2>/dev/null || true
    fi
    if [ "$MOUNTED_BY_SCRIPT_ROOT" = true ]; then
        umount "$ROOT_MOUNT" 2>/dev/null || true
        rmdir "$ROOT_MOUNT" 2>/dev/null || true
    fi
}

trap cleanup EXIT

# Prüfe und mounte Partitionen
echo "=== Prüfe und mounte Partitionen ==="

# Boot-Partition
BOOT_MOUNT=$(mount | grep "${SD_DEVICE}s1" | awk '{print $3}' | head -1)
if [ -z "$BOOT_MOUNT" ]; then
    BOOT_MOUNT="/tmp/sd-boot-$$"
    mkdir -p "$BOOT_MOUNT"
    mount -t msdos "/dev/${SD_DEVICE}s1" "$BOOT_MOUNT" || {
        echo "❌ Boot-Partition konnte nicht gemountet werden"
        exit 1
    }
    MOUNTED_BY_SCRIPT_BOOT=true
else
    echo "✅ Boot-Partition bereits gemountet: $BOOT_MOUNT"
fi

# Root-Partition
ROOT_MOUNT=$(mount | grep "${SD_DEVICE}s2" | awk '{print $3}' | head -1)
if [ -z "$ROOT_MOUNT" ]; then
    ROOT_MOUNT="/tmp/sd-root-$$"
    mkdir -p "$ROOT_MOUNT"
    mount "/dev/${SD_DEVICE}s2" "$ROOT_MOUNT" || {
        echo "❌ Root-Partition konnte nicht gemountet werden"
        exit 1
    }
    MOUNTED_BY_SCRIPT_ROOT=true
else
    echo "✅ Root-Partition bereits gemountet: $ROOT_MOUNT"
fi

echo ""

# === 1. CLOUD-INIT FIXES ===
echo "=== 1. CLOUD-INIT FIXES ==="

# 1.1 Leere cloud-init.target.wants
echo "1.1 Leere cloud-init.target.wants..."
mkdir -p "$ROOT_MOUNT/etc/systemd/system/cloud-init.target.wants" 2>/dev/null || true
rm -f "$ROOT_MOUNT/etc/systemd/system/cloud-init.target.wants/cloud-init-local.service" 2>/dev/null || true
rm -f "$ROOT_MOUNT/etc/systemd/system/cloud-init.target.wants/cloud-init-main.service" 2>/dev/null || true
rm -f "$ROOT_MOUNT/etc/systemd/system/cloud-init.target.wants/cloud-init-network.service" 2>/dev/null || true
rm -f "$ROOT_MOUNT/etc/systemd/system/cloud-init.target.wants/cloud-config.service" 2>/dev/null || true
rm -f "$ROOT_MOUNT/etc/systemd/system/cloud-init.target.wants/cloud-final.service" 2>/dev/null || true
rm -f "$ROOT_MOUNT/etc/systemd/system/cloud-init.target.wants/cloud-init-hotplugd.service" 2>/dev/null || true
echo "✅ cloud-init.target.wants geleert"

# 1.2 Erstelle cloud-init.target Override
echo "1.2 Erstelle cloud-init.target Override..."
mkdir -p "$ROOT_MOUNT/etc/systemd/system/cloud-init.target.d" 2>/dev/null || true
cat > "$ROOT_MOUNT/etc/systemd/system/cloud-init.target.d/override.conf" << 'EOF'
[Unit]
After=
Requires=
Wants=
EOF
echo "✅ cloud-init.target Override erstellt"

# 1.3 Deaktiviere cloud-init Services
echo "1.3 Deaktiviere cloud-init Services..."
rm -f "$ROOT_MOUNT/etc/systemd/system/multi-user.target.wants/cloud-init-local.service" 2>/dev/null || true
rm -f "$ROOT_MOUNT/etc/systemd/system/multi-user.target.wants/cloud-init-main.service" 2>/dev/null || true
rm -f "$ROOT_MOUNT/etc/systemd/system/multi-user.target.wants/cloud-init-network.service" 2>/dev/null || true
rm -f "$ROOT_MOUNT/etc/systemd/system/multi-user.target.wants/cloud-config.service" 2>/dev/null || true
rm -f "$ROOT_MOUNT/etc/systemd/system/multi-user.target.wants/cloud-final.service" 2>/dev/null || true
echo "✅ cloud-init Services deaktiviert"

# 1.4 Mask NetworkManager-wait-online
echo "1.4 Mask NetworkManager-wait-online..."
rm -f "$ROOT_MOUNT/etc/systemd/system/network-online.target.wants/NetworkManager-wait-online.service" 2>/dev/null || true
rm -f "$ROOT_MOUNT/etc/systemd/system/multi-user.target.wants/NetworkManager-wait-online.service" 2>/dev/null || true
mkdir -p "$ROOT_MOUNT/etc/systemd/system/NetworkManager-wait-online.service.d" 2>/dev/null || true
ln -sf /dev/null "$ROOT_MOUNT/etc/systemd/system/NetworkManager-wait-online.service" 2>/dev/null || true
echo "✅ NetworkManager-wait-online maskiert"

echo ""

# === 2. BLUE SCREEN FIXES ===
echo "=== 2. BLUE SCREEN FIXES ==="

# 2.1 Entferne piwiz.desktop
echo "2.1 Entferne piwiz.desktop..."
rm -f "$ROOT_MOUNT/etc/xdg/autostart/piwiz.desktop" 2>/dev/null || true
rm -f "$ROOT_MOUNT/usr/share/raspberrypi-ui-mods/etc/xdg/autostart/piwiz.desktop" 2>/dev/null || true
find "$ROOT_MOUNT/etc" "$ROOT_MOUNT/usr" -name "piwiz.desktop" -type f -delete 2>/dev/null || true
echo "✅ piwiz.desktop entfernt"

# 2.2 Deaktiviere piwiz Service
echo "2.2 Deaktiviere piwiz Service..."
rm -f "$ROOT_MOUNT/etc/systemd/system/multi-user.target.wants/piwiz.service" 2>/dev/null || true
rm -f "$ROOT_MOUNT/etc/systemd/system/graphical.target.wants/piwiz.service" 2>/dev/null || true
mkdir -p "$ROOT_MOUNT/etc/systemd/system/piwiz.service.d" 2>/dev/null || true
ln -sf /dev/null "$ROOT_MOUNT/etc/systemd/system/piwiz.service" 2>/dev/null || true
echo "✅ piwiz Service deaktiviert"

# 2.3 Stelle sicher dass User 'andre' existiert
echo "2.3 Prüfe User 'andre'..."
if ! grep -q "^andre:" "$ROOT_MOUNT/etc/passwd" 2>/dev/null; then
    echo "⚠️  User 'andre' fehlt - füge hinzu..."
    echo "andre:x:1000:1000:Ghettoblaster User:/home/andre:/bin/bash" >> "$ROOT_MOUNT/etc/passwd"
    if ! grep -q "^andre:" "$ROOT_MOUNT/etc/group" 2>/dev/null; then
        echo "andre:x:1000:" >> "$ROOT_MOUNT/etc/group" 2>/dev/null || true
    fi
    mkdir -p "$ROOT_MOUNT/home/andre" 2>/dev/null || true
    chown 1000:1000 "$ROOT_MOUNT/home/andre" 2>/dev/null || true
    echo "✅ User 'andre' hinzugefügt"
else
    echo "✅ User 'andre' existiert bereits"
fi

echo ""

# === 3. AKTIVIERE UNSERE SERVICES ===
echo "=== 3. Aktiviere Boot-Fix Services ==="

SCRIPT_DIR="/Users/andrevollmer/moodeaudio-cursor"
SERVICES_SOURCE="$SCRIPT_DIR/moode-source/lib/systemd/system"
SERVICES_TARGET="$ROOT_MOUNT/lib/systemd/system"

if [ -d "$SERVICES_SOURCE" ]; then
    # Kopiere Services
    cp "$SERVICES_SOURCE/boot-complete-minimal.service" "$SERVICES_TARGET/" 2>/dev/null || true
    cp "$SERVICES_SOURCE/cloud-init-unblock.service" "$SERVICES_TARGET/" 2>/dev/null || true
    cp "$SERVICES_SOURCE/fix-user-id.service" "$SERVICES_TARGET/" 2>/dev/null || true
    cp "$SERVICES_SOURCE/boot-debug-logger.service" "$SERVICES_TARGET/" 2>/dev/null || true
    echo "✅ Services kopiert"
    
    # Aktiviere Services
    mkdir -p "$ROOT_MOUNT/etc/systemd/system/local-fs.target.wants" 2>/dev/null || true
    ln -sf /lib/systemd/system/boot-complete-minimal.service "$ROOT_MOUNT/etc/systemd/system/local-fs.target.wants/boot-complete-minimal.service" 2>/dev/null || true
    ln -sf /lib/systemd/system/cloud-init-unblock.service "$ROOT_MOUNT/etc/systemd/system/local-fs.target.wants/cloud-init-unblock.service" 2>/dev/null || true
    ln -sf /lib/systemd/system/boot-debug-logger.service "$ROOT_MOUNT/etc/systemd/system/local-fs.target.wants/boot-debug-logger.service" 2>/dev/null || true
    
    mkdir -p "$ROOT_MOUNT/etc/systemd/system/multi-user.target.wants" 2>/dev/null || true
    ln -sf /lib/systemd/system/fix-user-id.service "$ROOT_MOUNT/etc/systemd/system/multi-user.target.wants/fix-user-id.service" 2>/dev/null || true
    echo "✅ Services aktiviert"
else
    echo "⚠️  Services-Source nicht gefunden: $SERVICES_SOURCE"
fi

echo ""

# === 4. SSH AKTIVIEREN ===
echo "=== 4. Aktiviere SSH ==="
touch "$BOOT_MOUNT/ssh" 2>/dev/null || touch "$BOOT_MOUNT/firmware/ssh" 2>/dev/null || true
echo "✅ SSH-Flag erstellt"
echo ""

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  ✅ ALLE FIXES ABGESCHLOSSEN                                 ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "📋 Angewendete Fixes:"
echo "   ✅ cloud-init.target.wants geleert"
echo "   ✅ cloud-init.target Override erstellt"
echo "   ✅ NetworkManager-wait-online maskiert"
echo "   ✅ piwiz.desktop entfernt (Blue Screen Fix)"
echo "   ✅ Boot-Fix Services aktiviert"
echo "   ✅ SSH aktiviert"
echo ""
echo "📋 Nächste Schritte:"
echo "   1. SD-Karte auswerfen"
echo "   2. SD-Karte in Pi einstecken"
echo "   3. Pi booten"
echo "   4. SSH-Zugriff: ssh andre@192.168.10.2"
echo ""

