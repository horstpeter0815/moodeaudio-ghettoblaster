#!/bin/bash
# Konfiguriere SD-Karte für Pi 4 mit Moode Audio

set -e

BOOTFS="/Volumes/bootfs"
CONFIG_FILE="$BOOTFS/config.txt"
CMDLINE_FILE="$BOOTFS/cmdline.txt"

# Prüfe ob SD-Karte gemountet ist
if [ ! -d "$BOOTFS" ]; then
    echo "❌ SD-Karte nicht gefunden!"
    echo "   Bitte SD-Karte einstecken und warten bis sie gemountet ist"
    echo "   Erwartetes Mount: $BOOTFS"
    exit 1
fi

echo "✅ SD-Karte gefunden: $BOOTFS"
echo ""

# Backup erstellen
echo "1. Erstelle Backup..."
BACKUP_DIR="$BOOTFS/backup-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"
cp "$CONFIG_FILE" "$BACKUP_DIR/config.txt.backup" 2>/dev/null || true
cp "$CMDLINE_FILE" "$BACKUP_DIR/cmdline.txt.backup" 2>/dev/null || true
echo "   ✅ Backup erstellt: $BACKUP_DIR"
echo ""

# config.txt konfigurieren
echo "2. Konfiguriere config.txt für Pi 4..."

# Entferne Pi-5-spezifische Einträge
sed -i.bak '/\[pi5\]/,/\[all\]/d' "$CONFIG_FILE" 2>/dev/null || true
sed -i.bak '/dtoverlay=vc4-kms-v3d-pi5/d' "$CONFIG_FILE" 2>/dev/null || true

# Füge Pi-4-Konfiguration hinzu
cat >> "$CONFIG_FILE" << 'CONFIG_EOF'

#########################################
# Moode Audio Konfiguration für Raspberry Pi 4
# Waveshare 7.9" HDMI LCD (1280x400)
#########################################

[pi4]
# Pi 4 spezifisches KMS Overlay
dtoverlay=vc4-kms-v3d-pi4,noaudio

[all]
# HDMI aktivieren für HDMI Waveshare Display
hdmi_ignore_hotplug=0
display_auto_detect=1
hdmi_force_hotplug=1
hdmi_blanking=0
hdmi_group=2
hdmi_mode=87
hdmi_cvt 1280 400 60 6 0 0 0
hdmi_drive=2

# I2C aktivieren
dtparam=i2c_arm=on
dtparam=i2c_arm_baudrate=100000
dtparam=i2c_vc=on

# Framebuffer aktivieren
fbcon=map=1

# Firmware-KMS aktivieren
disable_fw_kms_setup=0

# Allgemeine Einstellungen
arm_64bit=1
arm_boost=1
disable_splash=0
disable_overscan=1

# Power Management
WAKE_ON_GPIO=1
POWER_OFF_ON_HALT=0
CONFIG_EOF

echo "   ✅ config.txt konfiguriert"
echo ""

# cmdline.txt konfigurieren
echo "3. Konfiguriere cmdline.txt für Pi 4..."

# Prüfe ob video= Parameter bereits existiert
if grep -q "video=HDMI" "$CMDLINE_FILE" 2>/dev/null; then
    # Ersetze existierenden video= Parameter
    sed -i.bak 's/video=HDMI-A-[12]:[^ ]*/video=HDMI-A-1:400x1280M@60,rotate=90/' "$CMDLINE_FILE" 2>/dev/null || true
else
    # Füge video= Parameter hinzu
    sed -i.bak 's/$/ video=HDMI-A-1:400x1280M@60,rotate=90/' "$CMDLINE_FILE" 2>/dev/null || true
fi

# Stelle sicher, dass consoleblank=0 vorhanden ist
if ! grep -q "consoleblank=0" "$CMDLINE_FILE" 2>/dev/null; then
    sed -i.bak 's/$/ consoleblank=0/' "$CMDLINE_FILE" 2>/dev/null || true
fi

echo "   ✅ cmdline.txt konfiguriert"
echo ""

# Zeige Zusammenfassung
echo "=== KONFIGURATION ABGESCHLOSSEN ==="
echo ""
echo "config.txt:"
grep -E "\[pi4\]|dtoverlay.*pi4|hdmi_group|hdmi_mode|hdmi_cvt" "$CONFIG_FILE" | head -5
echo ""
echo "cmdline.txt:"
grep -o "video=HDMI[^ ]*" "$CMDLINE_FILE" || echo "   video= Parameter nicht gefunden"
echo ""
echo "✅ SD-Karte ist bereit für Pi 4!"
echo ""
echo "Nächste Schritte:"
echo "1. SD-Karte auswerfen"
echo "2. SD-Karte in Pi 4 einstecken"
echo "3. Pi 4 booten"
echo "4. Nach Boot: .xinitrc anpassen (siehe FORUM_SOLUTION_7.9_DISPLAY.md)"

