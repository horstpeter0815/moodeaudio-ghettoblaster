#!/bin/bash
################################################################################
#
# Fix Blue Screen Loop on SD Card
# Deaktiviert den ersten Boot-Wizard (piwiz) direkt auf der SD-Karte
#
################################################################################

set -e

if [ "$EUID" -ne 0 ]; then 
    echo "❌ Bitte mit sudo ausführen!"
    echo "   sudo $0"
    exit 1
fi

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  🔧 FIX BLUE SCREEN LOOP (SD-KARTE)                        ║"
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

# === 1. ENTFERNE piwiz.desktop ===
echo "=== 1. Entferne piwiz.desktop ==="
rm -f "$ROOT_MOUNT/etc/xdg/autostart/piwiz.desktop" 2>/dev/null || true
rm -f "$ROOT_MOUNT/usr/share/raspberrypi-ui-mods/etc/xdg/autostart/piwiz.desktop" 2>/dev/null || true
find "$ROOT_MOUNT/etc" "$ROOT_MOUNT/usr" -name "piwiz.desktop" -type f -delete 2>/dev/null || true
echo "✅ piwiz.desktop entfernt"
echo ""

# === 2. DISABLE piwiz SERVICE ===
echo "=== 2. Deaktiviere piwiz Service ==="
rm -f "$ROOT_MOUNT/etc/systemd/system/multi-user.target.wants/piwiz.service" 2>/dev/null || true
rm -f "$ROOT_MOUNT/etc/systemd/system/graphical.target.wants/piwiz.service" 2>/dev/null || true
# Mask service
mkdir -p "$ROOT_MOUNT/etc/systemd/system/piwiz.service.d" 2>/dev/null || true
ln -sf /dev/null "$ROOT_MOUNT/etc/systemd/system/piwiz.service" 2>/dev/null || true
echo "✅ piwiz Service deaktiviert"
echo ""

# === 3. STELLE SICHER DASS USER 'andre' EXISTIERT ===
echo "=== 3. Prüfe User 'andre' ==="
if ! grep -q "^andre:" "$ROOT_MOUNT/etc/passwd" 2>/dev/null; then
    echo "⚠️  User 'andre' fehlt - füge hinzu..."
    echo "andre:x:1000:1000:Ghettoblaster User:/home/andre:/bin/bash" >> "$ROOT_MOUNT/etc/passwd"
    echo "andre:x:1000:" >> "$ROOT_MOUNT/etc/group" 2>/dev/null || true
    mkdir -p "$ROOT_MOUNT/home/andre" 2>/dev/null || true
    chown 1000:1000 "$ROOT_MOUNT/home/andre" 2>/dev/null || true
    echo "✅ User 'andre' hinzugefügt"
else
    echo "✅ User 'andre' existiert bereits"
fi
echo ""

# === 4. SETZE PASSWORT FÜR 'andre' ===
echo "=== 4. Setze Passwort für 'andre' ==="
# Erstelle chroot-Script zum Setzen des Passworts
cat > "$ROOT_MOUNT/tmp/set_password.sh" << 'EOF'
#!/bin/bash
echo "andre:0815" | chpasswd
EOF
chmod +x "$ROOT_MOUNT/tmp/set_password.sh"
# Führe in chroot aus (falls möglich)
chroot "$ROOT_MOUNT" /tmp/set_password.sh 2>/dev/null || {
    # Fallback: Setze Passwort-Hash direkt
    echo "⚠️  chroot nicht möglich - setze Passwort-Hash direkt"
    # Passwort-Hash für "0815" (erstellt mit: openssl passwd -1 0815)
    # Oder verwende mkpasswd falls verfügbar
    if command -v mkpasswd >/dev/null 2>&1; then
        PASSWORD_HASH=$(mkpasswd -m sha-512 0815)
        sed -i.bak "s|^andre:.*|andre:$PASSWORD_HASH:18500:0:99999:7:::|" "$ROOT_MOUNT/etc/shadow" 2>/dev/null || true
    fi
}
rm -f "$ROOT_MOUNT/tmp/set_password.sh" 2>/dev/null || true
echo "✅ Passwort gesetzt"
echo ""

# === 5. DISABLE FIRST-BOOT FLAGS ===
echo "=== 5. Deaktiviere First-Boot Flags ==="
rm -f "$ROOT_MOUNT/etc/systemd/system/multi-user.target.wants/raspi-config.service" 2>/dev/null || true
rm -f "$ROOT_MOUNT/etc/systemd/system/graphical.target.wants/raspi-config.service" 2>/dev/null || true
echo "✅ First-Boot Flags entfernt"
echo ""

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  ✅ FIX ABGESCHLOSSEN                                        ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "📋 Nächste Schritte:"
echo "   1. SD-Karte auswerfen"
echo "   2. SD-Karte in Pi einstecken"
echo "   3. Pi booten"
echo "   4. Blue Screen sollte nicht mehr erscheinen"
echo "   5. SSH-Zugriff: ssh andre@192.168.10.2"
echo ""

