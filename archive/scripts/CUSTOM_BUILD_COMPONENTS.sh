#!/bin/bash
# Ghettoblaster - Custom Build Components
# Erstellt alle Custom Komponenten für den Build

LOG_FILE="custom-build-components-$(date +%Y%m%d_%H%M%S).log"
COMPONENTS_DIR="custom-components"

log() {
    echo "[$(date +%H:%M:%S)] $1" | tee -a "$LOG_FILE"
}

echo "=== GHETTOBLASTER CUSTOM BUILD COMPONENTS ===" | tee -a "$LOG_FILE"

# Erstelle Verzeichnisse
mkdir -p "$COMPONENTS_DIR"/{overlays,services,configs,scripts,packages}

log ""
log "=== SCHRITT 1: CUSTOM OVERLAYS ==="

# FT6236 Overlay für Pi 5
cat > "$COMPONENTS_DIR/overlays/ghettoblaster-ft6236.dts" << 'OVERLAY_EOF'
/dts-v1/;
/plugin/;

/ {
    compatible = "brcm,bcm2712";

    fragment@0 {
        target = <&i2c1>;
        __overlay__ {
            #address-cells = <1>;
            #size-cells = <0>;
            status = "okay";

            ft6236: ft6236@38 {
                compatible = "focaltech,ft6236";
                reg = <0x38>;
                interrupt-parent = <&gpio>;
                interrupts = <25 2>; /* GPIO 25, falling edge */
                touchscreen-size-x = <1280>;
                touchscreen-size-y = <400>;
                touchscreen-inverted-x;
                touchscreen-inverted-y;
                touchscreen-swapped-x-y;
            };
        };
    };
};
OVERLAY_EOF

log "✅ FT6236 Overlay erstellt"

# AMP100 Overlay für Pi 5
cat > "$COMPONENTS_DIR/overlays/ghettoblaster-amp100.dts" << 'OVERLAY_EOF'
/dts-v1/;
/plugin/;

/ {
    compatible = "brcm,bcm2712";

    fragment@0 {
        target = <&i2c1>;
        __overlay__ {
            #address-cells = <1>;
            #size-cells = <0>;
            status = "okay";
            clock-frequency = <100000>;

            pcm5122: pcm5122@4d {
                #sound-dai-cells = <0>;
                compatible = "ti,pcm5122";
                reg = <0x4d>;
                clocks = <&audio>;
                AVDD-supply = <&vdd_3v3_reg>;
                DVDD-supply = <&vdd_3v3_reg>;
                CPVDD-supply = <&vdd_3v3_reg>;
            };
        };
    };

    fragment@1 {
        target = <&sound>;
        __overlay__ {
            compatible = "hifiberry,hifiberry-amp";
            i2s-controller = <&i2s>;
            status = "okay";
        };
    };
};
OVERLAY_EOF

log "✅ AMP100 Overlay erstellt"

log ""
log "=== SCHRITT 2: CUSTOM SERVICES ==="

# localdisplay.service
cat > "$COMPONENTS_DIR/services/localdisplay.service" << 'SERVICE_EOF'
[Unit]
Description=Start Local Display (Ghettoblaster)
After=graphical.target
After=xserver-ready.service
Wants=graphical.target
Wants=xserver-ready.service
Requires=graphical.target

[Service]
Type=simple
User=andre
Environment=DISPLAY=:0
Environment=XAUTHORITY=/home/andre/.Xauthority
ExecStartPre=/usr/local/bin/xserver-ready.sh
ExecStartPre=/bin/sleep 2
ExecStart=/usr/local/bin/start-chromium-clean.sh
TimeoutStartSec=60
Restart=on-failure
RestartSec=5
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
SERVICE_EOF

log "✅ localdisplay.service erstellt"

# xserver-ready.service
cat > "$COMPONENTS_DIR/services/xserver-ready.service" << 'SERVICE_EOF'
[Unit]
Description=X Server Ready Check
After=graphical.target
Wants=graphical.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/xserver-ready.sh
RemainAfterExit=yes
TimeoutStartSec=35

[Install]
WantedBy=graphical.target
SERVICE_EOF

log "✅ xserver-ready.service erstellt"

