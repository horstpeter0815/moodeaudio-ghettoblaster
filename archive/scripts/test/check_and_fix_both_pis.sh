#!/bin/bash
# Prüfe beide Pis und fixe Rotation auf dem richtigen

PI5_IP="192.168.178.178"
RASPIOS_IP="192.168.178.143"
PI_USER="andre"
PI_PASS="0815"

echo "=== PRÜFE BEIDE PIS ==="
echo ""

# Prüfe Pi 5 (Ghetto Pi 5 - Moode Audio)
echo "1. Prüfe Pi 5 (192.168.178.178 - Ghetto Pi 5 / Moode Audio)..."
if sshpass -p "$PI_PASS" ssh -o ConnectTimeout=3 -o StrictHostKeyChecking=no "$PI_USER@$PI5_IP" "echo 'ONLINE' && hostname" 2>&1 | grep -q "ONLINE"; then
    echo "   ✅ Pi 5 ist online"
    sshpass -p "$PI_PASS" ssh -o StrictHostKeyChecking=no "$PI_USER@$PI5_IP" bash << 'FIX_PI5'
set -e
export DISPLAY=:0

echo "   Hostname: $(hostname)"
echo "   IP: $(hostname -I | awk '{print $1}')"
echo "   Uptime: $(uptime -p)"
echo ""

echo "   Aktuelle Display-Situation:"
xrandr --output HDMI-A-2 --query 2>/dev/null | grep -E "current|rotation" | head -2 || echo "   X11 nicht aktiv"
echo ""

echo "   Wende Rotation an..."
MODE=$(xrandr --output HDMI-A-2 --query 2>/dev/null | grep -E "^\s+[0-9]+x[0-9]+" | awk '{print $1}' | head -1)
xrandr --output HDMI-A-2 --mode "$MODE" --rotate right 2>&1
sleep 1
xrandr --fb 1280x400 2>&1
xrandr --output HDMI-A-2 --query 2>/dev/null | grep -E "current|rotation" | head -2
echo ""

echo "   Fixe xinitrc..."
cp /home/andre/.xinitrc /home/andre/.xinitrc.backup.$(date +%Y%m%d_%H%M%S) 2>/dev/null || true
sed -i '/xrandr.*HDMI-A-2/d' /home/andre/.xinitrc 2>/dev/null || true
if grep -q "chromium" /home/andre/.xinitrc; then
    sed -i "/chromium/i xrandr --output HDMI-A-2 --mode $MODE --rotate right" /home/andre/.xinitrc
    sed -i "/chromium/i xrandr --fb 1280x400" /home/andre/.xinitrc
    sed -i "/chromium/i sleep 2" /home/andre/.xinitrc
else
    echo "xrandr --output HDMI-A-2 --mode $MODE --rotate right" >> /home/andre/.xinitrc
    echo "xrandr --fb 1280x400" >> /home/andre/.xinitrc
fi
echo "   ✅ xinitrc gefixt"
echo ""

echo "   Reboot..."
sudo reboot
FIX_PI5
    echo "   ✅ Rotation auf Pi 5 gefixt - Reboot durchgeführt"
else
    echo "   ❌ Pi 5 ist offline"
fi
echo ""

# Prüfe RaspiOS Full
echo "2. Prüfe RaspiOS Full (192.168.178.143)..."
if sshpass -p "$PI_PASS" ssh -o ConnectTimeout=3 -o StrictHostKeyChecking=no "$PI_USER@$RASPIOS_IP" "echo 'ONLINE' && hostname" 2>&1 | grep -q "ONLINE"; then
    echo "   ✅ RaspiOS Full ist online"
    sshpass -p "$PI_PASS" ssh -o StrictHostKeyChecking=no "$PI_USER@$RASPIOS_IP" "hostname && hostname -I | awk '{print \$1}' && uptime -p"
else
    echo "   ❌ RaspiOS Full ist offline"
fi
echo ""

echo "=== FERTIG ==="

