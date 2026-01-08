#!/bin/bash
# Installation Script für DSP Reset auf AMP100

echo "=== INSTALLIERE DSP RESET ==="

# 1. Overlay erstellen
cat > /tmp/hifiberry-amp100-pi5-dsp-reset.dts << 'EOF'
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
                CPVDD-supply = <&cpvdd_supply>;
                status = "okay";
                i2c-scl-falling-time-ns = <100>;
                i2c-scl-rising-time-ns = <100>;
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
};
EOF

# 2. Overlay kompilieren
sudo dtc -@ -I dts -O dtb -o /boot/firmware/overlays/hifiberry-amp100-pi5-dsp-reset.dtbo /tmp/hifiberry-amp100-pi5-dsp-reset.dts
sudo chmod 644 /boot/firmware/overlays/hifiberry-amp100-pi5-dsp-reset.dtbo
echo "✅ Overlay kompiliert"

# 3. Reset-Script erstellen
sudo tee /usr/local/bin/dsp-reset-amp100.sh > /dev/null << 'SCRIPTEOF'
#!/bin/bash
if [ ! -d /sys/class/gpio/gpio17 ]; then
    echo 17 >/sys/class/gpio/export 2>/dev/null
    sleep 0.1
fi
if [ -d /sys/class/gpio/gpio17 ]; then
    echo out >/sys/class/gpio/gpio17/direction 2>/dev/null
    if [ ! -d /sys/class/gpio/gpio4 ]; then
        echo 4 >/sys/class/gpio/export 2>/dev/null
        sleep 0.1
    fi
    if [ -d /sys/class/gpio/gpio4 ]; then
        echo out >/sys/class/gpio/gpio4/direction 2>/dev/null
        echo 1 >/sys/class/gpio/gpio4/value 2>/dev/null
        sleep 0.01
    fi
    echo 0 >/sys/class/gpio/gpio17/value 2>/dev/null
    sleep 0.1
    echo 1 >/sys/class/gpio/gpio17/value 2>/dev/null
    sleep 0.01
    if [ -d /sys/class/gpio/gpio4 ]; then
        echo 0 >/sys/class/gpio/gpio4/value 2>/dev/null
    fi
fi
SCRIPTEOF

sudo chmod +x /usr/local/bin/dsp-reset-amp100.sh
echo "✅ Reset-Script erstellt"

# 4. Service erstellen
sudo tee /etc/systemd/system/dsp-reset-amp100.service > /dev/null << 'SERVICEEOF'
[Unit]
Description=Reset AMP100 via DSP Add-on GPIO 17 before driver load
Before=sound.target
Before=alsa-restore.service
DefaultDependencies=no
[Service]
Type=oneshot
ExecStart=/usr/local/bin/dsp-reset-amp100.sh
RemainAfterExit=yes
StandardOutput=journal
StandardError=journal
[Install]
WantedBy=multi-user.target
SERVICEEOF

sudo systemctl daemon-reload
sudo systemctl enable dsp-reset-amp100.service
echo "✅ Service erstellt und aktiviert"

# 5. config.txt aktualisieren
sudo sed -i 's/dtoverlay=hifiberry-amp100-pi5-gpio14/dtoverlay=hifiberry-amp100-pi5-dsp-reset/' /boot/firmware/config.txt
echo "✅ config.txt aktualisiert"

# 6. Prüfen
echo ""
echo "=== PRÜFUNG ==="
grep 'dtoverlay.*amp100' /boot/firmware/config.txt
ls -la /boot/firmware/overlays/hifiberry-amp100-pi5-dsp-reset.dtbo
systemctl is-enabled dsp-reset-amp100.service

echo ""
echo "✅ INSTALLATION ABGESCHLOSSEN!"
echo "⚠️  REBOOT ERFORDERLICH: sudo reboot"