# ft6236-delay.service
cat > "$COMPONENTS_DIR/services/ft6236-delay.service" << 'SERVICE_EOF'
[Unit]
Description=Load FT6236 Touchscreen after Display
After=localdisplay.service
After=xserver-ready.service
Wants=localdisplay.service
Wants=xserver-ready.service
Requires=graphical.target

[Service]
Type=oneshot
ExecStartPre=/bin/sleep 2
ExecStart=/sbin/modprobe ft6236
ExecStartPost=/bin/sleep 1
RemainAfterExit=yes
TimeoutStartSec=10

[Install]
WantedBy=graphical.target
SERVICE_EOF

log "✅ ft6236-delay.service erstellt"

# peppymeter.service
cat > "$COMPONENTS_DIR/services/peppymeter.service" << 'SERVICE_EOF'
[Unit]
Description=PeppyMeter Audio Visualizer
After=localdisplay.service
After=mpd.service
Wants=localdisplay.service
Wants=mpd.service

[Service]
Type=simple
User=andre
Environment=DISPLAY=:0
Environment=XAUTHORITY=/home/andre/.Xauthority
ExecStart=/usr/local/bin/peppymeter-wrapper.sh
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
SERVICE_EOF

log "✅ peppymeter.service erstellt"

log ""
log "=== SCHRITT 3: CUSTOM SCRIPTS ==="

# xserver-ready.sh
cat > "$COMPONENTS_DIR/scripts/xserver-ready.sh" << 'SCRIPT_EOF'
#!/bin/bash
# Ghettoblaster - X Server Ready Check
export DISPLAY=:0
export XAUTHORITY=/home/andre/.Xauthority
MAX_WAIT=30
WAIT_INTERVAL=0.5
for i in $(seq 1 $((MAX_WAIT * 2))); do
    if timeout 1 xrandr --query >/dev/null 2>&1; then
        if timeout 1 xdpyinfo -display :0 >/dev/null 2>&1; then
            exit 0
        fi
    fi
    sleep $WAIT_INTERVAL
done
exit 1
SCRIPT_EOF
chmod +x "$COMPONENTS_DIR/scripts/xserver-ready.sh"
log "✅ xserver-ready.sh erstellt"

# start-chromium-clean.sh
cat > "$COMPONENTS_DIR/scripts/start-chromium-clean.sh" << 'SCRIPT_EOF'
#!/bin/bash
# Ghettoblaster - Clean Chromium Startup
export DISPLAY=:0
export XAUTHORITY=/home/andre/.Xauthority
LOG_FILE=/var/log/chromium-clean.log
log() {
    echo "[$(date +%Y-%m-%d %H:%M:%S)] $1" | tee -a "$LOG_FILE"
}
log "=== CHROMIUM CLEAN START ==="
/usr/local/bin/xserver-ready.sh || exit 1
log "✅ X Server bereit"
xhost +SI:localuser:andre 2>/dev/null || true
sleep 1
if xrandr | grep -q "400x1280"; then
    xrandr --output HDMI-2 --mode 400x1280 --rotate left 2>&1 || \
    xrandr --output HDMI-1 --mode 400x1280 --rotate left 2>&1
elif xrandr | grep -q "1280x400"; then
    xrandr --output HDMI-2 --mode 1280x400 --rotate normal 2>&1 || \
    xrandr --output HDMI-1 --mode 1280x400 --rotate normal 2>&1
fi
xset s off 2>/dev/null || true
xset -dpms 2>/dev/null || true
pkill -9 chromium 2>/dev/null || true
pkill -9 chromium-browser 2>/dev/null || true
sleep 2
rm -rf /tmp/chromium-data/Singleton* 2>/dev/null || true
log "Starte Chromium..."
chromium-browser \
    --kiosk \
    --no-sandbox \
    --user-data-dir=/tmp/chromium-data \
    --window-size=1280,400 \
    --window-position=0,0 \
    --start-fullscreen \
    --noerrdialogs \
    --disable-infobars \
    --disable-session-crashed-bubble \
    --disable-restore-session-state \
    --disable-web-security \
    --autoplay-policy=no-user-gesture-required \
    --check-for-update-interval=31536000 \
    --disable-features=TranslateUI \
    --disable-gpu \
    --disable-software-rasterizer \
    http://localhost >/dev/null 2>&1 &
