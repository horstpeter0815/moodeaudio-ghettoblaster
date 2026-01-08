#!/bin/bash
################################################################################
# KOMPLETTES SYSTEM-SETUP FÜR MOODE AUDIO PI 5
# Direkt auf dem Pi ausführen: sudo bash SETUP_ON_PI.sh
################################################################################

set -e

echo "============================================================"
echo "KOMPLETTES SYSTEM-SETUP FÜR MOODE AUDIO PI 5"
echo "============================================================"
echo ""

# Backup erstellen
echo "=== 1. BACKUP ERSTELLEN ==="
BACKUP_DIR="/home/andre/backup_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"
sudo cp /boot/firmware/config.txt "$BACKUP_DIR/config.txt.backup" 2>/dev/null || true
sudo cp /boot/firmware/cmdline.txt "$BACKUP_DIR/cmdline.txt.backup" 2>/dev/null || true
sudo cp /home/andre/.xinitrc "$BACKUP_DIR/xinitrc.backup" 2>/dev/null || true
sudo cp /etc/X11/xorg.conf.d/99-touchscreen.conf "$BACKUP_DIR/99-touchscreen.conf.backup" 2>/dev/null || true
echo "✅ Backup erstellt: $BACKUP_DIR"
echo ""

# Remount /boot/firmware
echo "=== 2. REMOUNT /BOOT/FIRMWARE ==="
sudo mount -o remount,rw /boot/firmware
echo "✅ /boot/firmware ist READ-WRITE"
echo ""

# Display-Konfiguration
echo "=== 3. DISPLAY-KONFIGURATION ==="
sudo tee /boot/firmware/config.txt > /dev/null << 'EOF'
# Moode Audio - Pi 5 - Display Configuration
# Waveshare 7.9" HDMI - 1280x400 Landscape
# Verbesserte Timing-Parameter gegen Streifen/Display-Probleme

[all]
# Disable firmware KMS setup - verwende True KMS
disable_fw_kms_setup=1

# Framebuffer
framebuffer_width=1280
framebuffer_height=400

[pi5]
# Display Rotation - 0 = normal (landscape)
display_rotate=0

# HDMI Configuration - Custom Mode für präzise Timings
hdmi_force_hotplug=1
hdmi_ignore_edid=0xa5000080
hdmi_group=2
hdmi_mode=87

# Custom Video Timings - Versuche 30Hz (sehr konservativ für stabile Timings)
# Format: hdmi_cvt=<width> <height> <framerate> <aspect> <margins> <interlace> <rb>
hdmi_cvt=1280 400 58 0 0 0 0

# Zusätzliche Timing-Parameter für Stabilität
hdmi_drive=2
hdmi_pixel_freq_limit=400000000

# Maximale Signal-Stärke gegen Timing-Probleme (0-11)
config_hdmi_boost=11

# Weitere Stabilitäts-Optionen
hdmi_force_mode=1
hdmi_ignore_cec=1
hdmi_ignore_cec_init=1

# Zusätzliche Optionen für Pi 5
hdmi_enable_4kp60=0
max_framebuffers=2

# Disable Overscan
disable_overscan=1
EOF
echo "✅ config.txt konfiguriert"
echo ""

# cmdline.txt
echo "=== 4. CMDLINE.TXT KONFIGURATION ==="
# Entferne alte video= und consoleblank= Parameter
sudo sed -i 's/ video=[^ ]*//g' /boot/firmware/cmdline.txt
sudo sed -i 's/ consoleblank=[^ ]*//g' /boot/firmware/cmdline.txt

# Füge aktualisierte Parameter hinzu
if ! grep -q "video=HDMI-A-2:1280x400M@60" /boot/firmware/cmdline.txt; then
    sudo sed -i 's/$/ video=HDMI-A-2:1280x400M@60/' /boot/firmware/cmdline.txt
    echo "✅ video= Parameter hinzugefügt"
else
    echo "✅ video= Parameter bereits vorhanden"
fi

