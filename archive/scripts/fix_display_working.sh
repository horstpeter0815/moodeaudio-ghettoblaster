#!/bin/bash
# FIXE DISPLAY - Direkt ausführbar

PI_IP="192.168.178.178"
PI_USER="andre"
PI_PASS="0815"

echo "=== FIXE DISPLAY JETZT ==="

sshpass -p "$PI_PASS" ssh -o StrictHostKeyChecking=no "$PI_USER@$PI_IP" bash << 'FIX'
set -e
export DISPLAY=:0

echo "1. Prüfe Display..."
xrandr --output HDMI-A-2 --query 2>/dev/null | grep -E "current|rotation" | head -2
echo ""

echo "2. Finde Modus und wende Rotation an..."
MODE=$(xrandr --output HDMI-A-2 --query 2>/dev/null | grep -E "^\s+[0-9]+x[0-9]+" | awk '{print $1}' | head -1)
echo "Modus: $MODE"
xrandr --output HDMI-A-2 --mode "$MODE" --rotate right
sleep 1
xrandr --fb 1280x400
echo "Status:"
xrandr --output HDMI-A-2 --query 2>/dev/null | grep -E "current|rotation" | head -2
echo ""

echo "3. Fixe xinitrc..."
cp /home/andre/.xinitrc /home/andre/.xinitrc.backup.$(date +%Y%m%d_%H%M%S) 2>/dev/null || true
sed -i '/xrandr.*HDMI-A-2/d' /home/andre/.xinitrc 2>/dev/null || true

if grep -q "chromium" /home/andre/.xinitrc; then
    CHROMIUM_LINE=$(grep -n "chromium" /home/andre/.xinitrc | head -1 | cut -d: -f1)
    sed -i "${CHROMIUM_LINE}i xrandr --output HDMI-A-2 --mode $MODE --rotate right" /home/andre/.xinitrc
    sed -i "${CHROMIUM_LINE}i xrandr --fb 1280x400" /home/andre/.xinitrc
    sed -i "${CHROMIUM_LINE}i sleep 2" /home/andre/.xinitrc
else
    echo "xrandr --output HDMI-A-2 --mode $MODE --rotate right" >> /home/andre/.xinitrc
    echo "xrandr --fb 1280x400" >> /home/andre/.xinitrc
fi

chmod +x /home/andre/.xinitrc
echo "✅ xinitrc gefixt"
grep "xrandr.*HDMI-A-2" /home/andre/.xinitrc | head -3
echo ""

echo "4. Fixe Touchscreen..."
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
echo "✅ Touchscreen gefixt"
echo ""

echo "5. Verifiziere..."
xrandr --output HDMI-A-2 --query 2>/dev/null | grep -E "current|rotation" | head -2
xdpyinfo 2>/dev/null | grep dimensions | head -1
echo ""

echo "✅ DISPLAY GEFIXT"
FIX

echo ""
echo "✅ FERTIG - Display sollte jetzt im Landscape-Modus sein"

