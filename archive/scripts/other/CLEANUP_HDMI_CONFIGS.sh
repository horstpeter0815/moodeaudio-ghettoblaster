#!/bin/bash
# LÖSCHE ALLE HDMI CONFIGS - NUR AKTUELLE BLEIBT

PI_IP="192.168.178.178"
PI_USER="andre"
PI_PASS="0815"

echo "=== LÖSCHE ALLE HDMI CONFIGS (außer aktueller) ==="
echo ""

sshpass -p "$PI_PASS" ssh -o StrictHostKeyChecking=no "$PI_USER@$PI_IP" << 'CLEANUP_SCRIPT'
set -e

BOOT_DIR="/boot/firmware"
cd "$BOOT_DIR"

echo "1. Finde alle Backup/Test-Dateien:"
ls -1 *.backup* *.hdmi* *.working* *.test* *.double_rotation* *.video* *.minimal* 2>/dev/null | head -20 || echo "Keine gefunden"
echo ""

echo "2. LÖSCHE ALLE:"
sudo rm -f *.backup* *.hdmi* *.working* *.test* *.double_rotation* *.video* *.minimal* 2>/dev/null
echo "✅ Alle Backup-Dateien gelöscht"
echo ""

echo "3. Verbleibende Config-Dateien:"
ls -lh config.txt cmdline.txt
echo ""

echo "4. AKTUELLE CONFIG (NUR DIESE BLEIBT):"
echo "========================================"
echo ""
echo "[pi5] Sektion:"
grep -A 10 "^\[pi5\]" config.txt
echo ""
echo "cmdline.txt:"
cat cmdline.txt
echo ""

echo "✅ NUR AKTUELLE CONFIG BLEIBT"
CLEANUP_SCRIPT

echo ""
echo "✅ Aufräumen abgeschlossen"

