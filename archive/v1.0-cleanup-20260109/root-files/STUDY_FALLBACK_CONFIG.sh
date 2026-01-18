#!/bin/bash
# STUDIERE FALLBACK-LÖSUNG - Ghetto Pi 5

PI_IP="192.168.178.178"
PI_USER="andre"
PI_PASS="0815"

echo "=== STUDIERE FALLBACK-LÖSUNG ==="
echo "Display: 1280x400 Landscape - FAST PERFEKT"
echo ""

sshpass -p "$PI_PASS" ssh -o StrictHostKeyChecking=no "$PI_USER@$PI_IP" << 'STUDY_SCRIPT'
set -e

echo "1. CONFIG.TXT - [pi5] Sektion:"
echo "----------------------------------------"
grep -A 20 "^\[pi5\]" /boot/firmware/config.txt
echo ""

echo "2. CMDLINE.TXT:"
echo "----------------------------------------"
cat /boot/firmware/cmdline.txt
echo ""

echo "3. XRANDR Status (aktuelles Display):"
echo "----------------------------------------"
export DISPLAY=:0
xrandr 2>/dev/null | grep -E "connected|current|HDMI" | head -5 || echo "X11 nicht aktiv"
echo ""

echo "4. XINITRC - Display Setup:"
echo "----------------------------------------"
if [ -f /home/andre/.xinitrc ]; then
    grep -E "xrandr|HDMI|display|rotate" /home/andre/.xinitrc
else
    echo "xinitrc nicht gefunden"
fi
echo ""

echo "5. X11 Touchscreen Config:"
echo "----------------------------------------"
if [ -f /etc/X11/xorg.conf.d/99-touchscreen.conf ]; then
    cat /etc/X11/xorg.conf.d/99-touchscreen.conf
else
    echo "Touchscreen Config nicht gefunden"
fi
echo ""

echo "✅ Fallback-Lösung dokumentiert"
STUDY_SCRIPT

