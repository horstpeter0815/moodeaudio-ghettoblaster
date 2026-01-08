#!/bin/bash
# BEHEBE ROTATION-PROBLEM - Ghetto Pi 5

PI_IP="192.168.178.178"
PI_USER="andre"
PI_PASS="0815"

echo "=== BEHEBE ROTATION-PROBLEM ==="
echo ""

sshpass -p "$PI_PASS" ssh -o StrictHostKeyChecking=no "$PI_USER@$PI_IP" << 'FIX_ROTATION'
set -e
export DISPLAY=:0

echo "1. Aktueller Display-Status:"
xrandr --output HDMI-A-2 --query 2>/dev/null | grep -E "current|connected|primary" || echo "Display nicht erkannt"
echo ""

echo "2. Verfügbare Modi:"
xrandr --output HDMI-A-2 --query 2>/dev/null | grep -E "^\s+[0-9]+x[0-9]+" | head -5
echo ""

echo "3. Prüfe xinitrc:"
if [ -f /home/andre/.xinitrc ]; then
    echo "   Aktuelle xrandr Befehle:"
    grep -n "xrandr" /home/andre/.xinitrc | head -5
else
    echo "   xinitrc nicht gefunden"
fi
echo ""

echo "4. Fixe Rotation in xinitrc:"
if [ -f /home/andre/.xinitrc ]; then
    # Backup
    cp /home/andre/.xinitrc /home/andre/.xinitrc.backup.$(date +%Y%m%d_%H%M%S)
    
    # Entferne alte Rotation-Befehle
    sed -i '/xrandr.*rotate/d' /home/andre/.xinitrc
    
    # Finde HDMI-A-2 xrandr Befehl und füge Rotation hinzu
    if grep -q "xrandr.*HDMI-A-2.*--mode" /home/andre/.xinitrc; then
        # Ersetze mit Rotation
        sed -i 's/xrandr --output HDMI-A-2 --mode \([0-9]*x[0-9]*\)/xrandr --output HDMI-A-2 --mode \1 --rotate right/' /home/andre/.xinitrc
        echo "   ✅ Rotation hinzugefügt"
    else
        # Füge neuen Befehl hinzu (vor Chromium)
        if grep -q "chromium" /home/andre/.xinitrc; then
            sed -i '/chromium/i xrandr --output HDMI-A-2 --mode 1280x400 --rotate right || xrandr --output HDMI-A-2 --mode 400x1280 --rotate right' /home/andre/.xinitrc
            echo "   ✅ Rotation-Befehl hinzugefügt"
        fi
    fi
    
    echo "   Neue xrandr Befehle:"
    grep "xrandr" /home/andre/.xinitrc | head -3
else
    echo "   xinitrc nicht gefunden - erstelle sie"
fi
echo ""

echo "5. Fixe Touchscreen Matrix für Rotation:"
if [ -f /etc/X11/xorg.conf.d/99-touchscreen.conf ]; then
    # Backup
    sudo cp /etc/X11/xorg.conf.d/99-touchscreen.conf /etc/X11/xorg.conf.d/99-touchscreen.conf.backup.$(date +%Y%m%d_%H%M%S)
    
    # Setze Matrix für right rotation: 0 1 0 -1 0 1 0 0 1
    sudo sed -i 's/Option "TransformationMatrix".*/Option "TransformationMatrix" "0 1 0 -1 0 1 0 0 1"/' /etc/X11/xorg.conf.d/99-touchscreen.conf
    echo "   ✅ Touchscreen Matrix für right rotation gesetzt"
    cat /etc/X11/xorg.conf.d/99-touchscreen.conf
else
    echo "   Touchscreen Config nicht gefunden"
fi
echo ""

echo "6. Teste Rotation jetzt:"
xrandr --output HDMI-A-2 --mode 1280x400 --rotate right 2>&1 || xrandr --output HDMI-A-2 --mode 400x1280 --rotate right 2>&1
sleep 2
xrandr --output HDMI-A-2 --query 2>/dev/null | grep -E "current|connected"
echo ""

echo "7. Erstelle Screenshot:"
if command -v scrot >/dev/null 2>&1; then
    scrot /tmp/display_after_rotation.png 2>/dev/null && echo "   ✅ Screenshot: /tmp/display_after_rotation.png"
elif command -v import >/dev/null 2>&1; then
    import -window root /tmp/display_after_rotation.png 2>/dev/null && echo "   ✅ Screenshot: /tmp/display_after_rotation.png"
else
    echo "   ⚠️  Screenshot-Tool nicht verfügbar"
fi
echo ""

echo "✅ Rotation-Fix angewendet - Reboot empfohlen"
FIX_ROTATION

echo ""
echo "✅ Rotation-Fix abgeschlossen"

