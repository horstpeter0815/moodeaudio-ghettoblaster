#!/bin/bash
# Setup Smooth Audio Pi5

IP="192.168.178.178"
USER="andre"
PASS="0815"

echo "=== SETUP SMOOTH AUDIO ==="
echo ""

# Status prüfen
echo "1. STATUS PRÜFEN:"
sshpass -p "$PASS" ssh -o StrictHostKeyChecking=no $USER@$IP << 'ENDSSH'
echo "Hostname: $(hostname)"
echo "System: $(uname -a | head -1)"
echo ""
echo "Overlays:"
grep "dtoverlay" /boot/firmware/config.txt | grep -v "^#" | grep -v "^$"
echo ""
echo "Soundkarten:"
cat /proc/asound/cards
echo ""
echo "PCM5122:"
dmesg | grep -iE "pcm5122|4d" | tail -3
ENDSSH

echo ""
echo "2. KONFIGURIERE DISPLAY (Landscape):"
sshpass -p "$PASS" ssh -o StrictHostKeyChecking=no $USER@$IP << 'ENDSSH'
# Display Rotation für Landscape
sudo moodeutl -w hdmi_scn_orient landscape
echo "Display: Landscape gesetzt"
ENDSSH

echo ""
echo "3. KONFIGURIERE TOUCHSCREEN:"
sshpass -p "$PASS" ssh -o StrictHostKeyChecking=no $USER@$IP << 'ENDSSH'
# Touchscreen Kalibrierung (wie Ghettoblaster)
if [ -f /home/andre/.xinitrc ]; then
    # Touchscreen Matrix für Landscape
    if ! grep -q "Coordinate Transformation Matrix" /home/andre/.xinitrc; then
        echo 'xinput set-prop "FT6236" "Coordinate Transformation Matrix" 0 -1 1 1 0 0 0 0 1' >> /home/andre/.xinitrc
        echo "Touchscreen Matrix hinzugefügt"
    fi
else
    echo "⚠️  .xinitrc nicht gefunden"
fi
ENDSSH

echo ""
echo "4. PRÜFE AUDIO:"
sshpass -p "$PASS" ssh -o StrictHostKeyChecking=no $USER@$IP << 'ENDSSH'
# I2C Devices prüfen
echo "I2C Bus 13:"
i2cdetect -y 13 2>/dev/null | grep -A1 "0  1  2" | head -3
echo ""
echo "Soundkarten:"
cat /proc/asound/cards
echo ""
echo "ALSA Devices:"
aplay -l 2>&1 | head -5
ENDSSH

echo ""
echo "✅ Setup abgeschlossen!"
echo ""

