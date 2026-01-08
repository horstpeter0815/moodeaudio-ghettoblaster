#!/bin/bash
################################################################################
# DISPLAY TIMING TEST SCRIPT
# Testet verschiedene Timing-Konfigurationen für 1280x400 Display
################################################################################

PI_HOST="$1"
if [ -z "$PI_HOST" ]; then
    echo "Usage: $0 <pi-hostname-or-ip>"
    echo "Example: $0 andre@ghettopi5"
    exit 1
fi

echo "============================================================"
echo "DISPLAY TIMING TEST FÜR $PI_HOST"
echo "============================================================"
echo ""
echo "Dieses Script testet verschiedene Timing-Konfigurationen"
echo "Bitte prüfen Sie das Display nach jeder Änderung!"
echo ""
read -p "Drücken Sie Enter zum Fortfahren..."

# Backup erstellen
echo "Erstelle Backup..."
ssh -o StrictHostKeyChecking=no "$PI_HOST" "sudo cp /boot/firmware/config.txt /boot/firmware/config.txt.backup.timing_test"

# Test 1: 50Hz mit aspect=0
echo ""
echo "=== TEST 1: 50Hz Refresh-Rate ==="
ssh -o StrictHostKeyChecking=no "$PI_HOST" "sudo mount -o remount,rw /boot/firmware && sudo sed -i 's/hdmi_cvt=.*/hdmi_cvt=1280 400 50 0 0 0 0/' /boot/firmware/config.txt && sudo sed -i 's/config_hdmi_boost=.*/config_hdmi_boost=11/' /boot/firmware/config.txt"
echo "✅ Konfiguration angewendet - bitte DISPLAY PRÜFEN"
echo "Reboot erforderlich: ssh $PI_HOST 'sudo reboot'"
read -p "Hat TEST 1 funktioniert? (j/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Jj]$ ]]; then
    echo "✅ TEST 1 erfolgreich!"
    exit 0
fi

# Test 2: 30Hz
echo ""
echo "=== TEST 2: 30Hz Refresh-Rate ==="
ssh -o StrictHostKeyChecking=no "$PI_HOST" "sudo mount -o remount,rw /boot/firmware && sudo sed -i 's/hdmi_cvt=.*/hdmi_cvt=1280 400 30 0 0 0 0/' /boot/firmware/config.txt"
echo "✅ Konfiguration angewendet - bitte DISPLAY PRÜFEN"
echo "Reboot erforderlich: ssh $PI_HOST 'sudo reboot'"
read -p "Hat TEST 2 funktioniert? (j/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Jj]$ ]]; then
    echo "✅ TEST 2 erfolgreich!"
    exit 0
fi

# Test 3: 60Hz mit aspect=2 (16:10)
echo ""
echo "=== TEST 3: 60Hz mit aspect=2 (16:10) ==="
ssh -o StrictHostKeyChecking=no "$PI_HOST" "sudo mount -o remount,rw /boot/firmware && sudo sed -i 's/hdmi_cvt=.*/hdmi_cvt=1280 400 60 2 0 0 0/' /boot/firmware/config.txt"
echo "✅ Konfiguration angewendet - bitte DISPLAY PRÜFEN"
echo "Reboot erforderlich: ssh $PI_HOST 'sudo reboot'"
read -p "Hat TEST 3 funktioniert? (j/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Jj]$ ]]; then
    echo "✅ TEST 3 erfolgreich!"
    exit 0
fi

echo ""
echo "❌ Keine der getesteten Konfigurationen hat funktioniert."
echo "Bitte manuell weitere Optionen testen oder Hardware-Probleme prüfen."

