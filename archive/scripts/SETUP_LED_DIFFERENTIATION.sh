#!/bin/bash
################################################################################
# LED DIFFERENTIATION SETUP
# Setzt unterschiedliche LED-Modi für beide Pis, damit sie unterscheidbar sind
################################################################################

set -e

PI1="andre@ghettopi5"
PI1_HOSTNAME="andre@ghettopi5"
PI2="andre@192.168.178.134"
PI2_HOSTNAME="andre@ghettopi5-2"

echo "============================================================"
echo "LED DIFFERENTIATION SETUP"
echo "============================================================"
echo ""
echo "Ziel: Verschiedene LED-Modi für ghettopi5 und ghettopi5-2"
echo ""

# Prüfe Verbindungen
echo "=== 1. VERBINDUNG PRÜFEN ==="
if ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no "$PI1_HOSTNAME" "hostname" > /dev/null 2>&1; then
    echo "✅ ghettopi5 erreichbar"
    PI1="$PI1_HOSTNAME"
else
    echo "❌ ghettopi5 nicht erreichbar"
    exit 1
fi

if sshpass -p '0815' ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no "$PI2" "hostname" > /dev/null 2>&1; then
    echo "✅ ghettopi5-2 erreichbar"
else
    echo "⚠️  Versuche ghettopi5-2 mit Hostname..."
    if sshpass -p '0815' ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no "$PI2_HOSTNAME" "hostname" > /dev/null 2>&1; then
        PI2="$PI2_HOSTNAME"
        echo "✅ ghettopi5-2 erreichbar via Hostname"
    else
        echo "❌ ghettopi5-2 nicht erreichbar"
        exit 1
    fi
fi

echo ""
echo "=== 2. LED-KONFIGURATION ==="
echo ""

# ghettopi5: Heartbeat (normales Blinken)
echo "Konfiguriere ghettopi5 (Heartbeat-Modus)..."
ssh -o StrictHostKeyChecking=no "$PI1" "sudo mount -o remount,rw /boot/firmware && \
sudo sed -i '/^dtparam=act_led_trigger=/d' /boot/firmware/config.txt && \
echo 'dtparam=act_led_trigger=heartbeat' | sudo tee -a /boot/firmware/config.txt > /dev/null && \
echo '✅ ghettopi5: Heartbeat-Modus gesetzt' || echo '⚠️  Fehler'"

# ghettopi5-2: Timer (langsameres, rhythmischeres Blinken)
echo ""
echo "Konfiguriere ghettopi5-2 (Timer-Modus - langsameres Blinken)..."
sshpass -p '0815' ssh -o StrictHostKeyChecking=no "$PI2" "sudo mount -o remount,rw /boot/firmware && \
sudo sed -i '/^dtparam=act_led_trigger=/d' /boot/firmware/config.txt && \
echo 'dtparam=act_led_trigger=timer' | sudo tee -a /boot/firmware/config.txt > /dev/null && \
echo '✅ ghettopi5-2: Timer-Modus gesetzt (langsameres Blinken)' || echo '⚠️  Fehler'"

echo ""
echo "=== 3. SOFORTIGER LED-TEST (ohne Reboot) ==="
echo ""

# Setze LED-Modi sofort (funktioniert ohne Reboot)
echo "Setze ghettopi5 LED auf Heartbeat..."
ssh -o StrictHostKeyChecking=no "$PI1" "echo heartbeat | sudo tee /sys/class/leds/led0/trigger > /dev/null 2>&1 || echo timer | sudo tee /sys/class/leds/ACT/trigger > /dev/null 2>&1 || echo 'LED nicht gefunden'" && echo "✅ ghettopi5 LED aktiv"

echo ""
echo "Setze ghettopi5-2 LED auf Timer..."
sshpass -p '0815' ssh -o StrictHostKeyChecking=no "$PI2" "echo timer | sudo tee /sys/class/leds/led0/trigger > /dev/null 2>&1 || echo timer | sudo tee /sys/class/leds/ACT/trigger > /dev/null 2>&1 || echo 'LED nicht gefunden'" && echo "✅ ghettopi5-2 LED aktiv"

echo ""
echo "============================================================"
echo "LED DIFFERENTIATION ABGESCHLOSSEN"
echo "============================================================"
echo ""
echo "Unterscheidung:"
echo "  ghettopi5:      Heartbeat (normales, schnelles Blinken)"
echo "  ghettopi5-2:    Timer (langsameres, rhythmischeres Blinken)"
echo ""
echo "Die LEDs sollten SOFORT unterschiedlich blinken!"
echo ""
echo "Für permanente Änderung: Beide Pis rebooten"
echo "  ssh $PI1 sudo reboot"
echo "  sshpass -p '0815' ssh $PI2 sudo reboot"
echo ""

