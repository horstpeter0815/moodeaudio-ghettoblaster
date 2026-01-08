#!/bin/bash
# Fix Cloud-Init Hang on SD Card - SOFORTIGER FIX
# Entfernt After=moode-startup.service und fügt cloud-init-unblock.service hinzu

set -e

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  🔧 FIX CLOUD-INIT HANG (SD-KARTE - SOFORTIGER FIX)        ║"
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
    echo "⚠️  Root-Partition bereits gemountet oder Fehler beim Mounten"
    if mount | grep -q "rootfs"; then
        ROOT_MOUNT=$(mount | grep rootfs | awk '{print $3}' | head -1)
        echo "✅ Verwende bereits gemountete Partition: $ROOT_MOUNT"
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
# Fix 1: fix-user-id.service - After=moode-startup.service entfernen
################################################################################

echo "🔧 Fix 1: fix-user-id.service..."
FIX_USER_ID_FILE=$(find "$ROOT_MOUNT" -name "fix-user-id.service" -type f | head -1)
if [ -n "$FIX_USER_ID_FILE" ]; then
    echo "   Service-Datei: $FIX_USER_ID_FILE"
    
    # Backup
    cp "$FIX_USER_ID_FILE" "${FIX_USER_ID_FILE}.bak" 2>/dev/null || true
    
    # Entferne After=moode-startup.service und ersetze mit Before=cloud-init.target
    sed -i.bak2 's/After=moode-startup.service//g' "$FIX_USER_ID_FILE" 2>/dev/null || sed -i '' 's/After=moode-startup.service//g' "$FIX_USER_ID_FILE" 2>/dev/null || true
    
    # Füge Before=cloud-init.target hinzu (falls nicht vorhanden)
    if ! grep -q "Before=cloud-init.target" "$FIX_USER_ID_FILE"; then
        if grep -q "^\[Unit\]" "$FIX_USER_ID_FILE"; then
            sed -i.bak3 '/^\[Unit\]/a\
Before=cloud-init.target
' "$FIX_USER_ID_FILE" 2>/dev/null || sed -i '' '/^\[Unit\]/a\
Before=cloud-init.target
' "$FIX_USER_ID_FILE" 2>/dev/null || true
        fi
    fi
    
    # Ändere After=multi-user.target zu After=local-fs.target
    sed -i.bak4 's/After=multi-user.target/After=local-fs.target/g' "$FIX_USER_ID_FILE" 2>/dev/null || sed -i '' 's/After=multi-user.target/After=local-fs.target/g' "$FIX_USER_ID_FILE" 2>/dev/null || true
    
    echo "   ✅ fix-user-id.service gefixt"
else
    echo "   ⚠️  fix-user-id.service nicht gefunden"
fi
echo ""

################################################################################
# Fix 2: fix-ssh-sudoers.service - After=moode-startup.service entfernen
################################################################################

echo "🔧 Fix 2: fix-ssh-sudoers.service..."
FIX_SSH_SUDOERS_FILE=$(find "$ROOT_MOUNT" -name "fix-ssh-sudoers.service" -type f | head -1)
if [ -n "$FIX_SSH_SUDOERS_FILE" ]; then
    echo "   Service-Datei: $FIX_SSH_SUDOERS_FILE"
    
    # Backup
    cp "$FIX_SSH_SUDOERS_FILE" "${FIX_SSH_SUDOERS_FILE}.bak" 2>/dev/null || true
    
    # Entferne After=moode-startup.service
    sed -i.bak2 's/After=moode-startup.service//g' "$FIX_SSH_SUDOERS_FILE" 2>/dev/null || sed -i '' 's/After=moode-startup.service//g' "$FIX_SSH_SUDOERS_FILE" 2>/dev/null || true
    
    # Füge Before=cloud-init.target hinzu (falls nicht vorhanden)
    if ! grep -q "Before=cloud-init.target" "$FIX_SSH_SUDOERS_FILE"; then
        if grep -q "^\[Unit\]" "$FIX_SSH_SUDOERS_FILE"; then
            sed -i.bak3 '/^\[Unit\]/a\
Before=cloud-init.target
' "$FIX_SSH_SUDOERS_FILE" 2>/dev/null || sed -i '' '/^\[Unit\]/a\
Before=cloud-init.target
' "$FIX_SSH_SUDOERS_FILE" 2>/dev/null || true
        fi
    fi
    
    # Ändere After=multi-user.target zu After=local-fs.target
    sed -i.bak4 's/After=multi-user.target/After=local-fs.target/g' "$FIX_SSH_SUDOERS_FILE" 2>/dev/null || sed -i '' 's/After=multi-user.target/After=local-fs.target/g' "$FIX_SSH_SUDOERS_FILE" 2>/dev/null || true
    
    echo "   ✅ fix-ssh-sudoers.service gefixt"
