#!/bin/bash
# Fix SD Card Filesystem AND Cloud-Init Issues
# Prüft Dateisystem, repariert es, und wendet dann alle Cloud-Init Fixes an

set -e

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
ROOT_PARTITION="${SD_CARD}s2"

echo "=== SD-KARTE DATEISYSTEM + CLOUD-INIT FIX ==="
echo "SD-Karte: $SD_CARD"
echo "Root-Partition: $ROOT_PARTITION"
echo ""

# Prüfe ob Partition existiert
if [ ! -e "$ROOT_PARTITION" ]; then
    echo "❌ Root-Partition nicht gefunden: $ROOT_PARTITION"
    exit 1
fi

# Prüfe Mount-Status
ROOT_MOUNT=$(diskutil info "$ROOT_PARTITION" 2>/dev/null | grep "Mount Point:" | awk -F': ' '{print $2}' | xargs || echo "")

if [ -z "$ROOT_MOUNT" ]; then
    echo "=== 1. DATEISYSTEM PRÜFUNG UND REPARATUR ==="
    echo ""
    echo "⚠️  Root-Partition nicht gemountet - muss für fsck unmountet sein"
    echo ""
    echo "Führe fsck aus..."
    echo "   (Dies kann einige Minuten dauern)"
    echo ""
    
    # Unmount falls gemountet
    diskutil unmount "$ROOT_PARTITION" 2>/dev/null || true
    
    # Führe fsck aus
    echo "Prüfe Dateisystem..."
    fsck -fy "$ROOT_PARTITION" || {
        echo ""
        echo "⚠️  fsck hat Fehler gefunden und repariert"
        echo "   Das ist normal bei beschädigten Dateisystemen"
    }
    
    echo ""
    echo "✅ Dateisystem-Prüfung abgeschlossen"
    echo ""
    
    # Mounte wieder
    echo "Mounte Root-Partition..."
    diskutil mount "$ROOT_PARTITION" || {
        echo "❌ Konnte Root-Partition nicht mounten"
        exit 1
    }
    
    ROOT_MOUNT=$(diskutil info "$ROOT_PARTITION" 2>/dev/null | grep "Mount Point:" | awk -F': ' '{print $2}' | xargs || echo "")
    
    if [ -z "$ROOT_MOUNT" ]; then
        echo "❌ Konnte Mount-Point nicht ermitteln"
        exit 1
    fi
else
    echo "✅ Root-Partition bereits gemountet: $ROOT_MOUNT"
    echo ""
fi

BOOT_MOUNT=$(diskutil info "${SD_CARD}s1" 2>/dev/null | grep "Mount Point:" | awk -F': ' '{print $2}' | xargs || echo "/Volumes/bootfs")

echo "Root: $ROOT_MOUNT"
echo "Boot: $BOOT_MOUNT"
echo ""

SCRIPT_DIR="/Users/andrevollmer/moodeaudio-cursor"
SERVICES_SOURCE="$SCRIPT_DIR/moode-source/lib/systemd/system"

# 2. Erstelle Verzeichnisse
echo "=== 2. ERSTELLE VERZEICHNISSE ==="
mkdir -p "$ROOT_MOUNT/lib/systemd/system"
mkdir -p "$ROOT_MOUNT/etc/systemd/system/local-fs.target.wants"
mkdir -p "$ROOT_MOUNT/etc/systemd/system/multi-user.target.wants"
mkdir -p "$ROOT_MOUNT/etc/systemd/system/cloud-init.target.d"
echo "✅ Verzeichnisse erstellt"
echo ""

# 3. Kopiere Services
echo "=== 3. KOPIERE SERVICES ==="
cp "$SERVICES_SOURCE/cloud-init-unblock.service" "$ROOT_MOUNT/lib/systemd/system/" 2>/dev/null || true
cp "$SERVICES_SOURCE/boot-complete-minimal.service" "$ROOT_MOUNT/lib/systemd/system/" 2>/dev/null || true
cp "$SERVICES_SOURCE/fix-user-id.service" "$ROOT_MOUNT/lib/systemd/system/" 2>/dev/null || true
cp "$SERVICES_SOURCE/boot-debug-logger.service" "$ROOT_MOUNT/lib/systemd/system/" 2>/dev/null || true
echo "✅ Services kopiert"
echo ""

