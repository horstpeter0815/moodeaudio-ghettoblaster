#!/bin/bash
################################################################################
# SETUP FÜR BEIDE PI5 MIT RASPIOS
# - Display: Landscape, kein Touchscreen
# - Audio: HiFiBerry AMP100
################################################################################

set -e

PI1="andre@192.168.178.143"
PI2="andre@192.168.178.134"

echo "============================================================"
echo "SETUP BEIDE PI5 RASPIOS - DISPLAY (LANDSCAPE) + AUDIO"
echo "============================================================"
echo ""

for PI in "$PI1" "$PI2"; do
    PI_IP=$(echo $PI | cut -d'@' -f2)
    echo "=== WARTE AUF $PI_IP ==="
    
    # Warte bis Pi erreichbar ist
    MAX_WAIT=120
    WAITED=0
    while ! ping -c 1 -W 1 $PI_IP > /dev/null 2>&1; do
        if [ $WAITED -ge $MAX_WAIT ]; then
            echo "⚠️  $PI_IP nicht erreichbar nach $MAX_WAIT Sekunden - überspringe"
            continue 2
        fi
        sleep 2
        WAITED=$((WAITED + 2))
        echo -n "."
    done
    echo ""
    echo "✅ $PI_IP ist erreichbar"
    echo ""
    
    echo "=== KONFIGURIERE $PI_IP ==="
    echo ""
    
    sshpass -p "0815" ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no $PI << 'ENDSSH'
set -e

echo "1. DISPLAY KONFIGURATION (LANDSCAPE, KEIN TOUCHSCREEN)"
echo ""

# X Server Konfiguration - Landscape, kein Touchscreen
mkdir -p ~/.config
cat > ~/.xinitrc << 'XINITRC'
#!/bin/sh
export DISPLAY=:0

# Display Rotation: Landscape (kein Touchscreen nötig)
xrandr --output HDMI-1 --rotate normal 2>/dev/null || xrandr --output HDMI-A-1 --rotate normal 2>/dev/null || true

# Chromium im Kiosk-Mode starten
chromium-browser --kiosk --noerrdialogs --disable-infobars --disable-session-crashed-bubble --disable-infobars http://localhost/ &
XINITRC
chmod +x ~/.xinitrc
echo "✅ .xinitrc erstellt (Landscape, kein Touchscreen)"

# Systemd Service für Display
sudo tee /etc/systemd/system/localdisplay.service > /dev/null << 'SERVICE'
[Unit]
Description=Local Display (X + Chromium)
After=graphical.target

[Service]
User=andre
Type=simple
ExecStart=/usr/bin/xinit
Restart=always
RestartSec=5
Environment=DISPLAY=:0

[Install]
WantedBy=graphical.target
SERVICE
sudo systemctl daemon-reload
sudo systemctl enable localdisplay.service
echo "✅ localdisplay.service erstellt"

echo ""
echo "2. AUDIO KONFIGURATION (AMP100)"
echo ""

# Prüfe ob AMP100 vorhanden ist
AMP100_FOUND=0
for bus in 1 13 14 15; do
    if [ -e /dev/i2c-$bus ]; then
        if i2cdetect -y $bus 2>/dev/null | grep -q "4d"; then
            echo "✅ AMP100 gefunden auf Bus $bus"
            AMP100_FOUND=1
            break
        fi
    fi
done

if [ $AMP100_FOUND -eq 1 ]; then
    # Custom Overlay aktivieren
    if ! grep -q "hifiberry-amp100-pi5" /boot/firmware/config.txt 2>/dev/null; then
        echo "dtoverlay=hifiberry-amp100-pi5" | sudo tee -a /boot/firmware/config.txt
        echo "✅ Custom Overlay aktiviert"
    fi
    
    # Reset-Service erstellen
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
    echo "⚠️  AMP100 nicht gefunden - Audio-Setup übersprungen"
fi

echo ""
echo "3. CONFIG.TXT ÜBERPRÜFUNG"
echo ""

# Prüfe config.txt
if [ -f /boot/firmware/config.txt ]; then
    echo "Aktive Overlays:"
    grep "^dtoverlay" /boot/firmware/config.txt | grep -v "^#" | tail -5
else
    echo "⚠️  config.txt nicht gefunden"
fi

echo ""
echo "✅ Setup für $(hostname) abgeschlossen"
echo ""

ENDSSH

    echo ""
done

echo "============================================================"
echo "SETUP ABGESCHLOSSEN"
echo "============================================================"
echo ""
echo "Nächster Schritt: Reboot beider Pis"
echo "  sshpass -p '0815' ssh andre@192.168.178.143 'sudo reboot'"
echo "  sshpass -p '0815' ssh andre@192.168.178.134 'sudo reboot'"
echo ""

