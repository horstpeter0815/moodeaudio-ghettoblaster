#!/bin/bash
# Verifiziert die Display-Konfiguration nach Reboot
#
# AUSFÜHRUNG:
#   chmod +x VERIFY_DISPLAY_FIX.sh
#   ./VERIFY_DISPLAY_FIX.sh

PI_IP="192.168.178.178"
PI_USER="andre"
PI_PASS="0815"

echo "=== DISPLAY-VERIFIKATION ==="
echo ""

sshpass -p "$PI_PASS" ssh -o StrictHostKeyChecking=no "$PI_USER@$PI_IP" << 'VERIFY'
set -e
export DISPLAY=:0

echo "1. Prüfe config.txt..."
echo "   [pi5] Sektion:"
grep -A 10 "\[pi5\]" /boot/firmware/config.txt | head -10
echo ""

echo "2. Prüfe cmdline.txt..."
echo "   Video-Parameter:"
grep -o "video=[^ ]*" /boot/firmware/cmdline.txt || echo "   ⚠️  Kein video= Parameter gefunden"
echo ""

echo "3. Prüfe Display-Status..."
xrandr --output HDMI-A-2 --query 2>/dev/null | grep -E "connected|current" || echo "   ⚠️  Display nicht erkannt"
echo ""

echo "4. Prüfe verfügbare Modi..."
xrandr --output HDMI-A-2 --query 2>/dev/null | grep -E "^\s+[0-9]+x[0-9]+" | head -5 || echo "   ⚠️  Keine Modi gefunden"
echo ""

echo "5. Prüfe xinitrc..."
if [ -f /home/andre/.xinitrc ]; then
    echo "   ✅ xinitrc vorhanden"
    echo "   Chromium-Befehl:"
    grep "chromium" /home/andre/.xinitrc | head -1
    echo "   xrandr-Befehle:"
    grep "xrandr" /home/andre/.xinitrc | head -3
else
    echo "   ⚠️  xinitrc nicht gefunden"
fi
echo ""

echo "6. Prüfe Touchscreen-Config..."
if [ -f /etc/X11/xorg.conf.d/99-touchscreen.conf ]; then
    echo "   ✅ Touchscreen-Config vorhanden"
    grep "TransformationMatrix" /etc/X11/xorg.conf.d/99-touchscreen.conf || echo "   ⚠️  Keine TransformationMatrix gefunden"
else
    echo "   ⚠️  Touchscreen-Config nicht gefunden"
fi
echo ""

echo "7. Erstelle Screenshot..."
if command -v scrot >/dev/null 2>&1; then
    scrot /tmp/display_verification.png 2>/dev/null && echo "   ✅ Screenshot: /tmp/display_verification.png"
elif command -v import >/dev/null 2>&1; then
    import -window root /tmp/display_verification.png 2>/dev/null && echo "   ✅ Screenshot: /tmp/display_verification.png"
else
    echo "   ⚠️  Screenshot-Tool nicht verfügbar"
fi
echo ""

echo "=== VERIFIKATION ABGESCHLOSSEN ==="
VERIFY

echo ""
echo "Prüfe Screenshots auf dem Pi:"
echo "  ssh andre@192.168.178.178"
echo "  scp andre@192.168.178.178:/tmp/display_*.png ."

