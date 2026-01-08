#!/bin/bash
################################################################################
# SETUP FÜR BEIDE PI5
# - Ghettoblaster (moOde): Display + Audio (AMP100)
# - Pi5-2 (RaspiOS): Display Landscape + Audio (AMP100 falls vorhanden)
################################################################################

set -e

PI1="andre@ghettoblaster.local"
PI2_IPS=("andre@192.168.178.134" "andre@ghettopi5-2.local")

echo "============================================================"
echo "SETUP BEIDE PI5 - DISPLAY + AUDIO"
echo "============================================================"
echo ""

# ============================================================================
# PI1: GHETTOBLASTER (moOde)
# ============================================================================
echo "=== KONFIGURIERE GHETTOBLASTER (moOde) ==="
echo ""

sshpass -p "0815" ssh -o StrictHostKeyChecking=no $PI1 << 'ENDSSH'
set -e

echo "1. DISPLAY: Landscape prüfen"
OUTPUT=$(xrandr 2>/dev/null | grep " connected" | awk '{print $1}' | head -1)
if [ -n "$OUTPUT" ]; then
    CURRENT_ROT=$(xrandr 2>/dev/null | grep "$OUTPUT" | grep -o "rotate [a-z]*" | awk '{print $2}' || echo "normal")
    if [ "$CURRENT_ROT" != "normal" ]; then
        xrandr --output "$OUTPUT" --rotate normal 2>/dev/null && echo "✅ Rotation auf Landscape gesetzt" || echo "⚠️  Rotation konnte nicht gesetzt werden"
    else
        echo "✅ Display bereits Landscape"
    fi
else
    echo "⚠️  Kein Display gefunden"
fi

# .xinitrc prüfen
if [ -f ~/.xinitrc ]; then
    if ! grep -q "rotate normal" ~/.xinitrc; then
        sed -i '/xrandr/d' ~/.xinitrc
        sed -i '/chromium/i xrandr --output HDMI-1 --rotate normal 2>/dev/null || xrandr --output HDMI-A-1 --rotate normal 2>/dev/null || true' ~/.xinitrc
        echo "✅ .xinitrc aktualisiert"
    fi
fi
echo ""

echo "2. AUDIO: AMP100 Status"
for bus in 1 13 14 15; do
    if [ -e /dev/i2c-$bus ]; then
        if i2cdetect -y $bus 2>/dev/null | grep -q "4d"; then
            echo "✅ AMP100 auf Bus $bus gefunden"
            break
        fi
    fi
done

# Prüfe Soundcard
if [ "$(cat /proc/asound/cards)" = "--- no soundcards ---" ]; then
    echo "⚠️  Keine Soundcard - Overlay prüfen"
    if ! grep -q "hifiberry-amp100-pi5" /boot/firmware/config.txt; then
        echo "dtoverlay=hifiberry-amp100-pi5" | sudo tee -a /boot/firmware/config.txt
        echo "✅ Overlay aktiviert - REBOOT nötig"
    fi
else
    echo "✅ Soundcard gefunden:"
    cat /proc/asound/cards
fi
echo ""

ENDSSH

echo ""
echo "=== GHETTOBLASTER FERTIG ==="
echo ""

# ============================================================================
# PI2: RASPIOS
# ============================================================================
echo "=== KONFIGURIERE PI5-2 (RaspiOS) ==="
echo ""

PI2=""
for PI in "${PI2_IPS[@]}"; do
    PI_IP=$(echo $PI | cut -d'@' -f2)
    if ping -c 1 -W 2 $PI_IP > /dev/null 2>&1; then
        if sshpass -p "0815" ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no $PI "hostname" > /dev/null 2>&1; then
            PI2=$PI
            echo "✅ Pi5-2 gefunden: $PI_IP"
            break
        fi
    fi
done

if [ -z "$PI2" ]; then
    echo "⚠️  Pi5-2 nicht erreichbar - überspringe"
else
    sshpass -p "0815" ssh -o StrictHostKeyChecking=no $PI2 << 'ENDSSH'
set -e

echo "1. PRÜFE OS:"
cat /etc/os-release | grep PRETTY_NAME
echo ""

echo "2. DISPLAY SETUP (Landscape, kein Touchscreen)"
# Installiere X falls nicht vorhanden
if ! command -v xinit >/dev/null 2>&1; then
    echo "Installiere X..."
    sudo apt-get update -qq
    sudo apt-get install -y xinit xserver-xorg chromium-browser > /dev/null 2>&1
fi

# Erstelle .xinitrc
mkdir -p ~/.config
cat > ~/.xinitrc << 'XINITRC'
#!/bin/sh
export DISPLAY=:0