# Füge consoleblank=0 hinzu (permanente Deaktivierung)
if ! grep -q "consoleblank=0" /boot/firmware/cmdline.txt; then
    sudo sed -i 's/$/ consoleblank=0/' /boot/firmware/cmdline.txt
    echo "✅ consoleblank=0 hinzugefügt"
else
    echo "✅ consoleblank=0 bereits vorhanden"
fi
echo ""

# X11 und Chromium
echo "=== 5. X11 UND CHROMIUM KONFIGURATION ==="
sudo tee /home/andre/.xinitrc > /dev/null << 'EOF'
#!/bin/sh
# Moode Audio - X11 Startup Script
# Display: 1280x400 Landscape

# Warte auf X11
sleep 2

# Setze Display-Variablen
export DISPLAY=:0

# Warte auf HDMI-2
for i in 1 2 3 4 5; do
    if xrandr --output HDMI-2 --query 2>/dev/null | grep -q "connected"; then
        break
    fi
    sleep 1
done

# Setze Display-Modus (1280x400)
xrandr --output HDMI-2 --mode 1280x400 2>/dev/null || \
xrandr --output HDMI-2 --mode 400x1280 --rotate right 2>/dev/null || \
xrandr --output HDMI-2 --auto 2>/dev/null

# Setze Framebuffer-Größe
xrandr --fb 1280x400 2>/dev/null || true

# Deaktiviere Screen Blanking permanent
xset s off 2>/dev/null || true
xset -dpms 2>/dev/null || true
xset s noblank 2>/dev/null || true

# Starte Chromium in Kiosk-Mode
exec chromium-browser \
    --kiosk \
    --noerrdialogs \
    --disable-infobars \
    --disable-session-crashed-bubble \
    --disable-restore-session-state \
    --window-size=1280,400 \
    --start-fullscreen \
    http://localhost
EOF

sudo chown andre:andre /home/andre/.xinitrc
sudo chmod 755 /home/andre/.xinitrc
echo "✅ .xinitrc konfiguriert"
echo ""

# Touchscreen
echo "=== 6. TOUCHSCREEN-KONFIGURATION ==="
sudo mkdir -p /etc/X11/xorg.conf.d
sudo tee /etc/X11/xorg.conf.d/99-touchscreen.conf > /dev/null << 'EOF'
Section "InputClass"
    Identifier "WaveShare Touchscreen"
    MatchUSBID "0712:000a"
    MatchIsTouchscreen "on"
    Driver "libinput"
    Option "TransformationMatrix" "1 0 0 0 1 0 0 0 1"
EndSection
EOF
echo "✅ Touchscreen-Config erstellt"
echo ""

# Sync
echo "=== 7. SYNC ==="
sync
echo "✅ Sync abgeschlossen"
echo ""

# Verifikation
echo "=== 8. VERIFIKATION ==="
echo "config.txt:"
grep -E "display_rotate|hdmi_mode|disable_fw_kms_setup|framebuffer" /boot/firmware/config.txt || echo "  Keine relevanten Einträge"
echo ""
echo "cmdline.txt video= Parameter:"
grep "video=" /boot/firmware/cmdline.txt || echo "  Kein video= Parameter"
echo ""
echo ".xinitrc vorhanden:"
[[ -f /home/andre/.xinitrc ]] && echo "  ✅ Vorhanden" || echo "  ❌ Fehlt"
echo ""
echo "Touchscreen-Config vorhanden:"
[[ -f /etc/X11/xorg.conf.d/99-touchscreen.conf ]] && echo "  ✅ Vorhanden" || echo "  ❌ Fehlt"
echo ""

echo "============================================================"
echo "SETUP ABGESCHLOSSEN"
echo "============================================================"
echo ""
echo "Nächste Schritte:"
echo "1. Reboot: sudo reboot"
echo "2. Nach Reboot prüfen ob Display korrekt funktioniert"
echo "3. Video-Test ausführen: bash VIDEO_PIPELINE_TEST_SAFE.sh"
echo ""
echo "Backup-Verzeichnis: $BACKUP_DIR"
echo ""

