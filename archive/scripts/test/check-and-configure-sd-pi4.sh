#!/bin/bash
# Prüfe und konfiguriere moOde Audio SD-Karte für Pi 4

SD_DEVICE="/dev/disk4"
BOOT_MOUNT="/Volumes/bootfs"

echo "=== MOODE PI 4 SD-KARTE PRÜFUNG & KONFIGURATION ==="
echo ""

# Warte bis SD-Karte gemountet ist
echo "Warte auf SD-Karte..."
for i in {1..30}; do
    if [ -d "$BOOT_MOUNT" ] && [ -f "$BOOT_MOUNT/config.txt" ]; then
        echo "✅ SD-Karte gefunden!"
        break
    else
        echo "Warte... ($i/30)"
        sleep 2
    fi
done

if [ ! -f "$BOOT_MOUNT/config.txt" ]; then
    echo "❌ SD-Karte nicht gefunden oder nicht gemountet"
    echo "Bitte SD-Karte einstecken und erneut versuchen"
    exit 1
fi

echo ""
echo "=== SYSTEM-IDENTIFIKATION ==="
echo "Hostname: $(cat $BOOT_MOUNT/hostname 2>/dev/null || echo 'nicht gefunden')"
echo "OS: $(grep -i 'moode\|raspios' $BOOT_MOUNT/config.txt $BOOT_MOUNT/cmdline.txt 2>/dev/null | head -1 || echo 'moOde Audio (vermutet)')"
echo ""

echo "=== AKTUELLE CONFIG.TXT ==="
grep -E "display_rotate|hifiberry|vc4|dtoverlay" "$BOOT_MOUNT/config.txt" | head -10
echo ""

echo "=== KONFIGURIERE FÜR PI 4 ==="

# Backup erstellen
BACKUP_FILE="$BOOT_MOUNT/config.txt.backup-$(date +%Y%m%d_%H%M%S)"
cp "$BOOT_MOUNT/config.txt" "$BACKUP_FILE"
echo "✅ Backup erstellt: $(basename $BACKUP_FILE)"

# Konfiguration für Pi 4 anpassen
echo ""
echo "Konfiguriere für Pi 4 mit WaveShare Display..."

# Entferne Pi 5 spezifische Overlays
sed -i '' '/dtoverlay=hifiberry-amp100-pi5/d' "$BOOT_MOUNT/config.txt"
sed -i '' '/dtoverlay=vc4-kms-v3d-pi5/d' "$BOOT_MOUNT/config.txt"

# Füge Pi 4 Konfiguration hinzu
if ! grep -q "^display_rotate=3" "$BOOT_MOUNT/config.txt"; then
    echo "" >> "$BOOT_MOUNT/config.txt"
    echo "# Display Rotation (Landscape 270°)" >> "$BOOT_MOUNT/config.txt"
    echo "display_rotate=3" >> "$BOOT_MOUNT/config.txt"
fi

if ! grep -q "^dtoverlay=vc4-kms-v3d" "$BOOT_MOUNT/config.txt"; then
    echo "" >> "$BOOT_MOUNT/config.txt"
    echo "# VC4 KMS für Pi 4" >> "$BOOT_MOUNT/config.txt"
    echo "dtoverlay=vc4-kms-v3d,audio=off" >> "$BOOT_MOUNT/config.txt"
fi

# HiFiBerry Overlay (falls vorhanden, für Pi 4 anpassen)
if grep -q "hifiberry" "$BOOT_MOUNT/config.txt"; then
    echo "⚠️ HiFiBerry Overlay gefunden - bitte manuell für Pi 4 anpassen"
fi

echo ""
echo "=== NEUE CONFIG.TXT ==="
grep -E "display_rotate|hifiberry|vc4|dtoverlay" "$BOOT_MOUNT/config.txt" | head -10
echo ""

echo "✅ SD-Karte konfiguriert!"
echo ""
echo "Nächste Schritte:"
echo "1. SD-Karte in Pi 4 einstecken"
echo "2. Pi 4 booten"
echo "3. System prüfen"

