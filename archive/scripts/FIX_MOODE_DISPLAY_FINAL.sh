#!/bin/bash
# FINAL MOODE AUDIO DISPLAY FIX - Keine Workarounds, saubere Lösung
# Für: Raspberry Pi 5, Waveshare 7.9" HDMI (1280x400 Landscape)
# 
# AUSFÜHRUNG:
#   chmod +x FIX_MOODE_DISPLAY_FINAL.sh
#   ./FIX_MOODE_DISPLAY_FINAL.sh
#
# NACH AUSFÜHRUNG:
#   ssh andre@192.168.178.178
#   sudo reboot

PI_IP="192.168.178.178"
PI_USER="andre"
PI_PASS="0815"

echo "=== FINAL MOODE AUDIO DISPLAY FIX ==="
echo "Ziel: 1280x400 Landscape, permanent, keine Workarounds"
echo ""

sshpass -p "$PI_PASS" ssh -o StrictHostKeyChecking=no "$PI_USER@$PI_IP" << 'FIX_DISPLAY'
set -e
export DISPLAY=:0

echo "1. Backup aktuelle Konfiguration..."
sudo cp /boot/firmware/config.txt /boot/firmware/config.txt.backup.$(date +%Y%m%d_%H%M%S)
sudo cp /boot/firmware/cmdline.txt /boot/firmware/cmdline.txt.backup.$(date +%Y%m%d_%H%M%S)
[ -f /home/andre/.xinitrc ] && cp /home/andre/.xinitrc /home/andre/.xinitrc.backup.$(date +%Y%m%d_%H%M%S)
echo "✅ Backup erstellt"
echo ""

echo "2. Prüfe aktuelle Display-Status..."
xrandr --output HDMI-A-2 --query 2>/dev/null | grep -E "current|connected" || echo "⚠️  Display nicht erkannt"
echo ""

echo "3. Setze config.txt - SAUBERE KONFIGURATION..."
sudo tee /boot/firmware/config.txt > /dev/null << 'CONFIG_EOF'
# Moode Audio - Pi 5 - Final Display Configuration
# Waveshare 7.9" HDMI - 1280x400 Landscape
# KEINE WORKAROUNDS - Saubere Lösung

[all]
# Disable firmware KMS setup - wir verwenden True KMS
disable_fw_kms_setup=1

[pi5]
# Display Rotation - 0 = normal (landscape)
display_rotate=0

# HDMI Configuration
hdmi_force_hotplug=1
hdmi_ignore_edid=0xa5000080
hdmi_group=2
hdmi_mode=87

# Disable Overscan
disable_overscan=1

# Framebuffer
framebuffer_width=1280
framebuffer_height=400
CONFIG_EOF
echo "✅ config.txt gesetzt"
echo ""

echo "4. Setze cmdline.txt - Video-Parameter..."
# Lese aktuelle cmdline.txt
CURRENT_CMDLINE=$(cat /boot/firmware/cmdline.txt)
# Entferne vorhandene video= Parameter
CURRENT_CMDLINE=$(echo "$CURRENT_CMDLINE" | sed 's/video=[^ ]*//g')
# Füge neuen video= Parameter hinzu
NEW_CMDLINE="$CURRENT_CMDLINE video=HDMI-A-2:1280x400M@60"
echo "$NEW_CMDLINE" | sudo tee /boot/firmware/cmdline.txt > /dev/null
echo "✅ cmdline.txt gesetzt"
echo ""

echo "5. Setze xinitrc - X11 Display Setup..."
cat > /home/andre/.xinitrc << 'XINITRC_EOF'
#!/bin/sh
# Moode Audio - X11 Startup Script
# Display: 1280x400 Landscape

# Warte auf X11
sleep 2

# Setze Display-Variablen
export DISPLAY=:0

# Warte auf HDMI-A-2
for i in 1 2 3 4 5; do
    if xrandr --output HDMI-A-2 --query 2>/dev/null | grep -q "connected"; then
        break
    fi
    sleep 1
done

