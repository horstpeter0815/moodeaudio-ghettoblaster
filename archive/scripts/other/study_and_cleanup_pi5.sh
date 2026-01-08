#!/bin/bash
# Studie und bereinige Ghetto Pi 5 Config

PI_IP="192.168.178.178"
PI_USER="andre"
PI_PASS="0815"

echo "=== STUDIERE UND BEREINIGE GHETTO PI 5 ==="
echo ""

# 1. Prüfe Verbindung
echo "1. Prüfe Verbindung..."
sshpass -p "$PI_PASS" ssh -o StrictHostKeyChecking=no "$PI_USER@$PI_IP" "echo '✅ ONLINE' && hostname -I" || exit 1
echo ""

# 2. Zeige aktuelle [pi5] Config
echo "2. Aktuelle CONFIG.TXT - [pi5] Sektion:"
echo "----------------------------------------"
sshpass -p "$PI_PASS" ssh -o StrictHostKeyChecking=no "$PI_USER@$PI_IP" "grep -A 20 '^\[pi5\]' /boot/firmware/config.txt"
echo ""

# 3. Zeige cmdline.txt
echo "3. CMDLINE.TXT:"
echo "----------------------------------------"
sshpass -p "$PI_PASS" ssh -o StrictHostKeyChecking=no "$PI_USER@$PI_IP" "cat /boot/firmware/cmdline.txt"
echo ""

# 4. Zeige xinitrc
echo "4. XINITRC - Display Setup:"
echo "----------------------------------------"
sshpass -p "$PI_PASS" ssh -o StrictHostKeyChecking=no "$PI_USER@$PI_IP" "if [ -f /home/andre/.xinitrc ]; then grep -E 'xrandr|HDMI|display|rotate' /home/andre/.xinitrc; fi"
echo ""

# 5. Zeige Touchscreen Config
echo "5. X11 Touchscreen Config:"
echo "----------------------------------------"
sshpass -p "$PI_PASS" ssh -o StrictHostKeyChecking=no "$PI_USER@$PI_IP" "if [ -f /etc/X11/xorg.conf.d/99-touchscreen.conf ]; then cat /etc/X11/xorg.conf.d/99-touchscreen.conf; fi"
echo ""

# 6. Finde alle Backup-Dateien
echo "6. Finde alle Backup/Test-Dateien:"
echo "----------------------------------------"
sshpass -p "$PI_PASS" ssh -o StrictHostKeyChecking=no "$PI_USER@$PI_IP" "cd /boot/firmware && ls -1 *.backup* *.hdmi* *.working* *.test* *.double_rotation* *.video* *.minimal* 2>/dev/null | head -20"
echo ""

# 7. LÖSCHE ALLE BACKUPS
echo "7. LÖSCHE ALLE BACKUP/TEST-DATEIEN:"
echo "----------------------------------------"
sshpass -p "$PI_PASS" ssh -o StrictHostKeyChecking=no "$PI_USER@$PI_IP" "cd /boot/firmware && sudo rm -f *.backup* *.hdmi* *.working* *.test* *.double_rotation* *.video* *.minimal* 2>/dev/null && echo '✅ Alle Backup-Dateien gelöscht'"
echo ""

# 8. Zeige verbleibende Dateien
echo "8. Verbleibende Config-Dateien:"
echo "----------------------------------------"
sshpass -p "$PI_PASS" ssh -o StrictHostKeyChecking=no "$PI_USER@$PI_IP" "cd /boot/firmware && ls -lh config.txt cmdline.txt"
echo ""

echo "✅ STUDIE UND BEREINIGUNG ABGESCHLOSSEN"
echo ""
echo "=== FINALE CONFIG (NUR DIESE BLEIBT) ==="
echo ""
echo "[pi5] Sektion:"
sshpass -p "$PI_PASS" ssh -o StrictHostKeyChecking=no "$PI_USER@$PI_IP" "grep -A 10 '^\[pi5\]' /boot/firmware/config.txt"
echo ""
echo "cmdline.txt:"
sshpass -p "$PI_PASS" ssh -o StrictHostKeyChecking=no "$PI_USER@$PI_IP" "cat /boot/firmware/cmdline.txt"

