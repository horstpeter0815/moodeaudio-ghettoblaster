#!/bin/bash
# SYSTEM AUFRÄUMEN - Lösche alle unnötigen Dateien

PI_IP="192.168.178.178"
PI_USER="andre"
PI_PASS="0815"

echo "=== SYSTEM AUFRÄUMEN ==="
echo "Lösche alle unnötigen Dateien/Scripts"
echo ""

sshpass -p "$PI_PASS" ssh -o StrictHostKeyChecking=no "$PI_USER@$PI_IP" << 'CLEANUP'
set -e

echo "1. Lösche Backup-Dateien in /boot/firmware:"
cd /boot/firmware
sudo rm -f *.backup* *.hdmi* *.working* *.test* *.double_rotation* *.video* *.minimal* 2>/dev/null
echo "   ✅ Boot-Backups gelöscht"
echo ""

echo "2. Lösche temporäre Scripts in /tmp:"
sudo rm -f /tmp/*.sh /tmp/*.log /tmp/display_*.png 2>/dev/null
echo "   ✅ Temp-Dateien gelöscht"
echo ""

echo "3. Lösche alte xinitrc Backups:"
rm -f /home/andre/.xinitrc.backup* 2>/dev/null
echo "   ✅ xinitrc Backups gelöscht"
echo ""

echo "4. Lösche alte Touchscreen Config Backups:"
sudo rm -f /etc/X11/xorg.conf.d/99-touchscreen.conf.backup* 2>/dev/null
echo "   ✅ Touchscreen Backups gelöscht"
echo ""

echo "5. Prüfe verbleibende wichtige Dateien:"
echo "   /boot/firmware/config.txt: $([ -f /boot/firmware/config.txt ] && echo '✅' || echo '❌')"
echo "   /boot/firmware/cmdline.txt: $([ -f /boot/firmware/cmdline.txt ] && echo '✅' || echo '❌')"
echo "   /home/andre/.xinitrc: $([ -f /home/andre/.xinitrc ] && echo '✅' || echo '❌')"
echo "   /etc/X11/xorg.conf.d/99-touchscreen.conf: $([ -f /etc/X11/xorg.conf.d/99-touchscreen.conf ] && echo '✅' || echo '❌')"
echo ""

echo "✅ System aufgeräumt - nur essentielle Dateien bleiben"
CLEANUP

echo ""
echo "=== LÖSCHE UNNÖTIGE SCRIPTS LOKAL ==="
cd "/Users/andrevollmer/Library/Mobile Documents/com~apple~CloudDocs/Ablage/Roon filters/Bose Wave/OS/RPi4/moodeaudio/cursor"

# Lösche alte Test-Scripts (behalte wichtige)
rm -f RUN_THIS_NOW.sh WRITE_RASPIOS_TO_SD.sh TOUCHSCREEN_COMPLETE_GUIDE.md 2>/dev/null
echo "✅ Lokale Test-Scripts gelöscht"

echo ""
echo "✅ System-Aufräumen abgeschlossen"

