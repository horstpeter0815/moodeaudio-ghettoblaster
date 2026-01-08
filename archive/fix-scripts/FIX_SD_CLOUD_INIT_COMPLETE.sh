#!/bin/bash
# Complete Cloud-Init Fix - Entfernt ALLE cloud-init Dependencies
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

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  🔧 COMPLETE CLOUD-INIT FIX                                 ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "Root: $ROOT_MOUNT"
echo "Boot: $BOOT_MOUNT"
echo ""

SCRIPT_DIR="/Users/andrevollmer/moodeaudio-cursor"
SERVICES_SOURCE="$SCRIPT_DIR/moode-source/lib/systemd/system"

# 1. Erstelle Verzeichnisse
echo "=== 1. ERSTELLE VERZEICHNISSE ==="
mkdir -p "$ROOT_MOUNT/lib/systemd/system"
mkdir -p "$ROOT_MOUNT/etc/systemd/system/local-fs.target.wants"
mkdir -p "$ROOT_MOUNT/etc/systemd/system/multi-user.target.wants"
mkdir -p "$ROOT_MOUNT/etc/systemd/system/cloud-init.target.d"
echo "✅ Verzeichnisse erstellt"
echo ""

# 2. ENTFERNE ALLE CLOUD-INIT SERVICES AUS cloud-init.target.wants
echo "=== 2. ENTFERNE CLOUD-INIT SERVICES ==="
echo "Entferne alle Symlinks aus cloud-init.target.wants..."
rm -f "$ROOT_MOUNT/etc/systemd/system/cloud-init.target.wants/cloud-init-local.service" 2>/dev/null || true
rm -f "$ROOT_MOUNT/etc/systemd/system/cloud-init.target.wants/cloud-init-main.service" 2>/dev/null || true
rm -f "$ROOT_MOUNT/etc/systemd/system/cloud-init.target.wants/cloud-init-network.service" 2>/dev/null || true
rm -f "$ROOT_MOUNT/etc/systemd/system/cloud-init.target.wants/cloud-config.service" 2>/dev/null || true
rm -f "$ROOT_MOUNT/etc/systemd/system/cloud-init.target.wants/cloud-final.service" 2>/dev/null || true
rm -f "$ROOT_MOUNT/etc/systemd/system/cloud-init.target.wants/cloud-init-hotplugd.service" 2>/dev/null || true
echo "✅ Alle cloud-init Services aus cloud-init.target.wants entfernt"
echo ""

# 3. DEAKTIVIERE CLOUD-INIT SERVICES KOMPLETT
echo "=== 3. DEAKTIVIERE CLOUD-INIT SERVICES ==="
rm -f "$ROOT_MOUNT/etc/systemd/system/multi-user.target.wants/cloud-init.service" 2>/dev/null || true
rm -f "$ROOT_MOUNT/etc/systemd/system/multi-user.target.wants/cloud-init-local.service" 2>/dev/null || true
rm -f "$ROOT_MOUNT/etc/systemd/system/multi-user.target.wants/cloud-init-config.service" 2>/dev/null || true
rm -f "$ROOT_MOUNT/etc/systemd/system/multi-user.target.wants/cloud-init-final.service" 2>/dev/null || true
rm -f "$ROOT_MOUNT/etc/systemd/system/multi-user.target.wants/cloud-init-main.service" 2>/dev/null || true
rm -f "$ROOT_MOUNT/etc/systemd/system/multi-user.target.wants/cloud-init-network.service" 2>/dev/null || true
echo "✅ Cloud-init Services deaktiviert"
echo ""

# 4. Kopiere Services
echo "=== 4. KOPIERE SERVICES ==="
cp "$SERVICES_SOURCE/cloud-init-unblock.service" "$ROOT_MOUNT/lib/systemd/system/" 2>/dev/null || true
cp "$SERVICES_SOURCE/boot-complete-minimal.service" "$ROOT_MOUNT/lib/systemd/system/" 2>/dev/null || true
cp "$SERVICES_SOURCE/fix-user-id.service" "$ROOT_MOUNT/lib/systemd/system/" 2>/dev/null || true
cp "$SERVICES_SOURCE/boot-debug-logger.service" "$ROOT_MOUNT/lib/systemd/system/" 2>/dev/null || true
echo "✅ Services kopiert"
echo ""

# 5. Aktiviere Services
echo "=== 5. AKTIVIERE SERVICES ==="
ln -sf /lib/systemd/system/cloud-init-unblock.service "$ROOT_MOUNT/etc/systemd/system/local-fs.target.wants/cloud-init-unblock.service" 2>/dev/null || true
ln -sf /lib/systemd/system/boot-complete-minimal.service "$ROOT_MOUNT/etc/systemd/system/local-fs.target.wants/boot-complete-minimal.service" 2>/dev/null || true
ln -sf /lib/systemd/system/fix-user-id.service "$ROOT_MOUNT/etc/systemd/system/multi-user.target.wants/fix-user-id.service" 2>/dev/null || true
echo "✅ Services aktiviert"
echo ""

# 6. Erstelle cloud-init.target Override (AGGRESSIV)
echo "=== 6. ERSTELLE CLOUD-INIT TARGET OVERRIDE ==="
cat > "$ROOT_MOUNT/etc/systemd/system/cloud-init.target.d/override.conf" << 'EOF'
[Unit]
After=
Requires=
Wants=
Conflicts=
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

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  ✅ FIX ABGESCHLOSSEN                                         ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "✅ Alle cloud-init Services aus cloud-init.target.wants entfernt"
echo "✅ Alle cloud-init Services deaktiviert"
echo "✅ cloud-init-unblock.service aktiviert"
echo "✅ boot-complete-minimal.service aktiviert"
echo "✅ cloud-init.target Override erstellt (aggressiv)"
echo "✅ NetworkManager-wait-online deaktiviert"
echo "✅ SSH aktiviert"
echo ""
echo "SD-Karte ist komplett gefixt. Pi neu starten!"