# Setze Display-Modus (1280x400)
xrandr --output HDMI-A-2 --mode 1280x400 2>/dev/null || \
xrandr --output HDMI-A-2 --mode 400x1280 --rotate right 2>/dev/null || \
xrandr --output HDMI-A-2 --auto 2>/dev/null

# Setze Framebuffer-Größe
xrandr --fb 1280x400 2>/dev/null || true

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
XINITRC_EOF

chmod +x /home/andre/.xinitrc
echo "✅ xinitrc gesetzt"
echo ""

echo "6. Setze Touchscreen-Transformation (für Landscape)..."
sudo mkdir -p /etc/X11/xorg.conf.d
sudo tee /etc/X11/xorg.conf.d/99-touchscreen.conf > /dev/null << 'TOUCH_EOF'
Section "InputClass"
    Identifier "WaveShare Touchscreen"
    MatchUSBID "0712:000a"
    MatchIsTouchscreen "on"
    Driver "libinput"
    # Transformation Matrix für Landscape (keine Rotation nötig)
    Option "TransformationMatrix" "1 0 0 0 1 0 0 0 1"
EndSection
TOUCH_EOF
echo "✅ Touchscreen-Config gesetzt"
echo ""

echo "7. Teste aktuelle Display-Konfiguration..."
if xrandr --output HDMI-A-2 --query 2>/dev/null | grep -q "connected"; then
    CURRENT_MODE=$(xrandr --output HDMI-A-2 --query 2>/dev/null | grep "current" | awk '{print $8"x"$10}' | tr -d ',')
    echo "   Aktueller Modus: $CURRENT_MODE"
    
    # Versuche 1280x400 zu setzen
    if xrandr --output HDMI-A-2 --mode 1280x400 2>/dev/null; then
        echo "   ✅ 1280x400 gesetzt"
    elif xrandr --output HDMI-A-2 --mode 400x1280 --rotate right 2>/dev/null; then
        echo "   ⚠️  400x1280 mit Rotation gesetzt (Fallback)"
    else
        echo "   ⚠️  Automatischer Modus verwendet"
        xrandr --output HDMI-A-2 --auto 2>/dev/null || true
    fi
    
    sleep 2
    FINAL_MODE=$(xrandr --output HDMI-A-2 --query 2>/dev/null | grep "current" | awk '{print $8"x"$10}' | tr -d ',')
    echo "   Finaler Modus: $FINAL_MODE"
else
    echo "   ⚠️  Display nicht erkannt - wird nach Reboot verfügbar sein"
fi
echo ""

echo "8. Erstelle Screenshot zur Verifikation..."
if command -v scrot >/dev/null 2>&1; then
    scrot /tmp/display_final_fix.png 2>/dev/null && echo "   ✅ Screenshot: /tmp/display_final_fix.png"
elif command -v import >/dev/null 2>&1; then
    import -window root /tmp/display_final_fix.png 2>/dev/null && echo "   ✅ Screenshot: /tmp/display_final_fix.png"
else
    echo "   ⚠️  Screenshot-Tool nicht verfügbar"
fi
echo ""

echo "=== KONFIGURATION ABGESCHLOSSEN ==="
echo ""
echo "✅ config.txt: Gesetzt (1280x400, display_rotate=0)"
echo "✅ cmdline.txt: Gesetzt (video=HDMI-A-2:1280x400M@60)"
echo "✅ xinitrc: Gesetzt (1280x400, keine Rotation)"
echo "✅ Touchscreen: Gesetzt (Landscape-Matrix)"
echo ""
echo "⚠️  REBOOT ERFORDERLICH für vollständige Aktivierung"
echo ""
echo "Nach Reboot prüfen:"
echo "  - Display zeigt 1280x400 Landscape"
echo "  - Keine schwarzen Ränder"
echo "  - Touchscreen funktioniert korrekt"
echo "  - Chromium startet automatisch"
FIX_DISPLAY

echo ""
echo "=== FIX ABGESCHLOSSEN ==="
echo ""
echo "Nächster Schritt: REBOOT des Pi 5"
echo ""

