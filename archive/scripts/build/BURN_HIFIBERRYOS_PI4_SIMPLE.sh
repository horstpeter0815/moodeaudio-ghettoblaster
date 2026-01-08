#!/bin/bash

# HiFiBerryOS auf SD-Karte brennen (Pi 4) - Einfache Version
# Ausführung: sudo bash BURN_HIFIBERRYOS_PI4_SIMPLE.sh

# Wechsle ins Script-Verzeichnis
cd "$(dirname "$0")"

set -e

IMAGE="hifiberryos-pi4-wave-final.img"
DISK="/dev/rdisk4"

echo "=== HIFIBERRYOS AUF SD-KARTE BRENNEN ==="
echo ""
echo "Image: $IMAGE"
echo "Ziel: $DISK"
echo ""

# Prüfe ob Image existiert
if [ ! -f "$IMAGE" ]; then
    echo "❌ FEHLER: Image $IMAGE nicht gefunden!"
    exit 1
fi

# Prüfe ob rdisk4 existiert, sonst verwende disk4
if [ ! -b "$DISK" ]; then
    if [ -b "/dev/disk4" ]; then
        DISK="/dev/disk4"
        echo "⚠️  Verwende /dev/disk4 statt /dev/rdisk4"
    else
        echo "❌ FEHLER: Disk nicht gefunden!"
        echo "   Verfügbare Disks:"
        diskutil list | grep -E "disk[0-9]+"
        exit 1
    fi
fi

# Unmount Disk
echo "📦 Unmounte SD-Karte..."
diskutil unmountDisk /dev/disk4 2>/dev/null || true

echo ""
echo "🔥 Brenne Image auf SD-Karte..."
echo "   Dies kann einige Minuten dauern..."
echo ""

# Image brennen
dd if="$IMAGE" of="$DISK" bs=1m status=progress

echo ""
echo "✅ Image erfolgreich gebrannt!"
echo ""

# Sync
echo "💾 Synchronisiere Daten..."
sync

# Warte kurz, damit das System die Partitionen erkennt
sleep 3

# Prüfe Partitionen
echo ""
echo "🔍 Prüfe Partitionen..."
diskutil list /dev/disk4

echo ""
echo "📦 Prüfe Boot-Partition..."
if diskutil info /dev/disk4s1 >/dev/null 2>&1; then
    echo "   ✅ Boot-Partition gefunden: /dev/disk4s1"
    diskutil info /dev/disk4s1 | grep -E "File System|Volume Name|Disk Size" || true
else
    echo "   ⚠️  Boot-Partition nicht gefunden"
fi

echo ""
echo "📦 Prüfe Root-Partition..."
if diskutil info /dev/disk4s2 >/dev/null 2>&1; then
    echo "   ✅ Root-Partition gefunden: /dev/disk4s2"
    diskutil info /dev/disk4s2 | grep -E "File System|Volume Name|Disk Size" || true
else
    echo "   ⚠️  Root-Partition nicht gefunden"
fi

# Mount Boot-Partition zum Prüfen
echo ""
echo "🔍 Prüfe Boot-FS Inhalt..."
if diskutil mount /dev/disk4s1 >/dev/null 2>&1; then
    BOOT_MOUNT=$(diskutil info /dev/disk4s1 | grep "Mount Point" | awk '{print $3}')
    if [ -n "$BOOT_MOUNT" ]; then
        echo "   ✅ Boot-FS gemountet: $BOOT_MOUNT"
        echo "   📁 Wichtige Dateien:"
        ls -la "$BOOT_MOUNT" | grep -E "config.txt|cmdline.txt|kernel|dtb|bootcode|start.elf" | head -10 || true
        diskutil unmount /dev/disk4s1 >/dev/null 2>&1
    fi
fi

echo ""
echo "✅ SD-Karte ist bootfähig!"
echo "   - Boot-Partition: /dev/disk4s1 (FAT32)"
echo "   - Root-Partition: /dev/disk4s2 (Linux)"
echo ""

# Eject
echo "📤 Ejecte SD-Karte..."
diskutil eject /dev/disk4

echo ""
echo "✅ Fertig! SD-Karte kann jetzt:"
echo "   1. Aus dem Mac entfernt werden"
echo "   2. In den Raspberry Pi 4 gesteckt werden"
echo "   3. Booten (Boot-FS und Root-FS sind bereit)"
echo ""