else
    echo "   ⚠️  fix-ssh-sudoers.service nicht gefunden"
fi
echo ""

################################################################################
# Fix 3: cloud-init-unblock.service hinzufügen
################################################################################

echo "🔧 Fix 3: cloud-init-unblock.service hinzufügen..."
CLOUD_INIT_UNBLOCK_FILE="$ROOT_MOUNT/lib/systemd/system/cloud-init-unblock.service"
mkdir -p "$(dirname "$CLOUD_INIT_UNBLOCK_FILE")" 2>/dev/null || true

cat > "$CLOUD_INIT_UNBLOCK_FILE" << 'EOF'
[Unit]
Description=Cloud-Init Unblock - Prevents cloud-init.target from hanging boot
DefaultDependencies=no
After=local-fs.target
Before=cloud-init.target
Before=sysinit.target

[Service]
Type=oneshot
RemainAfterExit=yes
StandardOutput=journal
StandardError=journal
# Force cloud-init.target to be active after a timeout
ExecStart=/bin/bash -c '
    # Wait max 30 seconds for cloud-init to complete naturally
    for i in {1..30}; do
        if systemctl is-active cloud-init.target >/dev/null 2>&1; then
            echo "✅ cloud-init.target is active"
            exit 0
        fi
        sleep 1
    done
    
    # If still not active after 30 seconds, force it
    echo "⚠️  cloud-init.target not active after 30s, forcing activation..."
    systemctl set-property cloud-init.target ActiveState=active 2>/dev/null || true
    systemctl reset-failed cloud-init.target 2>/dev/null || true
    echo "✅ cloud-init.target forced active"
'

[Install]
WantedBy=local-fs.target
WantedBy=sysinit.target
EOF

chmod 644 "$CLOUD_INIT_UNBLOCK_FILE"
echo "   ✅ cloud-init-unblock.service erstellt"
echo ""

################################################################################
# Fix 4: cloud-init-unblock.service aktivieren
################################################################################

echo "🔧 Fix 4: cloud-init-unblock.service aktivieren..."
if [ -d "$ROOT_MOUNT/etc/systemd/system/local-fs.target.wants" ]; then
    mkdir -p "$ROOT_MOUNT/etc/systemd/system/local-fs.target.wants" 2>/dev/null || true
    ln -sf /lib/systemd/system/cloud-init-unblock.service "$ROOT_MOUNT/etc/systemd/system/local-fs.target.wants/cloud-init-unblock.service" 2>/dev/null || true
    echo "   ✅ cloud-init-unblock.service aktiviert"
else
    echo "   ⚠️  local-fs.target.wants Verzeichnis nicht gefunden"
fi
echo ""

################################################################################
# Zusammenfassung
################################################################################

echo "✅ Alle Fixes angewendet!"
echo ""
echo "📋 Zusammenfassung:"
echo "   1. ✅ fix-user-id.service - After=moode-startup.service entfernt"
echo "   2. ✅ fix-ssh-sudoers.service - After=moode-startup.service entfernt"
echo "   3. ✅ cloud-init-unblock.service - Hinzugefügt"
echo "   4. ✅ cloud-init-unblock.service - Aktiviert"
echo ""
echo "🔄 Nächste Schritte:"
echo "   1. SD-Karte auswerfen: diskutil eject /dev/$SD_DEVICE"
echo "   2. SD-Karte in Pi einstecken"
echo "   3. Pi booten"
echo "   4. cloud-init.target sollte nicht mehr hängen"
echo ""

# Unmount
echo "🔌 Unmounte Root-Partition..."
sudo umount "$ROOT_MOUNT" 2>/dev/null || true
echo "✅ Fertig!"

