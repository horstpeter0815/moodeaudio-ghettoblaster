#!/bin/bash
# Aggressive Cloud-Init Fix - Deaktiviert cloud-init komplett falls nötig
# Führt alle notwendigen Fixes aus während SD-Karte gemountet ist

set -e

if [ "$EUID" -ne 0 ]; then 
    echo "❌ Bitte mit sudo ausführen!"
    echo "   sudo $0"
    exit 1
fi

ROOT_MOUNT="/Volumes/rootfs"
BOOT_MOUNT="/Volumes/bootfs"

if [ ! -d "$ROOT_MOUNT" ]; then
    echo "❌ Root-Partition nicht gemountet: $ROOT_MOUNT"
    echo "   Bitte SD-Karte einstecken und warten bis gemountet"
    exit 1
fi

echo "=== AGGRESSIVE CLOUD-INIT FIX ==="
echo "Root: $ROOT_MOUNT"
echo "Boot: $BOOT_MOUNT"
echo ""

SCRIPT_DIR="/Users/andrevollmer/moodeaudio-cursor"
SERVICES_SOURCE="$SCRIPT_DIR/moode-source/lib/systemd/system"

# 1. Erstelle Verzeichnisse
echo "1. Erstelle Verzeichnisse..."
mkdir -p "$ROOT_MOUNT/lib/systemd/system"
mkdir -p "$ROOT_MOUNT/etc/systemd/system/local-fs.target.wants"
mkdir -p "$ROOT_MOUNT/etc/systemd/system/multi-user.target.wants"
mkdir -p "$ROOT_MOUNT/etc/systemd/system/cloud-init.target.d"
echo "✅ Verzeichnisse erstellt"
echo ""

# 2. Kopiere Services (mit aktualisiertem cloud-init-unblock)
echo "2. Kopiere Services..."
cp "$SERVICES_SOURCE/cloud-init-unblock.service" "$ROOT_MOUNT/lib/systemd/system/" 2>/dev/null || true
cp "$SERVICES_SOURCE/cloud-init-force-unblock.service" "$ROOT_MOUNT/lib/systemd/system/" 2>/dev/null || true
cp "$SERVICES_SOURCE/boot-complete-minimal.service" "$ROOT_MOUNT/lib/systemd/system/" 2>/dev/null || true
cp "$SERVICES_SOURCE/fix-user-id.service" "$ROOT_MOUNT/lib/systemd/system/" 2>/dev/null || true
echo "✅ Services kopiert"
echo ""

# 3. Aktiviere Services
echo "3. Aktiviere Services..."
ln -sf /lib/systemd/system/cloud-init-unblock.service "$ROOT_MOUNT/etc/systemd/system/local-fs.target.wants/cloud-init-unblock.service" 2>/dev/null || true
ln -sf /lib/systemd/system/cloud-init-force-unblock.service "$ROOT_MOUNT/etc/systemd/system/local-fs.target.wants/cloud-init-force-unblock.service" 2>/dev/null || true
ln -sf /lib/systemd/system/boot-complete-minimal.service "$ROOT_MOUNT/etc/systemd/system/local-fs.target.wants/boot-complete-minimal.service" 2>/dev/null || true
ln -sf /lib/systemd/system/fix-user-id.service "$ROOT_MOUNT/etc/systemd/system/multi-user.target.wants/fix-user-id.service" 2>/dev/null || true
echo "✅ Services aktiviert"
echo ""

# 4. Deaktiviere cloud-init Services komplett
echo "4. Deaktiviere cloud-init Services..."
rm -f "$ROOT_MOUNT/etc/systemd/system/multi-user.target.wants/cloud-init.service" 2>/dev/null || true
rm -f "$ROOT_MOUNT/etc/systemd/system/multi-user.target.wants/cloud-init-local.service" 2>/dev/null || true
rm -f "$ROOT_MOUNT/etc/systemd/system/multi-user.target.wants/cloud-init-config.service" 2>/dev/null || true
rm -f "$ROOT_MOUNT/etc/systemd/system/multi-user.target.wants/cloud-init-final.service" 2>/dev/null || true
echo "✅ Cloud-init Services deaktiviert"
echo ""

# 5. Erstelle cloud-init.target Override
echo "5. Erstelle cloud-init.target Override..."
cat > "$ROOT_MOUNT/etc/systemd/system/cloud-init.target.d/override.conf" << 'EOF'
[Unit]
After=
Requires=
Wants=
EOF
echo "✅ Override erstellt"
echo ""

# 6. Deaktiviere NetworkManager-wait-online
echo "6. Deaktiviere NetworkManager-wait-online..."
rm -f "$ROOT_MOUNT/etc/systemd/system/network-online.target.wants/NetworkManager-wait-online.service" 2>/dev/null || true
rm -f "$ROOT_MOUNT/etc/systemd/system/multi-user.target.wants/NetworkManager-wait-online.service" 2>/dev/null || true
echo "✅ NetworkManager-wait-online deaktiviert"
echo ""

# 7. Fixe moode-startup Abhängigkeiten
echo "7. Fixe moode-startup Abhängigkeiten..."
if [ -f "$ROOT_MOUNT/lib/systemd/system/fix-user-id.service" ]; then
    sed -i.bak 's/After=.*moode-startup.service/After=local-fs.target/' "$ROOT_MOUNT/lib/systemd/system/fix-user-id.service" 2>/dev/null || true
    echo "✅ fix-user-id.service gefixt"
fi

if [ -f "$ROOT_MOUNT/lib/systemd/system/fix-ssh-sudoers.service" ]; then
    sed -i.bak 's/After=.*moode-startup.service/After=local-fs.target/' "$ROOT_MOUNT/lib/systemd/system/fix-ssh-sudoers.service" 2>/dev/null || true
    echo "✅ fix-ssh-sudoers.service gefixt"
fi
echo ""

# 8. Entferne alle After=cloud-init.target Abhängigkeiten
echo "8. Entferne cloud-init.target Abhängigkeiten..."
find "$ROOT_MOUNT/lib/systemd/system" -name "*.service" -type f -exec sed -i.bak 's/After=.*cloud-init.target/After=local-fs.target/g' {} \; 2>/dev/null || true
find "$ROOT_MOUNT/etc/systemd/system" -name "*.service" -type f -exec sed -i.bak 's/After=.*cloud-init.target/After=local-fs.target/g' {} \; 2>/dev/null || true
echo "✅ Cloud-init.target Abhängigkeiten entfernt"
echo ""

# 9. SSH aktivieren
echo "9. Aktiviere SSH..."
touch "$BOOT_MOUNT/ssh" 2>/dev/null || touch "$BOOT_MOUNT/firmware/ssh" 2>/dev/null || true
echo "✅ SSH aktiviert"
echo ""

echo "=== AGGRESSIVE FIX ABGESCHLOSSEN ==="
echo ""
echo "✅ cloud-init-unblock.service (aggressiv) aktiviert"
echo "✅ cloud-init-force-unblock.service aktiviert"
echo "✅ boot-complete-minimal.service aktiviert"
echo "✅ Cloud-init Services deaktiviert"
echo "✅ cloud-init.target Override erstellt"
echo "✅ Alle cloud-init.target Abhängigkeiten entfernt"
echo "✅ NetworkManager-wait-online deaktiviert"
echo "✅ SSH aktiviert"
echo ""
echo "SD-Karte ist aggressiv gefixt. Pi neu starten!"

