#!/bin/bash
################################################################################
#
# Apply pi-gen Override Mechanisms to Standard moOde Image (SD Card)
# Wendet die gleichen Override-Mechanismen an wie im Custom-Build
#
################################################################################

set -e

if [ "$EUID" -ne 0 ]; then 
    echo "❌ Bitte mit sudo ausführen!"
    echo "   sudo $0"
    exit 1
fi

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  🔧 APPLY PI-GEN OVERRIDES TO SD CARD                      ║"
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

# === 1. APPLY config.txt.overwrite (wie in pi-gen) ===
echo "=== 1. Apply config.txt.overwrite (pi-gen Override) ==="

SCRIPT_DIR="/Users/andrevollmer/moodeaudio-cursor"
CONFIG_OVERWRITE="$SCRIPT_DIR/moode-source/boot/firmware/config.txt.overwrite"

if [ -f "$CONFIG_OVERWRITE" ]; then
    echo "📋 Kopiere config.txt.overwrite → config.txt..."
    cp "$CONFIG_OVERWRITE" "$BOOT_MOUNT/config.txt"
    echo "✅ config.txt.overwrite angewendet (wie in pi-gen Stage 1)"
else
    echo "⚠️  config.txt.overwrite nicht gefunden: $CONFIG_OVERWRITE"
    echo "   Prüfe ob moOde Headers in aktueller config.txt vorhanden sind..."
    if ! grep -q "# This file is managed by moOde" "$BOOT_MOUNT/config.txt"; then
        echo "⚠️  Keine moOde Headers gefunden!"
        echo "   Füge Header hinzu..."
        # Füge Header in Zeile 2 ein
        sed -i.bak '2i\
# This file is managed by moOde\
' "$BOOT_MOUNT/config.txt"
        echo "✅ moOde Header hinzugefügt"
    else
        echo "✅ moOde Headers bereits vorhanden"
    fi
fi

echo ""

# === 2. BACKUP CURRENT config.txt ===
echo "=== 2. Backup current config.txt ==="
cp "$BOOT_MOUNT/config.txt" "$BOOT_MOUNT/config.txt.pi-gen-override-backup"
echo "✅ Backup erstellt: config.txt.pi-gen-override-backup"
echo ""

# === 3. VERIFY HEADERS ===
echo "=== 3. Verify moOde Headers ==="
if grep -q "# This file is managed by moOde" "$BOOT_MOUNT/config.txt"; then
    HEADER_LINE=$(grep -n "# This file is managed by moOde" "$BOOT_MOUNT/config.txt" | cut -d: -f1)
    echo "✅ moOde Header gefunden in Zeile: $HEADER_LINE"
    if [ "$HEADER_LINE" = "2" ]; then
        echo "✅ Header in korrekter Position (Zeile 2) - wird von worker.php erkannt"
    else
        echo "⚠️  Header in Zeile $HEADER_LINE (sollte Zeile 2 sein)"
    fi
else
    echo "❌ Keine moOde Headers gefunden!"
fi

echo ""

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  ✅ PI-GEN OVERRIDES APPLIED                                 ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "📋 Angewendet:"
echo "   ✅ config.txt.overwrite → config.txt (wie pi-gen Stage 1)"
echo "   ✅ Backup erstellt"
echo "   ✅ Headers verifiziert"
echo ""
echo "📋 Nächste Schritte:"
echo "   1. SD-Karte auswerfen"
echo "   2. SD-Karte in Pi einstecken"
echo "   3. Pi booten"
echo "   4. config.txt sollte nicht mehr überschrieben werden"
echo ""

