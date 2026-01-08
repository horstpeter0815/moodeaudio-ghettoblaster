#!/bin/bash
# Read Boot Logs from SD Card
# Liest alle verfügbaren Boot-Logs von der gemounteten SD-Karte

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
BOOT_PARTITION="${SD_CARD}s1"

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  📋 BOOT-LOGS VON SD-KARTE LESEN                           ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "SD-Karte: $SD_CARD"
echo ""

# Prüfe Mount-Status
ROOT_MOUNT=$(diskutil info "$ROOT_PARTITION" 2>/dev/null | grep "Mount Point:" | awk -F': ' '{print $2}' | xargs || echo "")
BOOT_MOUNT=$(diskutil info "$BOOT_PARTITION" 2>/dev/null | grep "Mount Point:" | awk -F': ' '{print $2}' | xargs || echo "/Volumes/bootfs")

if [ -z "$ROOT_MOUNT" ]; then
    echo "⚠️  Root-Partition nicht gemountet - mounte jetzt..."
    diskutil mount "$ROOT_PARTITION" || {
        echo "❌ Konnte Root-Partition nicht mounten"
        exit 1
    }
    ROOT_MOUNT=$(diskutil info "$ROOT_PARTITION" 2>/dev/null | grep "Mount Point:" | awk -F': ' '{print $2}' | xargs || echo "")
fi

if [ -z "$ROOT_MOUNT" ]; then
    echo "❌ Konnte Root-Partition nicht mounten"
    exit 1
fi

echo "Root: $ROOT_MOUNT"
echo "Boot: $BOOT_MOUNT"
echo ""

# === 1. BOOT-DEBUG.LOG (unser custom logger) ===
echo "═══════════════════════════════════════════════════════════════"
echo "1. BOOT-DEBUG.LOG (Custom Logger)"
echo "═══════════════════════════════════════════════════════════════"
echo ""

if [ -f "$ROOT_MOUNT/var/log/boot-debug.log" ]; then
    echo "📄 /var/log/boot-debug.log:"
    echo ""
    tail -100 "$ROOT_MOUNT/var/log/boot-debug.log" 2>/dev/null || echo "   (kann nicht gelesen werden)"
    echo ""
else
    echo "⚠️  /var/log/boot-debug.log nicht gefunden"
    echo ""
fi

# === 2. BOOT-DEBUG.LOG AUF BOOT-PARTITION ===
if [ -d "$BOOT_MOUNT" ]; then
    echo "═══════════════════════════════════════════════════════════════"
    echo "2. BOOT-DEBUG.LOG (Boot Partition Backup)"
    echo "═══════════════════════════════════════════════════════════════"
    echo ""
    
    if [ -f "$BOOT_MOUNT/boot-debug.log" ]; then
        echo "📄 /boot/firmware/boot-debug.log:"
        echo ""
        tail -100 "$BOOT_MOUNT/boot-debug.log" 2>/dev/null || echo "   (kann nicht gelesen werden)"
        echo ""
    else
        echo "⚠️  /boot/firmware/boot-debug.log nicht gefunden"
        echo ""
    fi
fi

# === 3. SYSTEMD JOURNAL ===
echo "═══════════════════════════════════════════════════════════════"
echo "3. SYSTEMD JOURNAL (falls verfügbar)"
echo "═══════════════════════════════════════════════════════════════"
echo ""

if [ -d "$ROOT_MOUNT/var/log/journal" ]; then
    echo "📄 Systemd Journal gefunden"
    echo ""
    echo "Letzte Boot-Einträge (falls verfügbar):"
    # Versuche journalctl zu verwenden (funktioniert nur wenn wir chroot machen)
    echo "   (Journal kann nur im chroot gelesen werden)"
    echo ""
else
    echo "⚠️  Systemd Journal nicht gefunden"
    echo ""
fi

# === 4. DMESG LOGS ===
echo "═══════════════════════════════════════════════════════════════"
echo "4. KERNEL/DMESG LOGS"
echo "═══════════════════════════════════════════════════════════════"
echo ""

if [ -f "$ROOT_MOUNT/var/log/dmesg" ]; then
    echo "📄 /var/log/dmesg:"
    echo ""
    tail -50 "$ROOT_MOUNT/var/log/dmesg" 2>/dev/null || echo "   (kann nicht gelesen werden)"
    echo ""
elif [ -f "$ROOT_MOUNT/var/log/kern.log" ]; then
    echo "📄 /var/log/kern.log:"
    echo ""
    tail -50 "$ROOT_MOUNT/var/log/kern.log" 2>/dev/null || echo "   (kann nicht gelesen werden)"
    echo ""
else
    echo "⚠️  dmesg/kern.log nicht gefunden"
    echo ""
fi

