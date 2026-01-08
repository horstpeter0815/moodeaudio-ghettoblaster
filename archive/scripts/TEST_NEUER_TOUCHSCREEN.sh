#!/bin/bash
# Test-Script für neuen Touchscreen

export SSHPASS="0815"
PI4_IP="192.168.178.96"

echo "=== PI 4: NEUER TOUCHSCREEN TEST ==="
echo ""

# Option 1: MIT REBOOT
echo "Option 1: MIT REBOOT (empfohlen)"
echo "  1. Hardware wechseln"
echo "  2. Reboot durchführen"
echo "  3. System testen"
echo ""

# Option 2: OHNE REBOOT
echo "Option 2: OHNE REBOOT"
echo "  1. Hardware wechseln"
echo "  2. I2C Bus scannen"
echo "  3. Device manuell erstellen"
echo ""

read -p "Reboot durchführen? (j/n): " REBOOT

if [ "$REBOOT" = "j" ]; then
    echo "Reboot wird durchgeführt..."
    sshpass -e ssh -o StrictHostKeyChecking=no andre@$PI4_IP "echo '0815' | sudo -S reboot"
    echo "Warte auf Reboot..."
    sleep 60
    for i in {1..60}; do
        ping -c 1 -W 1 $PI4_IP >/dev/null 2>&1 && \
        sshpass -e ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 andre@$PI4_IP "hostname" 2>&1 && \
        echo "✅ PI 4 online" && break || \
        echo "Warte... ($i/60)" && sleep 5
    done
else
    echo "Ohne Reboot - Hardware sollte bereits gewechselt sein"
fi

echo ""
echo "=== I2C BUS SCAN ==="
sshpass -e ssh -o StrictHostKeyChecking=no andre@$PI4_IP "sudo i2cdetect -y 1"

echo ""
echo "=== TOUCHSCREEN ERKENNEN ==="
# Automatisch Touchscreen erkennen und testen
