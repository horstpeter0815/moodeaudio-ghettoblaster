#!/bin/bash
# Reboot beide Pis

PI5_IP="192.168.178.178"
RASPIOS_IP="192.168.178.143"
PI_USER="andre"
PI_PASS="0815"

echo "=== REBOOT BEIDE PIS ==="
echo ""

echo "1. Reboot Pi 5 (192.168.178.178 - Ghetto Pi 5 / Moode Audio)..."
if sshpass -p "$PI_PASS" ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no "$PI_USER@$PI5_IP" "echo 'Reboot Pi 5...' && sudo reboot" 2>&1; then
    echo "   ✅ Pi 5 Reboot initiiert"
else
    echo "   ❌ Pi 5 nicht erreichbar"
fi
echo ""

echo "2. Reboot RaspiOS Full (192.168.178.143)..."
if sshpass -p "$PI_PASS" ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no "$PI_USER@$RASPIOS_IP" "echo 'Reboot RaspiOS Full...' && sudo reboot" 2>&1; then
    echo "   ✅ RaspiOS Full Reboot initiiert"
else
    echo "   ❌ RaspiOS Full nicht erreichbar"
fi
echo ""

echo "=== WARTE AUF REBOOT (90 Sekunden) ==="
sleep 90
echo ""

echo "=== PRÜFE STATUS ==="
echo ""

echo "Pi 5 (192.168.178.178):"
for i in {1..20}; do
    if sshpass -p "$PI_PASS" ssh -o ConnectTimeout=3 -o StrictHostKeyChecking=no "$PI_USER@$PI5_IP" "echo 'ONLINE'" 2>&1 | grep -q "ONLINE"; then
        echo "   ✅ Pi 5 ist wieder online"
        sshpass -p "$PI_PASS" ssh -o StrictHostKeyChecking=no "$PI_USER@$PI5_IP" "hostname && uptime -p"
        break
    else
        echo "   [$(date +%H:%M:%S)] Warte auf Pi 5... ($i/20)"
        sleep 3
    fi
done
echo ""

echo "RaspiOS Full (192.168.178.143):"
for i in {1..20}; do
    if sshpass -p "$PI_PASS" ssh -o ConnectTimeout=3 -o StrictHostKeyChecking=no "$PI_USER@$RASPIOS_IP" "echo 'ONLINE'" 2>&1 | grep -q "ONLINE"; then
        echo "   ✅ RaspiOS Full ist wieder online"
        sshpass -p "$PI_PASS" ssh -o StrictHostKeyChecking=no "$PI_USER@$RASPIOS_IP" "hostname && uptime -p"
        break
    else
        echo "   [$(date +%H:%M:%S)] Warte auf RaspiOS Full... ($i/20)"
        sleep 3
    fi
done
echo ""

echo "✅ Reboot abgeschlossen"