# === 5. SYSTEMD SERVICE STATUS ===
echo "═══════════════════════════════════════════════════════════════"
echo "5. SERVICE STATUS (aus systemd)"
echo "═══════════════════════════════════════════════════════════════"
echo ""

echo "Prüfe welche Services aktiviert sind:"
echo ""

# Prüfe boot-complete-minimal
if [ -L "$ROOT_MOUNT/etc/systemd/system/local-fs.target.wants/boot-complete-minimal.service" ]; then
    echo "✅ boot-complete-minimal.service aktiviert"
else
    echo "❌ boot-complete-minimal.service NICHT aktiviert"
fi

# Prüfe cloud-init-unblock
if [ -L "$ROOT_MOUNT/etc/systemd/system/local-fs.target.wants/cloud-init-unblock.service" ]; then
    echo "✅ cloud-init-unblock.service aktiviert"
else
    echo "❌ cloud-init-unblock.service NICHT aktiviert"
fi

# Prüfe fix-user-id
if [ -L "$ROOT_MOUNT/etc/systemd/system/multi-user.target.wants/fix-user-id.service" ]; then
    echo "✅ fix-user-id.service aktiviert"
else
    echo "❌ fix-user-id.service NICHT aktiviert"
fi

# Prüfe NetworkManager-wait-online
if [ -L "$ROOT_MOUNT/etc/systemd/system/network-online.target.wants/NetworkManager-wait-online.service" ] || \
   [ -L "$ROOT_MOUNT/etc/systemd/system/multi-user.target.wants/NetworkManager-wait-online.service" ]; then
    echo "⚠️  NetworkManager-wait-online.service AKTIVIERT (sollte deaktiviert sein!)"
else
    echo "✅ NetworkManager-wait-online.service deaktiviert"
fi

echo ""

# === 6. CLOUD-INIT STATUS ===
echo "═══════════════════════════════════════════════════════════════"
echo "6. CLOUD-INIT KONFIGURATION"
echo "═══════════════════════════════════════════════════════════════"
echo ""

if [ -f "$ROOT_MOUNT/etc/systemd/system/cloud-init.target.d/override.conf" ]; then
    echo "✅ cloud-init.target Override vorhanden:"
    cat "$ROOT_MOUNT/etc/systemd/system/cloud-init.target.d/override.conf"
    echo ""
else
    echo "❌ cloud-init.target Override NICHT vorhanden"
    echo ""
fi

# Prüfe ob cloud-init Services deaktiviert sind
CLOUD_INIT_ENABLED=$(find "$ROOT_MOUNT/etc/systemd/system" -name "*cloud-init*.service" -type l 2>/dev/null | wc -l | xargs)
if [ "$CLOUD_INIT_ENABLED" -gt 0 ]; then
    echo "⚠️  $CLOUD_INIT_ENABLED cloud-init Services noch aktiviert:"
    find "$ROOT_MOUNT/etc/systemd/system" -name "*cloud-init*.service" -type l 2>/dev/null | head -5
    echo ""
else
    echo "✅ Alle cloud-init Services deaktiviert"
    echo ""
fi

# === 7. NETZWERK KONFIGURATION ===
echo "═══════════════════════════════════════════════════════════════"
echo "7. NETZWERK KONFIGURATION"
echo "═══════════════════════════════════════════════════════════════"
echo ""

if [ -f "$ROOT_MOUNT/etc/systemd/network/10-eth0-static.network" ]; then
    echo "✅ systemd-networkd Config vorhanden:"
    cat "$ROOT_MOUNT/etc/systemd/network/10-eth0-static.network"
    echo ""
else
    echo "⚠️  systemd-networkd Config nicht gefunden"
    echo ""
fi

if [ -f "$ROOT_MOUNT/etc/NetworkManager/system-connections/eth0-static.nmconnection" ]; then
    echo "✅ NetworkManager Config vorhanden"
    echo ""
else
    echo "⚠️  NetworkManager Config nicht gefunden"
    echo ""
fi

# === 8. SSH STATUS ===
echo "═══════════════════════════════════════════════════════════════"
echo "8. SSH STATUS"
echo "═══════════════════════════════════════════════════════════════"
echo ""

if [ -f "$BOOT_MOUNT/ssh" ] || [ -f "$BOOT_MOUNT/firmware/ssh" ]; then
    echo "✅ SSH-Flag vorhanden"
else
    echo "❌ SSH-Flag NICHT vorhanden"
fi
echo ""

# === ZUSAMMENFASSUNG ===
echo "═══════════════════════════════════════════════════════════════"
echo "ZUSAMMENFASSUNG"
echo "═══════════════════════════════════════════════════════════════"
echo ""
echo "Boot-Logs wurden gelesen von:"
echo "  Root: $ROOT_MOUNT"
echo "  Boot: $BOOT_MOUNT"
echo ""
echo "Prüfe die obigen Logs für Fehler oder Hinweise auf Boot-Probleme."

