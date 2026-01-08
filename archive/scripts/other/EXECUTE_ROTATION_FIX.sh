#!/bin/bash
# FIXE ROTATION SOFORT - Ghetto Pi 5

PI_IP="192.168.178.178"
PI_USER="andre"
PI_PASS="0815"

echo "=== FIXE ROTATION JETZT ==="

sshpass -p "$PI_PASS" ssh -o StrictHostKeyChecking=no "$PI_USER@$PI_IP" bash << 'FIX'
set -e
export DISPLAY=:0

# Backup
cp /home/andre/.xinitrc /home/andre/.xinitrc.backup.$(date +%Y%m%d_%H%M%S) 2>/dev/null || true

# Finde Modus
MODE=$(xrandr --output HDMI-A-2 --query 2>/dev/null | grep -E "^\s+[0-9]+x[0-9]+" | awk '{print $1}' | head -1)
echo "Verwende Modus: $MODE"

# Teste Rotation
xrandr --output HDMI-A-2 --mode "$MODE" --rotate right 2>&1
sleep 1
xrandr --fb 1280x400 2>&1

# Fixe xinitrc
sed -i '/xrandr.*HDMI-A-2/d' /home/andre/.xinitrc 2>/dev/null || true
if grep -q "chromium" /home/andre/.xinitrc; then
    sed -i "/chromium/i xrandr --output HDMI-A-2 --mode $MODE --rotate right" /home/andre/.xinitrc
    sed -i "/chromium/i xrandr --fb 1280x400" /home/andre/.xinitrc
    sed -i "/chromium/i sleep 1" /home/andre/.xinitrc
else
    sed -i "1i xrandr --output HDMI-A-2 --mode $MODE --rotate right" /home/andre/.xinitrc
    sed -i "2i xrandr --fb 1280x400" /home/andre/.xinitrc
fi

# Fixe Touchscreen
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

echo "✅ Rotation gefixt"
xrandr --output HDMI-A-2 --query 2>/dev/null | grep -E "current|rotation" | head -2

# Cleanup
cd /boot/firmware
sudo rm -f *.backup* *.hdmi* *.working* *.test* *.double_rotation* *.video* *.minimal* 2>/dev/null
echo "✅ System aufgeräumt"

# Reboot
echo "Reboot in 5 Sekunden..."
sleep 5
sudo reboot
FIX

echo ""
echo "✅ Rotation-Fix ausgeführt - Pi bootet neu"

