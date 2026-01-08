#!/bin/bash
################################################################################
# SETUP FÜR PI5 MIT RASPIOS - DISPLAY UND AUDIO
# Konfiguriert Display (X, Chromium, Touchscreen) und Audio (AMP100)
################################################################################

set -e

PI_HOST="$1"

if [ -z "$PI_HOST" ]; then
    echo "Usage: $0 <pi-hostname-or-ip>"
    echo "Example: $0 192.168.178.143"
    exit 1
fi

echo "============================================================"
echo "SETUP PI5 RASPIOS - DISPLAY UND AUDIO"
echo "============================================================"
echo ""

# 1. DISPLAY KONFIGURATION
echo "=== 1. DISPLAY KONFIGURATION ==="
echo ""

sshpass -p "0815" ssh -o StrictHostKeyChecking=no andre@$PI_HOST << 'ENDSSH'
# X Server Konfiguration
if [ ! -f ~/.xinitrc ]; then
    cat > ~/.xinitrc << 'XINITRC'
#!/bin/sh
export DISPLAY=:0

# Touchscreen Kalibrierung (falls nötig)
# xinput set-prop "Coordinate Transformation Matrix" "0 -1 1 1 0 0 0 0 1"

# Chromium starten
chromium-browser --kiosk --noerrdialogs --disable-infobars http://localhost/ &

# PeppyMeter (falls aktiviert)
# export DISPLAY=:0 && python3 /opt/peppymeter/peppymeter.py
XINITRC
    chmod +x ~/.xinitrc
    echo "✅ .xinitrc erstellt"
fi

# Systemd Service für Display
if [ ! -f /etc/systemd/system/localdisplay.service ]; then
    sudo tee /etc/systemd/system/localdisplay.service > /dev/null << 'SERVICE'
[Unit]
Description=Moode Audio Display (X + Chromium)
After=graphical.target

[Service]
User=andre
Type=simple
ExecStart=/usr/bin/xinit
Restart=always
RestartSec=5

[Install]
WantedBy=graphical.target
SERVICE
    sudo systemctl daemon-reload
    sudo systemctl enable localdisplay.service
    echo "✅ localdisplay.service erstellt"
fi

ENDSSH

# 2. AUDIO KONFIGURATION
echo ""
echo "=== 2. AUDIO KONFIGURATION ==="
echo ""

sshpass -p "0815" ssh -o StrictHostKeyChecking=no andre@$PI_HOST << 'ENDSSH'
# Prüfe ob AMP100 vorhanden ist
if i2cdetect -y 1 2>/dev/null | grep -q "4d" || i2cdetect -y 13 2>/dev/null | grep -q "4d"; then
    echo "✅ AMP100 erkannt"
    
    # Custom Overlay aktivieren
    if ! grep -q "hifiberry-amp100-pi5" /boot/firmware/config.txt; then
        echo "dtoverlay=hifiberry-amp100-pi5" | sudo tee -a /boot/firmware/config.txt
        echo "✅ Custom Overlay aktiviert"
    fi
    
    # Reset-Service aktivieren
    if [ ! -f /etc/systemd/system/reset-amp100.service ]; then
        sudo tee /usr/local/bin/reset-amp100.sh > /dev/null << 'SCRIPT'
#!/bin/bash
GPIO_RESET=17
GPIO_MUTE=4

if [ ! -d /sys/class/gpio/gpio${GPIO_RESET} ]; then
    echo ${GPIO_RESET} > /sys/class/gpio/export 2>/dev/null
    sleep 0.1
fi
if [ ! -d /sys/class/gpio/gpio${GPIO_MUTE} ]; then
    echo ${GPIO_MUTE} > /sys/class/gpio/export 2>/dev/null
    sleep 0.1
fi

if [ -d /sys/class/gpio/gpio${GPIO_RESET} ]; then
    echo out > /sys/class/gpio/gpio${GPIO_RESET}/direction 2>/dev/null
fi
if [ -d /sys/class/gpio/gpio${GPIO_MUTE} ]; then
    echo out > /sys/class/gpio/gpio${GPIO_MUTE}/direction 2>/dev/null
fi

if [ -d /sys/class/gpio/gpio${GPIO_MUTE} ]; then
    echo 1 > /sys/class/gpio/gpio${GPIO_MUTE}/value 2>/dev/null
    sleep 0.01
fi
if [ -d /sys/class/gpio/gpio${GPIO_RESET} ]; then
    echo 0 > /sys/class/gpio/gpio${GPIO_RESET}/value 2>/dev/null
    sleep 0.01
    echo 1 > /sys/class/gpio/gpio${GPIO_RESET}/value 2>/dev/null
    sleep 0.1
fi
if [ -d /sys/class/gpio/gpio${GPIO_MUTE} ]; then
    echo 0 > /sys/class/gpio/gpio${GPIO_MUTE}/value 2>/dev/null
fi
sleep 0.2
SCRIPT
        sudo chmod +x /usr/local/bin/reset-amp100.sh
        
        sudo tee /etc/systemd/system/reset-amp100.service > /dev/null << 'SERVICE'
[Unit]
Description=Reset HiFiBerry AMP100 before driver load
Before=systemd-modules-load.service
DefaultDependencies=no

[Service]
Type=oneshot
ExecStart=/usr/local/bin/reset-amp100.sh
RemainAfterExit=yes

[Install]
WantedBy=sysinit.target
SERVICE
        sudo systemctl daemon-reload
        sudo systemctl enable reset-amp100.service
        echo "✅ Reset-Service erstellt"
    fi
else
    echo "⚠️  AMP100 nicht erkannt"
fi

ENDSSH

# 3. KOPIERE CUSTOM OVERLAY (falls vorhanden)
echo ""
echo "=== 3. CUSTOM OVERLAY KOPIEREN ==="
echo ""

if [ -f "/Users/andrevollmer/Library/Mobile Documents/com~apple~CloudDocs/Ablage/Roon filters/Bose Wave/OS/RPi4/moodeaudio/cursor/hifiberry-amp100-pi5.dtbo" ]; then
    sshpass -p "0815" scp -o StrictHostKeyChecking=no \
        "/Users/andrevollmer/Library/Mobile Documents/com~apple~CloudDocs/Ablage/Roon filters/Bose Wave/OS/RPi4/moodeaudio/cursor/hifiberry-amp100-pi5.dtbo" \
        andre@$PI_HOST:/tmp/hifiberry-amp100-pi5.dtbo 2>/dev/null
    
    sshpass -p "0815" ssh -o StrictHostKeyChecking=no andre@$PI_HOST << 'ENDSSH'
        if [ -f /tmp/hifiberry-amp100-pi5.dtbo ]; then
            sudo cp /tmp/hifiberry-amp100-pi5.dtbo /boot/firmware/overlays/
            echo "✅ Custom Overlay kopiert"
        fi
ENDSSH
fi

echo ""
echo "============================================================"
echo "SETUP ABGESCHLOSSEN"
echo "============================================================"
echo ""
echo "Nächster Schritt: Reboot"
echo "  ssh andre@$PI_HOST 'sudo reboot'"
echo ""

