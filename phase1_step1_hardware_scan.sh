#!/bin/bash
# Phase 1, Schritt 1.1: Hardware-Identifikation
# Ausführen auf: Moode Audio Pi 5 (192.168.178.178)

set -e

RESULTS_FILE="/tmp/phase1_step1_results.txt"
echo "=== PHASE 1.1: HARDWARE-IDENTIFIKATION ===" > "$RESULTS_FILE"
echo "Datum: $(date)" >> "$RESULTS_FILE"
echo "" >> "$RESULTS_FILE"

echo "=== PHASE 1.1: HARDWARE-IDENTIFIKATION ==="
echo ""

echo "1. USB-Geräte:"
lsusb | tee -a "$RESULTS_FILE"
echo "" | tee -a "$RESULTS_FILE"

echo "2. Audio-Geräte (Playback):"
aplay -l | tee -a "$RESULTS_FILE"
echo "" | tee -a "$RESULTS_FILE"

echo "3. Audio-Geräte (Capture):"
arecord -l 2>/dev/null | tee -a "$RESULTS_FILE" || echo "Keine Capture-Geräte" | tee -a "$RESULTS_FILE"
echo "" | tee -a "$RESULTS_FILE"

echo "4. Video-Displays:"
export DISPLAY=:0
xrandr 2>/dev/null | grep -E "connected|current" | head -5 | tee -a "$RESULTS_FILE" || echo "X11 nicht aktiv" | tee -a "$RESULTS_FILE"
echo "" | tee -a "$RESULTS_FILE"

echo "5. Device-Tree Overlays (Audio):"
ls /boot/firmware/overlays/ 2>/dev/null | grep -E "audio|hifiberry|dac|amp" | head -10 | tee -a "$RESULTS_FILE" || echo "Keine Audio-Overlays gefunden" | tee -a "$RESULTS_FILE"
echo "" | tee -a "$RESULTS_FILE"

echo "6. Device-Tree Overlays (Video):"
ls /boot/firmware/overlays/ 2>/dev/null | grep -E "video|display|dsi|hdmi|vc4" | head -10 | tee -a "$RESULTS_FILE" || echo "Keine Video-Overlays gefunden" | tee -a "$RESULTS_FILE"
echo "" | tee -a "$RESULTS_FILE"

echo "7. Geladene Device-Tree Overlays:"
dmesg | grep -i "overlay\|dtoverlay" | tail -10 | tee -a "$RESULTS_FILE" || echo "Keine Overlay-Info" | tee -a "$RESULTS_FILE"
echo "" | tee -a "$RESULTS_FILE"

echo "8. Audio-Hardware in dmesg:"
dmesg | grep -i "audio\|alsa\|hifiberry\|dac" | tail -10 | tee -a "$RESULTS_FILE" || echo "Keine Audio-Info" | tee -a "$RESULTS_FILE"
echo "" | tee -a "$RESULTS_FILE"

echo "9. Video-Hardware in dmesg:"
dmesg | grep -i "display\|hdmi\|dsi\|vc4\|drm" | tail -10 | tee -a "$RESULTS_FILE" || echo "Keine Video-Info" | tee -a "$RESULTS_FILE"
echo "" | tee -a "$RESULTS_FILE"

echo "10. System-Info:"
uname -a | tee -a "$RESULTS_FILE"
echo "" | tee -a "$RESULTS_FILE"
cat /etc/os-release | grep -E "PRETTY_NAME|NAME" | head -2 | tee -a "$RESULTS_FILE"
echo "" | tee -a "$RESULTS_FILE"

echo "11. I2C-Geräte (für HiFiBerry):"
i2cdetect -y 1 2>/dev/null | tee -a "$RESULTS_FILE" || echo "I2C nicht verfügbar" | tee -a "$RESULTS_FILE"
echo "" | tee -a "$RESULTS_FILE"

echo "12. Aktive config.txt Einträge:"
grep -E "dtoverlay|dtparam" /boot/firmware/config.txt 2>/dev/null | tee -a "$RESULTS_FILE" || echo "config.txt nicht lesbar" | tee -a "$RESULTS_FILE"
echo "" | tee -a "$RESULTS_FILE"

echo "✅ Hardware-Identifikation abgeschlossen"
echo "Ergebnisse gespeichert in: $RESULTS_FILE"
echo ""
echo "=== ZUSAMMENFASSUNG ==="
echo "Audio-Geräte: $(aplay -l 2>/dev/null | grep -c "^card" || echo "0")"
echo "USB-Geräte: $(lsusb | wc -l)"
echo "Display: $(xrandr 2>/dev/null | grep -c "connected" || echo "Nicht verfügbar")"

