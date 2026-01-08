#!/bin/bash
################################################################################
# QUICK FIX FÜR ghettopi5 (gestreiftes Display)
# Portrait-Mode + Heartbeat-LED
################################################################################

PI1="andre@ghettopi5"

echo "=== FIX FÜR ghettopi5 (gestreiftes Display) ==="
echo ""

# Prüfe ob online
if ! ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no "$PI1" "hostname" > /dev/null 2>&1; then
    echo "❌ ghettopi5 nicht erreichbar. Versuche IP..."
    PI1="andre@192.168.178.143"
    if ! ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no "$PI1" "hostname" > /dev/null 2>&1; then
        echo "❌ ghettopi5 nicht erreichbar. Bitte später erneut versuchen."
        exit 1
    fi
fi

echo "✅ ghettopi5 ist online"
echo ""

# LED: Heartbeat
echo "1. Setze Heartbeat-LED..."
ssh -o StrictHostKeyChecking=no "$PI1" "sudo mount -o remount,rw /boot/firmware && \
sudo sed -i '/^dtparam=act_led_trigger=/d' /boot/firmware/config.txt && \
echo 'dtparam=act_led_trigger=heartbeat' | sudo tee -a /boot/firmware/config.txt > /dev/null && \
echo heartbeat | sudo tee /sys/class/leds/ACT/trigger > /dev/null 2>&1 || echo heartbeat | sudo tee /sys/class/leds/led0/trigger > /dev/null 2>&1 || true && \
echo '✅ Heartbeat gesetzt'"

# Display: Portrait-Mode (für gestreiftes Display)
echo ""
echo "2. Setze Portrait-Mode (400x1280@60Hz)..."
ssh -o StrictHostKeyChecking=no "$PI1" "sudo mount -o remount,rw /boot/firmware && \
sudo sed -i 's/^hdmi_cvt=.*/hdmi_cvt=400 1280 60 0 0 0 0/' /boot/firmware/config.txt && \
sudo sed -i 's/^framebuffer_width=.*/framebuffer_width=400/' /boot/firmware/config.txt && \
sudo sed -i 's/^framebuffer_height=.*/framebuffer_height=1280/' /boot/firmware/config.txt && \
sudo sed -i 's/video=HDMI-A-2:1280x400M@60/video=HDMI-A-2:400x1280M@60,rotate=90/' /boot/firmware/cmdline.txt && \
echo '✅ Portrait-Mode gesetzt'"

echo ""
echo "=== REBOOT ERFORDERLICH ==="
read -p "ghettopi5 jetzt rebooten? (j/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[JjYy]$ ]]; then
    ssh -o StrictHostKeyChecking=no "$PI1" "sudo reboot"
    echo "✅ ghettopi5 rebootet (Portrait-Mode + Heartbeat-LED)"
fi

echo ""
echo "FERTIG"



