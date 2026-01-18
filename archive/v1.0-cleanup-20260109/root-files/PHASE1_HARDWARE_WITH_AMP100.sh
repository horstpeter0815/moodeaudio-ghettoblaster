#!/bin/bash
# Phase 1.1: Hardware-Identifikation MIT AMP100

PI_IP="192.168.178.178"
PI_USER="andre"
PI_PASS="0815"

echo "=== PHASE 1.1: HARDWARE-IDENTIFIKATION (mit AMP100) ==="
echo ""

sshpass -p "$PI_PASS" ssh -o StrictHostKeyChecking=no "$PI_USER@$PI_IP" << 'HARDWARE_SCAN'
set -e

echo "=== AUDIO-HARDWARE ==="
echo ""
echo "1. USB-Audio-Geräte:"
lsusb | grep -i "audio\|usb" || echo "Keine USB-Audio-Geräte"
echo ""

echo "2. ALSA Playback-Geräte:"
aplay -l
echo ""

echo "3. ALSA Capture-Geräte:"
arecord -l 2>/dev/null || echo "Keine Capture-Geräte"
echo ""

echo "4. I2C-Geräte (für AMP100):"
i2cdetect -y 1 2>/dev/null || echo "I2C nicht verfügbar"
echo ""

echo "5. HiFiBerry/AMP100 in dmesg:"
dmesg | grep -i "hifiberry\|amp100\|wm8960\|i2s" | tail -10 || echo "Keine AMP100-Info"
echo ""

echo "6. Device-Tree Overlays (Audio):"
ls /boot/firmware/overlays/ 2>/dev/null | grep -E "hifiberry|amp|dac|audio" | head -10 || echo "Keine Audio-Overlays"
echo ""

echo "7. Aktive Audio-Overlays:"
grep -E "dtoverlay.*hifiberry|dtoverlay.*amp" /boot/firmware/config.txt || echo "Keine AMP100-Overlays aktiv"
echo ""

echo "=== VIDEO-HARDWARE ==="
echo ""
echo "8. USB-Video-Geräte:"
lsusb | grep -i "display\|video\|touch" || echo "Keine USB-Video-Geräte"
echo ""

echo "9. Display-Status:"
export DISPLAY=:0
xrandr --output HDMI-A-2 --query 2>/dev/null | grep -E "connected|current" || echo "Display nicht erkannt"
echo ""

echo "10. Video-Overlays:"
grep -E "dtoverlay.*vc4|dtoverlay.*kms|dtoverlay.*display" /boot/firmware/config.txt || echo "Keine Video-Overlays"
echo ""

echo "=== SYSTEM-INFO ==="
echo ""
echo "11. System:"
uname -a
echo ""
cat /etc/os-release | grep -E "PRETTY_NAME|NAME" | head -2
echo ""

echo "12. Pi-Modell:"
cat /proc/device-tree/model 2>/dev/null || echo "Modell nicht verfügbar"
echo ""

echo "=== ZUSAMMENFASSUNG ==="
echo ""
echo "Audio-Geräte: $(aplay -l 2>/dev/null | grep -c "^card" || echo "0")"
echo "USB-Geräte: $(lsusb | wc -l)"
echo "Display: $(xrandr 2>/dev/null | grep -c "connected" || echo "Nicht verfügbar")"
echo "I2C-Geräte: $(i2cdetect -y 1 2>/dev/null | grep -E "1a|1b" | wc -l || echo "0")"
echo ""

echo "✅ Hardware-Scan abgeschlossen"
HARDWARE_SCAN

echo ""
echo "=== SCAN ABGESCHLOSSEN ==="
echo ""

