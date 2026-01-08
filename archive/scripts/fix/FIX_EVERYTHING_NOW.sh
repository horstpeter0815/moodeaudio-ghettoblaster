#!/bin/bash
# FIXE ALLES JETZT - KEINE AUSREDEN

PI_IP="192.168.178.178"
PI_USER="andre"
PI_PASS="0815"

echo "=== FIXE ROTATION JETZT - KEINE AUSREDEN ==="

sshpass -p "$PI_PASS" ssh -o StrictHostKeyChecking=no "$PI_USER@$PI_IP" bash << 'FIX'
set -e
export DISPLAY=:0

echo "1. Aktuelle Situation:"
xrandr --output HDMI-A-2 --query 2>/dev/null | grep -E "current|rotation" | head -2
echo ""

echo "2. Finde Modus und wende Rotation an:"
MODE=$(xrandr --output HDMI-A-2 --query 2>/dev/null | grep -E "^\s+[0-9]+x[0-9]+" | awk '{print $1}' | head -1)
echo "Modus: $MODE"
xrandr --output HDMI-A-2 --mode "$MODE" --rotate right
sleep 1
xrandr --fb 1280x400
xrandr --output HDMI-A-2 --query 2>/dev/null | grep -E "current|rotation" | head -2
echo ""

echo "3. Fixe xinitrc PERMANENT:"
cp /home/andre/.xinitrc /home/andre/.xinitrc.backup.$(date +%Y%m%d_%H%M%S) 2>/dev/null || true
sed -i '/xrandr.*HDMI-A-2/d' /home/andre/.xinitrc 2>/dev/null || true

if grep -q "chromium" /home/andre/.xinitrc; then
    sed -i "/chromium/i xrandr --output HDMI-A-2 --mode $MODE --rotate right" /home/andre/.xinitrc
    sed -i "/chromium/i xrandr --fb 1280x400" /home/andre/.xinitrc
    sed -i "/chromium/i sleep 2" /home/andre/.xinitrc
else
    sed -i "1i xrandr --output HDMI-A-2 --mode $MODE --rotate right" /home/andre/.xinitrc
    sed -i "2i xrandr --fb 1280x400" /home/andre/.xinitrc
fi

echo "xinitrc Rotation:"
grep "xrandr.*HDMI-A-2" /home/andre/.xinitrc | head -3
echo ""

echo "4. Fixe Touchscreen:"
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
echo "✅ Touchscreen Matrix gesetzt"
echo ""

echo "5. Verifiziere JETZT:"
xrandr --output HDMI-A-2 --query 2>/dev/null | grep -E "current|rotation" | head -2
xdpyinfo 2>/dev/null | grep dimensions | head -1
echo ""

echo "✅ ROTATION GEFIXT - SOLLTE JETZT FUNKTIONIEREN"
FIX

echo ""
echo "✅ FERTIG - Rotation sollte jetzt funktionieren"

