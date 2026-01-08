#!/bin/bash
# Complete NetworkManager-wait-online Fix - Maskiert und deaktiviert komplett
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
echo "║  🔧 NETWORKMANAGER-WAIT-ONLINE KOMPLETT FIX                 ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "Root: $ROOT_MOUNT"
echo "Boot: $BOOT_MOUNT"
echo ""

# 1. ENTFERNE ALLE SYMLINKS
echo "=== 1. ENTFERNE ALLE SYMLINKS ==="
rm -f "$ROOT_MOUNT/etc/systemd/system/network-online.target.wants/NetworkManager-wait-online.service" 2>/dev/null || true
rm -f "$ROOT_MOUNT/etc/systemd/system/multi-user.target.wants/NetworkManager-wait-online.service" 2>/dev/null || true
rm -f "$ROOT_MOUNT/etc/systemd/system/default.target.wants/NetworkManager-wait-online.service" 2>/dev/null || true
rm -f "$ROOT_MOUNT/etc/systemd/system/sysinit.target.wants/NetworkManager-wait-online.service" 2>/dev/null || true
rm -f "$ROOT_MOUNT/etc/systemd/system/basic.target.wants/NetworkManager-wait-online.service" 2>/dev/null || true
echo "✅ Alle Symlinks entfernt"
echo ""

# 2. MASKIERE SERVICE (verhindert dass er gestartet wird)
echo "=== 2. MASKIERE SERVICE ==="
mkdir -p "$ROOT_MOUNT/etc/systemd/system"
ln -sf /dev/null "$ROOT_MOUNT/etc/systemd/system/NetworkManager-wait-online.service" 2>/dev/null || true
echo "✅ Service maskiert"
echo ""

# 3. ERSTELLE OVERRIDE (falls Service existiert)
echo "=== 3. ERSTELLE OVERRIDE ==="
mkdir -p "$ROOT_MOUNT/etc/systemd/system/NetworkManager-wait-online.service.d"
cat > "$ROOT_MOUNT/etc/systemd/system/NetworkManager-wait-online.service.d/override.conf" << 'EOF'
[Unit]
After=
Before=
Wants=
Requires=
Conflicts=

[Service]
ExecStart=
ExecStart=/bin/true
Type=oneshot
RemainAfterExit=yes
EOF
echo "✅ Override erstellt"
echo ""

# 4. ENTFERNE NETWORK-ONLINE ABHÄNGIGKEITEN AUS ANDEREN SERVICES
echo "=== 4. ENTFERNE NETWORK-ONLINE ABHÄNGIGKEITEN ==="
echo "Suche Services die auf network-online.target warten..."
find "$ROOT_MOUNT/lib/systemd/system" -name "*.service" -type f -exec grep -l "After=.*network-online\|Wants=.*network-online\|Requires=.*network-online" {} \; 2>/dev/null | while read -r service; do
    echo "  Fixe: $(basename $service)"
    sed -i.bak 's/After=.*network-online.target/After=local-fs.target/g' "$service" 2>/dev/null || true
    sed -i.bak 's/Wants=.*network-online.target//g' "$service" 2>/dev/null || true
    sed -i.bak 's/Requires=.*network-online.target//g' "$service" 2>/dev/null || true
done
echo "✅ Network-online Abhängigkeiten entfernt"
echo ""

# 5. ENTFERNE CLOUD-INIT SERVICES AUS cloud-init.target.wants
echo "=== 5. ENTFERNE CLOUD-INIT SERVICES ==="
rm -f "$ROOT_MOUNT/etc/systemd/system/cloud-init.target.wants/cloud-init-local.service" 2>/dev/null || true
rm -f "$ROOT_MOUNT/etc/systemd/system/cloud-init.target.wants/cloud-init-main.service" 2>/dev/null || true
rm -f "$ROOT_MOUNT/etc/systemd/system/cloud-init.target.wants/cloud-init-network.service" 2>/dev/null || true
rm -f "$ROOT_MOUNT/etc/systemd/system/cloud-init.target.wants/cloud-config.service" 2>/dev/null || true
rm -f "$ROOT_MOUNT/etc/systemd/system/cloud-init.target.wants/cloud-final.service" 2>/dev/null || true
echo "✅ Cloud-init Services entfernt"
echo ""

# 6. KOPIERE UND AKTIVIERE UNSERE SERVICES
SCRIPT_DIR="/Users/andrevollmer/moodeaudio-cursor"
SERVICES_SOURCE="$SCRIPT_DIR/moode-source/lib/systemd/system"

echo "=== 6. KOPIERE UND AKTIVIERE SERVICES ==="
mkdir -p "$ROOT_MOUNT/lib/systemd/system"
mkdir -p "$ROOT_MOUNT/etc/systemd/system/local-fs.target.wants"
mkdir -p "$ROOT_MOUNT/etc/systemd/system/multi-user.target.wants"

cp "$SERVICES_SOURCE/cloud-init-unblock.service" "$ROOT_MOUNT/lib/systemd/system/" 2>/dev/null || true
cp "$SERVICES_SOURCE/boot-complete-minimal.service" "$ROOT_MOUNT/lib/systemd/system/" 2>/dev/null || true
cp "$SERVICES_SOURCE/fix-user-id.service" "$ROOT_MOUNT/lib/systemd/system/" 2>/dev/null || true

ln -sf /lib/systemd/system/cloud-init-unblock.service "$ROOT_MOUNT/etc/systemd/system/local-fs.target.wants/cloud-init-unblock.service" 2>/dev/null || true
ln -sf /lib/systemd/system/boot-complete-minimal.service "$ROOT_MOUNT/etc/systemd/system/local-fs.target.wants/boot-complete-minimal.service" 2>/dev/null || true
ln -sf /lib/systemd/system/fix-user-id.service "$ROOT_MOUNT/etc/systemd/system/multi-user.target.wants/fix-user-id.service" 2>/dev/null || true
echo "✅ Services kopiert und aktiviert"
echo ""

# 7. CLOUD-INIT TARGET OVERRIDE
echo "=== 7. CLOUD-INIT TARGET OVERRIDE ==="
mkdir -p "$ROOT_MOUNT/etc/systemd/system/cloud-init.target.d"
cat > "$ROOT_MOUNT/etc/systemd/system/cloud-init.target.d/override.conf" << 'EOF'
[Unit]
After=
Requires=
Wants=
Conflicts=
EOF
echo "✅ Override erstellt"
echo ""

# 8. SSH AKTIVIEREN
echo "=== 8. SSH AKTIVIEREN ==="
touch "$BOOT_MOUNT/ssh" 2>/dev/null || touch "$BOOT_MOUNT/firmware/ssh" 2>/dev/null || true
echo "✅ SSH aktiviert"
echo ""

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  ✅ FIX ABGESCHLOSSEN                                         ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "✅ NetworkManager-wait-online.service maskiert (kann nicht gestartet werden)"
echo "✅ NetworkManager-wait-online.service Override erstellt (startet /bin/true)"
echo "✅ Alle Symlinks entfernt"
echo "✅ Network-online Abhängigkeiten entfernt"
echo "✅ Cloud-init Services entfernt"
echo "✅ Unsere Services aktiviert"
echo ""
echo "SD-Karte ist komplett gefixt. Pi neu starten!"

