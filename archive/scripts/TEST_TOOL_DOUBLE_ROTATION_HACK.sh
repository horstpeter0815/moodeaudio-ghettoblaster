#!/bin/bash
#
# Test Tool: Double Rotation Hack für Waveshare 7.9" DSI Display
# Quelle: Moode Audio Forum Thread 6416
# Zweck: Display mit 1280 Pixel Höhe initialisieren (Portrait-Mode) durch doppelte Rotation
#
# WICHTIG: Nicht automatisch implementieren - nur als Test-Tool!

set -e

PI_IP="192.168.178.122"
PI_USER="andre"
PI_PASS="0815"

echo "=========================================="
echo "Double Rotation Hack - Test Tool"
echo "=========================================="
echo ""
echo "Dieses Tool zeigt die Änderungen für:"
echo "1. cmdline.txt: video=DSI-1:400x1280M@60,rotate=90"
echo "2. xinitrc: DSI-Rotation VOR xset verschieben"
echo ""
echo "NICHT automatisch implementieren!"
echo ""

# Prüfe aktuelle cmdline.txt
echo "=== Aktuelle cmdline.txt ==="
sshpass -p "$PI_PASS" ssh -o StrictHostKeyChecking=no "$PI_USER@$PI_IP" "cat /boot/firmware/cmdline.txt"
echo ""

# Zeige was geändert werden würde
echo "=== Änderung für cmdline.txt ==="
echo "ALT: video=DSI-1:1280x400@60"
echo "NEU: video=DSI-1:400x1280M@60,rotate=90"
echo ""
echo "Bedeutung:"
echo "- 400x1280 = Initialisiert Display im Portrait-Mode (1280 Pixel Höhe!)"
echo "- rotate=90 = 90° Rotation"
echo "- Display startet mit 1280 Pixel Höhe (löst 'minimum pixel height' Problem)"
echo ""

# Prüfe aktuelle xinitrc
echo "=== Aktuelle xinitrc (Ausschnitt) ==="
sshpass -p "$PI_PASS" ssh -o StrictHostKeyChecking=no "$PI_USER@$PI_IP" "cat /home/$PI_USER/.xinitrc | head -20"
echo ""

# Zeige was in xinitrc passieren sollte
echo "=== Änderung für xinitrc ==="
echo "1. DSI-Rotation-Code VOR 'xset -dpms' verschieben"
echo "2. Reihenfolge:"
echo "   - DSI-Konfiguration aus DB lesen"
echo "   - xrandr --output DSI-1 --rotate right (bei dsi_scn_rotate=90)"
echo "   - DANN xset -dpms"
echo "   - DANN SCREEN_RES auslesen (OHNE Swap - Moode macht das schon bei Rotation!)"
echo ""

# Prüfe aktuelle Moode-Konfiguration
echo "=== Aktuelle Moode DSI-Konfiguration ==="
sshpass -p "$PI_PASS" ssh -o StrictHostKeyChecking=no "$PI_USER@$PI_IP" \
  "moodeutl -q \"SELECT param, value FROM cfg_system WHERE param LIKE '%dsi%'\" 2>&1"
echo ""

echo "=== Zusammenfassung ==="
echo ""
echo "Doppelte Rotation:"
echo "1. cmdline.txt: Display startet im Portrait-Mode (400x1280 = 1280 Pixel Höhe)"
echo "2. xinitrc: xrandr rotiert Display nochmal für finale Orientierung"
echo ""
echo "Ergebnis:"
echo "- Display hat genug Höhe beim Start (1280 Pixel)"
echo "- Wird dann für Anwendung korrekt orientiert"
echo "- Keine Probleme mit 'minimum pixel height'"
echo ""
echo "=========================================="
echo "Tool beendet - Änderungen wurden NICHT implementiert!"
echo "=========================================="

