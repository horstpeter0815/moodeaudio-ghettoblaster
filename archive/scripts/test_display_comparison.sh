#!/bin/bash
# Test-Script für Display-Vergleich
# Führe dieses Script nach Display-Wechsel aus

echo "=========================================="
echo "WAVESHARE DISPLAY COMPARISON TEST"
echo "=========================================="
echo ""

echo "=== TEST 1: DSI ERKENNUNG ==="
ls -la /sys/class/drm/ | grep -E 'card|DSI'
echo ""
if [ -d /sys/class/drm/card1-DSI-1 ]; then
    echo "DSI-1 erkannt:"
    cat /sys/class/drm/card1-DSI-1/status 2>&1
    cat /sys/class/drm/card1-DSI-1/modes 2>&1
else
    echo "DSI-1 NICHT erkannt!"
fi
echo ""

echo "=== TEST 2: CRTC STATUS ==="
dmesg | grep -E 'Bogus|possible_crtc|No compatible format' | tail -5
if [ $? -ne 0 ]; then
    echo "Keine CRTC-Fehler gefunden (gut!)"
fi
echo ""

echo "=== TEST 3: FRAMEBUFFER ==="
ls -la /dev/fb* 2>&1
if [ $? -ne 0 ]; then
    echo "Kein Framebuffer gefunden"
fi
echo ""

echo "=== TEST 4: I2C STATUS ==="
echo "Panel-Devices:"
ls -la /sys/bus/i2c/devices/ | grep -E '0045|panel'
echo ""
echo "I2C-Fehler (letzte 10):"
dmesg | grep -E 'i2c write|panel-waveshare' | tail -10
echo ""

echo "=== TEST 5: VC4 STATUS ==="
lsmod | grep vc4
echo ""
dmesg | grep 'Initialized vc4'
echo ""

echo "=== TEST 6: PANEL INITIALISIERUNG ==="
dmesg | grep -E 'panel.*enable|panel.*prepare|DSI.*init' | tail -10
echo ""

echo "=== TEST 7: OVERLAY STATUS ==="
dmesg | grep -E 'waveshare|panel|DSI' | head -15
echo ""

echo "=========================================="
echo "TEST ABGESCHLOSSEN"
echo "=========================================="

