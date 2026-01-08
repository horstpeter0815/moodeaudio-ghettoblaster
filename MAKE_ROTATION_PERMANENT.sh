#!/bin/bash
# MACHE ROTATION PERMANENT - FUNKTIONIERT NACH JEDEM REBOOT

PI_IP="192.168.178.178"
PI_USER="andre"
PI_PASS="0815"

echo "=== MACHE ROTATION PERMANENT ==="

sshpass -p "$PI_PASS" ssh -o StrictHostKeyChecking=no "$PI_USER@$PI_IP" bash << 'MAKE_PERMANENT'
set -e
export DISPLAY=:0

echo "1. Prüfe aktuelle config.txt..."
grep -A 10 "^\[pi5\]" /boot/firmware/config.txt | head -10
echo ""

echo "2. Prüfe xinitrc..."
if [ -f /home/andre/.xinitrc ]; then
    echo "xinitrc existiert"
    grep "xrandr.*HDMI-A-2" /home/andre/.xinitrc | head -3 || echo "Keine Rotation in xinitrc"
else
    echo "xinitrc existiert NICHT - erstelle sie"
fi
echo ""

echo "3. MACHE ROTATION PERMANENT IN XINITRC..."
# Backup
cp /home/andre/.xinitrc /home/andre/.xinitrc.backup.$(date +%Y%m%d_%H%M%S) 2>/dev/null || true

# Finde Modus
MODE=$(xrandr --output HDMI-A-2 --query 2>/dev/null | grep -E "^\s+[0-9]+x[0-9]+" | awk '{print $1}' | head -1)
echo "Verwende Modus: $MODE"

# Entferne ALLE alten xrandr Befehle
sed -i '/xrandr.*HDMI-A-2/d' /home/andre/.xinitrc 2>/dev/null || true
sed -i '/xrandr.*rotate/d' /home/andre/.xinitrc 2>/dev/null || true
sed -i '/xrandr.*fb/d' /home/andre/.xinitrc 2>/dev/null || true

# Erstelle NEUE xinitrc wenn nicht existiert
if [ ! -f /home/andre/.xinitrc ] || [ ! -s /home/andre/.xinitrc ]; then
    cat > /home/andre/.xinitrc << 'XINITRC_BASE'
#!/bin/bash
export DISPLAY=:0
sleep 2
XINITRC_BASE
fi

# Füge Rotation VOR Chromium ein (wenn Chromium existiert)
if grep -q "chromium" /home/andre/.xinitrc; then
    # Finde Chromium-Zeile
    CHROMIUM_LINE=$(grep -n "chromium" /home/andre/.xinitrc | head -1 | cut -d: -f1)
    # Füge Rotation-Befehle VOR Chromium ein
    sed -i "${CHROMIUM_LINE}i xrandr --output HDMI-A-2 --mode $MODE --rotate right" /home/andre/.xinitrc
    sed -i "${CHROMIUM_LINE}i xrandr --fb 1280x400" /home/andre/.xinitrc
    sed -i "${CHROMIUM_LINE}i sleep 1" /home/andre/.xinitrc
else
    # Füge am Ende ein
    echo "xrandr --output HDMI-A-2 --mode $MODE --rotate right" >> /home/andre/.xinitrc
    echo "xrandr --fb 1280x400" >> /home/andre/.xinitrc
fi

chmod +x /home/andre/.xinitrc
echo "✅ xinitrc PERMANENT gefixt"
echo ""
echo "xinitrc Rotation-Befehle:"
grep "xrandr.*HDMI-A-2" /home/andre/.xinitrc | head -5
echo ""

echo "4. MACHE TOUCHSCREEN PERMANENT..."
sudo mkdir -p /etc/X11/xorg.conf.d
sudo tee /etc/X11/xorg.conf.d/99-touchscreen.conf > /dev/null << 'TOUCH'
Section "InputClass"
    Identifier "WaveShare Touchscreen"
    MatchUSBID "0712:000a"
    MatchIsTouchscreen "on"
    Driver "libinput"
    Option "TransformationMatrix" "0 1 0 -1 0 1 0 0 1"
EndSection
TOUCH
echo "✅ Touchscreen Matrix PERMANENT gesetzt"
echo ""

echo "5. Prüfe config.txt - stelle sicher display_rotate=0..."
if ! grep -q "^display_rotate=0" /boot/firmware/config.txt; then
    # Füge in [pi5] Sektion ein
    if grep -q "^\[pi5\]" /boot/firmware/config.txt; then
        sed -i "/^\[pi5\]/a display_rotate=0" /boot/firmware/config.txt
        echo "✅ display_rotate=0 hinzugefügt"
    fi
fi
echo ""

echo "6. Wende Rotation JETZT an..."
xrandr --output HDMI-A-2 --mode "$MODE" --rotate right 2>&1
sleep 1
xrandr --fb 1280x400 2>&1
echo "✅ Rotation angewendet"
echo ""

echo "7. FINALE VERIFIZIERUNG..."
echo "Display-Status:"
xrandr --output HDMI-A-2 --query 2>/dev/null | grep -E "current|rotation" | head -2
echo ""
echo "X11 Screen:"
xdpyinfo 2>/dev/null | grep dimensions | head -1
echo ""
echo "xinitrc Datei:"
ls -lh /home/andre/.xinitrc
echo ""
echo "Touchscreen Config:"
ls -lh /etc/X11/xorg.conf.d/99-touchscreen.conf
echo ""

echo "✅ ROTATION IST JETZT PERMANENT - FUNKTIONIERT NACH JEDEM REBOOT"
MAKE_PERMANENT

echo ""
echo "✅ FERTIG - Rotation ist jetzt permanent"

