#!/bin/bash
################################################################################
# QUICK DISPLAY FIX + LED DIFFERENTIATION
# Behebt Display-Probleme und setzt unterschiedliche LED-Modi
################################################################################

set -e

PI1="andre@ghettopi5"
PI2="andre@192.168.178.134"
PI2_PASS="0815"

echo "============================================================"
echo "QUICK DISPLAY FIX + LED SETUP"
echo "============================================================"
echo ""

# Warte auf Pis
echo "=== Warte auf Pis (max 60 Sekunden) ==="
for i in {1..12}; do
    if ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no "$PI1" "hostname" > /dev/null 2>&1; then
        echo "✅ ghettopi5 ist online"
        break
    fi
    echo "Warte auf ghettopi5... ($i/12)"
    sleep 5
done

for i in {1..12}; do
    if sshpass -p "$PI2_PASS" ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no "$PI2" "hostname" > /dev/null 2>&1; then
        echo "✅ ghettopi5-2 ist online"
        break
    fi
    echo "Warte auf ghettopi5-2... ($i/12)"
    sleep 5
done

echo ""
echo "=== 1. LED UNTERSCHEIDUNG ==="
echo ""

# ghettopi5: Heartbeat
echo "ghettopi5: Setze Heartbeat-LED..."
ssh -o StrictHostKeyChecking=no "$PI1" "sudo mount -o remount,rw /boot/firmware 2>/dev/null; \
sudo sed -i '/^dtparam=act_led_trigger=/d' /boot/firmware/config.txt; \
echo 'dtparam=act_led_trigger=heartbeat' | sudo tee -a /boot/firmware/config.txt > /dev/null; \
echo heartbeat | sudo tee /sys/class/leds/ACT/trigger > /dev/null 2>&1 || echo heartbeat | sudo tee /sys/class/leds/led0/trigger > /dev/null 2>&1 || true; \
echo '✅ Heartbeat gesetzt'" || echo "⚠️  Fehler"

# ghettopi5-2: Timer  
echo "ghettopi5-2: Setze Timer-LED (langsameres Blinken)..."
sshpass -p "$PI2_PASS" ssh -o StrictHostKeyChecking=no "$PI2" "sudo mount -o remount,rw /boot/firmware 2>/dev/null; \
sudo sed -i '/^dtparam=act_led_trigger=/d' /boot/firmware/config.txt; \
echo 'dtparam=act_led_trigger=timer' | sudo tee -a /boot/firmware/config.txt > /dev/null; \
echo timer | sudo tee /sys/class/leds/ACT/trigger > /dev/null 2>&1 || echo timer | sudo tee /sys/class/leds/led0/trigger > /dev/null 2>&1 || true; \
echo '✅ Timer gesetzt'" || echo "⚠️  Fehler"

echo ""
echo "=== 2. DISPLAY-FIXES ==="
echo ""

# ghettopi5: Teste Portrait-Mode für gestreiftes Display
echo "ghettopi5: Setze Portrait-Mode (400x1280@60Hz) - für gestreiftes Display..."
ssh -o StrictHostKeyChecking=no "$PI1" "sudo mount -o remount,rw /boot/firmware; \
sudo sed -i 's/^hdmi_cvt=.*/hdmi_cvt=400 1280 60 0 0 0 0/' /boot/firmware/config.txt; \
sudo sed -i 's/^framebuffer_width=.*/framebuffer_width=400/' /boot/firmware/config.txt; \
sudo sed -i 's/^framebuffer_height=.*/framebuffer_height=1280/' /boot/firmware/config.txt; \
sudo sed -i 's/video=HDMI-A-2:1280x400M@60/video=HDMI-A-2:400x1280M@60,rotate=90/' /boot/firmware/cmdline.txt; \
echo '✅ Portrait-Mode gesetzt'" || echo "⚠️  Fehler"

# ghettopi5-2: Teste 30Hz für schwarzes Display  
echo "ghettopi5-2: Setze 30Hz Mode - für schwarzes Display..."
sshpass -p "$PI2_PASS" ssh -o StrictHostKeyChecking=no "$PI2" "sudo mount -o remount,rw /boot/firmware; \
sudo sed -i 's/^hdmi_cvt=.*/hdmi_cvt=1280 400 30 0 0 0 0/' /boot/firmware/config.txt; \
sudo sed -i 's/video=HDMI-A-2:1280x400M@60/video=HDMI-A-2:1280x400M@30/' /boot/firmware/cmdline.txt; \
echo '✅ 30Hz Mode gesetzt'" || echo "⚠️  Fehler"

echo ""
echo "=== 3. REBOOT BEIDE PIS ==="
echo ""

read -p "Beide Pis jetzt rebooten? (j/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[JjYy]$ ]]; then
    echo "Reboote ghettopi5..."
    ssh -o StrictHostKeyChecking=no "$PI1" "sudo reboot" || true
    
    echo "Reboote ghettopi5-2..."
    sshpass -p "$PI2_PASS" ssh -o StrictHostKeyChecking=no "$PI2" "sudo reboot" || true
    
    echo ""
    echo "✅ Beide Pis rebooten..."
    echo ""
    echo "Nach Reboot:"
    echo "  ghettopi5: Heartbeat-LED (schnelles Blinken) + Portrait-Mode"
    echo "  ghettopi5-2: Timer-LED (langsames Blinken) + 30Hz Mode"
else
    echo "Reboot übersprungen. Führen Sie manuell aus:"
    echo "  ssh $PI1 sudo reboot"
    echo "  sshpass -p '$PI2_PASS' ssh $PI2 sudo reboot"
fi

echo ""
echo "============================================================"
echo "FERTIG"
echo "============================================================"