# Display Rotation: Landscape (kein Touchscreen)
OUTPUT=$(xrandr 2>/dev/null | grep " connected" | awk '{print $1}' | head -1)
if [ -n "$OUTPUT" ]; then
    xrandr --output "$OUTPUT" --rotate normal 2>/dev/null || true
fi

# Chromium im Kiosk-Mode
chromium-browser --kiosk --noerrdialogs --disable-infobars --disable-session-crashed-bubble http://localhost/ &
XINITRC
chmod +x ~/.xinitrc
echo "✅ .xinitrc erstellt"

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

echo "3. AUDIO SETUP (AMP100)"
# Prüfe ob AMP100 vorhanden ist
AMP100_FOUND=0
AMP100_BUS=""
for bus in 1 13 14 15; do
    if [ -e /dev/i2c-$bus ]; then
        if i2cdetect -y $bus 2>/dev/null | grep -q "4d"; then
            echo "✅ AMP100 gefunden auf Bus $bus"
            AMP100_FOUND=1
            AMP100_BUS=$bus
            break
        fi
    fi
done

if [ $AMP100_FOUND -eq 1 ]; then
    # Installiere dtc falls nicht vorhanden
    if ! command -v dtc >/dev/null 2>&1; then
        sudo apt-get install -y device-tree-compiler > /dev/null 2>&1
    fi
    
    # Prüfe ob Custom Overlay existiert
    if [ ! -f /boot/firmware/overlays/hifiberry-amp100-pi5.dtbo ]; then
        echo "Erstelle Custom Overlay..."
        cd /tmp
        cat > hifiberry-amp100-pi5.dts << 'DTS'
/dts-v1/;
/plugin/;

/ {
    compatible = "brcm,bcm2712";
    
    fragment@0 {
        target-path = "/";
        __overlay__ {
            dacpro_osc {
                compatible = "hifiberry,dacpro-clk";
                #clock-cells = <0>;
                phandle = <0x01>;
            };
        };
    };
    
    fragment@1 {
        target = <&i2s_clk_consumer>;
        __overlay__ {
            status = "okay";
        };
    };
    
    fragment@2 {
        target-path = "/axi/pcie@1000120000/rp1/i2c@74000";
        __overlay__ {
            #address-cells = <1>;
            #size-cells = <0>;
            status = "okay";
            
            pcm5122@4d {
                #sound-dai-cells = <0>;
                compatible = "ti,pcm5122";
                reg = <0x4d>;
                clocks = <0x01>;
                AVDD-supply = <&vdd_3v3_reg>;
                DVDD-supply = <&vdd_3v3_reg>;
                CPVDD-supply = <&vdd_3v3_reg>;
                status = "okay";
            };
        };
    };
    
    fragment@3 {
        target-path = "/soc@107c000000";
        __overlay__ {
            sound {
                compatible = "hifiberry,hifiberry-dacplus";
                i2s-controller = <&i2s_clk_consumer>;
                status = "okay";
            };
        };
    };
    
    __fixups__ {
        i2s_clk_consumer = "/fragment@1:target:0", "/fragment@3/__overlay__/sound:i2s-controller:0";
        vdd_3v3_reg = "/fragment@2/__overlay__/pcm5122@4d:AVDD-supply:0", "/fragment@2/__overlay__/pcm5122@4d:DVDD-supply:0", "/fragment@2/__overlay__/pcm5122@4d:CPVDD-supply:0";
    };
    
    __local_fixups__ {
        fragment@2 {
            __overlay__ {
                pcm5122@4d {
                    clocks = <0x00>;
                };
            };
        };
    };
};
DTS
        dtc -@ -I dts -O dtb -o hifiberry-amp100-pi5.dtbo hifiberry-amp100-pi5.dts 2>&1 | grep -v "Warning" || true
        if [ -f hifiberry-amp100-pi5.dtbo ]; then
            sudo cp hifiberry-amp100-pi5.dtbo /boot/firmware/overlays/
            sudo cp hifiberry-amp100-pi5.dts /boot/firmware/overlays/
            echo "✅ Custom Overlay erstellt"
        fi
    fi
    
    # Aktiviere Overlay
    if ! grep -q "hifiberry-amp100-pi5" /boot/firmware/config.txt; then
        echo "dtoverlay=hifiberry-amp100-pi5" | sudo tee -a /boot/firmware/config.txt
        echo "✅ Overlay aktiviert"
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

echo "4. STATUS:"
echo "Display Service:"
systemctl is-enabled localdisplay.service && echo "✅ Aktiviert" || echo "❌ Nicht aktiviert"
echo ""
echo "Audio:"
cat /proc/asound/cards
echo ""

ENDSSH
fi

echo ""
echo "============================================================"
echo "SETUP ABGESCHLOSSEN"
echo "============================================================"
echo ""
echo "Nächster Schritt: Reboot beider Pis falls nötig"
echo ""