CHROMIUM_PID=$!
sleep 3
if ps -p $CHROMIUM_PID > /dev/null 2>&1; then
    log "✅ Chromium gestartet (PID: $CHROMIUM_PID)"
    for i in {1..10}; do
        WINDOW=$(xdotool search --class Chromium 2>/dev/null | head -1)
        if [ -n "$WINDOW" ]; then
            xdotool windowsize $WINDOW 1280 400 2>/dev/null
            xdotool windowmove $WINDOW 0 0 2>/dev/null
            xdotool windowraise $WINDOW 2>/dev/null
            log "✅ Chromium Window gefunden"
            exit 0
        fi
        sleep 1
    done
    log "⚠️  Chromium läuft, aber Window nicht gefunden"
    exit 0
else
    log "❌ Chromium Start fehlgeschlagen"
    exit 1
fi
SCRIPT_EOF
chmod +x "$COMPONENTS_DIR/scripts/start-chromium-clean.sh"
log "✅ start-chromium-clean.sh erstellt"

log ""
log "=== SCHRITT 4: CONFIG TEMPLATES ==="

# config.txt Template
cat > "$COMPONENTS_DIR/configs/config.txt.template" << 'CONFIG_EOF'
# Ghettoblaster Custom Build - config.txt
# Raspberry Pi 5 Optimized

# Display
disable_overscan=1
display_rotate=3
dtoverlay=vc4-kms-v3d-pi5,noaudio

# Custom HDMI Mode (1280x400)
hdmi_group=2
hdmi_mode=87
hdmi_cvt=1280 400 60 6 0 0 0

# I2C
dtparam=i2c_arm=on
dtparam=i2c_arm_baudrate=100000

# SPI
dtparam=spi=on

# Audio - HiFiBerry AMP100
dtoverlay=hifiberry-amp100,automute

# Touchscreen - FT6236 (wird von Service geladen)
# dtoverlay=ft6236 (NICHT hier, wird von ft6236-delay.service geladen)

# Boot
boot_delay=0
CONFIG_EOF

log "✅ config.txt.template erstellt"

# cmdline.txt Template
cat > "$COMPONENTS_DIR/configs/cmdline.txt.template" << 'CMDLINE_EOF'
console=serial0,115200 console=tty1 root=PARTUUID=REPLACE_PARTUUID rootfstype=ext4 fsck.repair=yes rootwait cfg80211.ieee80211_regdom=DE systemd.show_status=yes fbcon=rotate:3
CMDLINE_EOF

log "✅ cmdline.txt.template erstellt"

log ""
log "=== SCHRITT 5: WORKER.PHP PATCH ==="

# Patch für worker.php (display_rotate=3)
cat > "$COMPONENTS_DIR/scripts/worker-php-patch.sh" << 'PATCH_EOF'
#!/bin/bash
# Ghettoblaster - worker.php Patch für display_rotate=3
WORKER_FILE="/var/www/daemon/worker.php"

# Prüfe ob Patch bereits angewendet wurde
if grep -q "Ghettoblaster: display_rotate=3" "$WORKER_FILE"; then
    exit 0
fi

# Patch anwenden
sed -i '/sysCmd.*cp.*config.txt.*\/boot\/firmware\//a\
		// Ghettoblaster: Stelle display_rotate=3 wieder her\
		sysCmd("sed -i \"/^display_rotate=/d\" /boot/firmware/config.txt");\
		sysCmd("echo \"display_rotate=3\" >> /boot/firmware/config.txt");
' "$WORKER_FILE"

echo "✅ worker.php Patch angewendet"
PATCH_EOF
chmod +x "$COMPONENTS_DIR/scripts/worker-php-patch.sh"
log "✅ worker.php Patch Script erstellt"

log ""
log "=== ZUSAMMENFASSUNG ==="
log "✅ Custom Overlays erstellt (FT6236, AMP100)"
log "✅ Custom Services erstellt (5 Services)"
log "✅ Custom Scripts erstellt (3 Scripts)"
log "✅ Config Templates erstellt"
log "✅ worker.php Patch vorbereitet"
log ""
log "Alle Komponenten in: $COMPONENTS_DIR/"

echo "==========================================" | tee -a "$LOG_FILE"
echo "✅ CUSTOM BUILD COMPONENTS ERSTELLT" | tee -a "$LOG_FILE"
echo "==========================================" | tee -a "$LOG_FILE"