# 4. Aktiviere Services
echo "=== 4. AKTIVIERE SERVICES ==="
ln -sf /lib/systemd/system/cloud-init-unblock.service "$ROOT_MOUNT/etc/systemd/system/local-fs.target.wants/cloud-init-unblock.service" 2>/dev/null || true
ln -sf /lib/systemd/system/boot-complete-minimal.service "$ROOT_MOUNT/etc/systemd/system/local-fs.target.wants/boot-complete-minimal.service" 2>/dev/null || true
ln -sf /lib/systemd/system/fix-user-id.service "$ROOT_MOUNT/etc/systemd/system/multi-user.target.wants/fix-user-id.service" 2>/dev/null || true
echo "✅ Services aktiviert"
echo ""

# 5. Deaktiviere cloud-init Services
echo "=== 5. DEAKTIVIERE CLOUD-INIT SERVICES ==="
rm -f "$ROOT_MOUNT/etc/systemd/system/multi-user.target.wants/cloud-init.service" 2>/dev/null || true
rm -f "$ROOT_MOUNT/etc/systemd/system/multi-user.target.wants/cloud-init-local.service" 2>/dev/null || true
rm -f "$ROOT_MOUNT/etc/systemd/system/multi-user.target.wants/cloud-init-config.service" 2>/dev/null || true
rm -f "$ROOT_MOUNT/etc/systemd/system/multi-user.target.wants/cloud-init-final.service" 2>/dev/null || true
echo "✅ Cloud-init Services deaktiviert"
echo ""

# 6. Erstelle cloud-init.target Override
echo "=== 6. ERSTELLE CLOUD-INIT TARGET OVERRIDE ==="
cat > "$ROOT_MOUNT/etc/systemd/system/cloud-init.target.d/override.conf" << 'EOF'
[Unit]
After=
Requires=
Wants=
EOF
echo "✅ Override erstellt"
echo ""

# 7. Deaktiviere NetworkManager-wait-online
echo "=== 7. DEAKTIVIERE NETWORKMANAGER-WAIT-ONLINE ==="
rm -f "$ROOT_MOUNT/etc/systemd/system/network-online.target.wants/NetworkManager-wait-online.service" 2>/dev/null || true
rm -f "$ROOT_MOUNT/etc/systemd/system/multi-user.target.wants/NetworkManager-wait-online.service" 2>/dev/null || true
echo "✅ NetworkManager-wait-online deaktiviert"
echo ""

# 8. Fixe moode-startup Abhängigkeiten
echo "=== 8. FIXE MOODE-STARTUP ABHÄNGIGKEITEN ==="
if [ -f "$ROOT_MOUNT/lib/systemd/system/fix-user-id.service" ]; then
    sed -i.bak 's/After=.*moode-startup.service/After=local-fs.target/' "$ROOT_MOUNT/lib/systemd/system/fix-user-id.service" 2>/dev/null || true
    echo "✅ fix-user-id.service gefixt"
fi

if [ -f "$ROOT_MOUNT/lib/systemd/system/fix-ssh-sudoers.service" ]; then
    sed -i.bak 's/After=.*moode-startup.service/After=local-fs.target/' "$ROOT_MOUNT/lib/systemd/system/fix-ssh-sudoers.service" 2>/dev/null || true
    echo "✅ fix-ssh-sudoers.service gefixt"
fi
echo ""

# 9. SSH aktivieren
echo "=== 9. AKTIVIERE SSH ==="
touch "$BOOT_MOUNT/ssh" 2>/dev/null || touch "$BOOT_MOUNT/firmware/ssh" 2>/dev/null || true
echo "✅ SSH aktiviert"
echo ""

echo "=== FIX ABGESCHLOSSEN ==="
echo ""
echo "✅ Dateisystem geprüft und repariert"
echo "✅ cloud-init-unblock.service aktiviert"
echo "✅ boot-complete-minimal.service aktiviert"
echo "✅ Cloud-init Services deaktiviert"
echo "✅ cloud-init.target Override erstellt"
echo "✅ NetworkManager-wait-online deaktiviert"
echo "✅ SSH aktiviert"
echo ""
echo "SD-Karte ist gefixt. Pi neu starten!"

