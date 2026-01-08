#!/bin/bash
# STANDARD TEST SUITE - Für Moode Audio Pi 5
# WICHTIG: Nur ausführen, wenn alle Phasen abgeschlossen sind!
#
# AUSFÜHRUNG:
#   chmod +x STANDARD_TEST_SUITE_FINAL.sh
#   ./STANDARD_TEST_SUITE_FINAL.sh
#
# ⚠️  WARNUNG: Diese Tests sollten nur am ENDE ausgeführt werden!

PI_IP="192.168.178.178"
PI_USER="andre"
PI_PASS="0815"

echo "=== STANDARD TEST SUITE ==="
echo "⚠️  WARNUNG: Diese Tests sollten nur ausgeführt werden, wenn alle Phasen abgeschlossen sind!"
echo ""
read -p "Fortfahren? (j/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Jj]$ ]]; then
    echo "Abgebrochen."
    exit 1
fi

echo ""
echo "=== TEST 1: Hardware-Identifikation ==="
sshpass -p "$PI_PASS" ssh -o StrictHostKeyChecking=no "$PI_USER@$PI_IP" << 'TEST1'
echo "1.1 Audio-Geräte:"
aplay -l
echo ""
echo "1.2 Video-Displays:"
export DISPLAY=:0
xrandr --output HDMI-A-2 --query 2>/dev/null | grep -E "connected|current" || echo "Display nicht erkannt"
echo ""
echo "1.3 USB-Geräte:"
lsusb | grep -E "audio|display|touch"
TEST1

echo ""
echo "=== TEST 2: Display-Konfiguration ==="
sshpass -p "$PI_PASS" ssh -o StrictHostKeyChecking=no "$PI_USER@$PI_IP" << 'TEST2'
export DISPLAY=:0
echo "2.1 Aktuelle Auflösung:"
xrandr --output HDMI-A-2 --query 2>/dev/null | grep "current" || echo "Display nicht erkannt"
echo ""
echo "2.2 config.txt Einträge:"
grep -E "display_rotate|hdmi_mode|hdmi_group|framebuffer" /boot/firmware/config.txt | head -5
echo ""
echo "2.3 cmdline.txt Video-Parameter:"
grep "video=" /boot/firmware/cmdline.txt || echo "Kein video= Parameter"
TEST2

echo ""
echo "=== TEST 3: Audio-Pipeline ==="
sshpass -p "$PI_PASS" ssh -o StrictHostKeyChecking=no "$PI_USER@$PI_IP" << 'TEST3'
echo "3.1 ALSA-Geräte:"
aplay -l
echo ""
echo "3.2 MPD Status:"
systemctl status mpd --no-pager -l | head -10 || echo "MPD nicht gefunden"
echo ""
echo "3.3 Audio-Test (1 Sekunde Test-Ton):"
timeout 1 aplay /usr/share/sounds/alsa/Front_Left.wav 2>/dev/null && echo "✅ Audio funktioniert" || echo "⚠️  Audio-Test fehlgeschlagen"
TEST3

echo ""
echo "=== TEST 4: Video-Pipeline ==="
sshpass -p "$PI_PASS" ssh -o StrictHostKeyChecking=no "$PI_USER@$PI_IP" << 'TEST4'
export DISPLAY=:0
echo "4.1 X11 Status:"
ps aux | grep -E "Xorg|X11" | grep -v grep || echo "X11 nicht gefunden"
echo ""
echo "4.2 Chromium Status:"
ps aux | grep chromium | grep -v grep || echo "Chromium nicht gefunden"
echo ""
echo "4.3 Display-Modi:"
xrandr --output HDMI-A-2 --query 2>/dev/null | grep -E "^\s+[0-9]+x[0-9]+" | head -5 || echo "Keine Modi gefunden"
TEST4

echo ""
echo "=== TEST 5: Touchscreen ==="
sshpass -p "$PI_PASS" ssh -o StrictHostKeyChecking=no "$PI_USER@$PI_IP" << 'TEST5'
echo "5.1 Touchscreen-Config:"
if [ -f /etc/X11/xorg.conf.d/99-touchscreen.conf ]; then
    cat /etc/X11/xorg.conf.d/99-touchscreen.conf
else
    echo "⚠️  Touchscreen-Config nicht gefunden"
fi
echo ""
echo "5.2 USB Touchscreen-Gerät:"
lsusb | grep -i "touch\|0712" || echo "Touchscreen nicht gefunden"
TEST5

echo ""
echo "=== TEST 6: System-Status ==="
sshpass -p "$PI_PASS" ssh -o StrictHostKeyChecking=no "$PI_USER@$PI_IP" << 'TEST6'
echo "6.1 System-Info:"
uname -a
echo ""
echo "6.2 Uptime:"
uptime
echo ""
echo "6.3 Speicher:"
free -h | head -2
echo ""
echo "6.4 CPU-Temperatur:"
vcgencmd measure_temp 2>/dev/null || echo "Temperatur nicht verfügbar"
TEST6

echo ""
echo "=== TEST SUITE ABGESCHLOSSEN ==="
echo ""
echo "Ergebnisse:"
echo "  - Prüfe ob alle Tests erfolgreich waren"
echo "  - Screenshots auf Pi: /tmp/display_*.png"
echo "  - Logs: systemctl status mpd, systemctl status lightdm"
echo ""

