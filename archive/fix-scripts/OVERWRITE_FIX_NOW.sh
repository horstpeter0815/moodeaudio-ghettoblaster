#!/bin/bash
################################################################################
# ÜBERSCHREIBE ALLES - FUNKTIONIERT SOFORT
#
# Überschreibt:
# 1. config.txt auf SD-Karte (Header in Zeile 2, alle Settings)
# 2. cmdline.txt (fbcon=rotate:3)
# 3. Erstellt worker.php Patch-Script (wird auf Pi ausgeführt)
# 4. Erstellt systemd Service (verhindert Overwrite)
#
# KEINE BESCHREIBUNG - NUR ÜBERSCHREIBEN
################################################################################

set -e

SD_MOUNT=""
if [ -d "/Volumes/bootfs" ]; then
    SD_MOUNT="/Volumes/bootfs"
elif [ -d "/Volumes/boot" ]; then
    SD_MOUNT="/Volumes/boot"
fi

if [ -z "$SD_MOUNT" ] || [ ! -w "$SD_MOUNT" ]; then
    echo "❌ SD-Karte nicht gefunden oder nicht beschreibbar"
    exit 1
fi

echo "=== ÜBERSCHREIBE ALLES ==="
echo ""

# 1. ÜBERSCHREIBE config.txt
echo "1. Überschreibe config.txt..."
CONFIG_FILE="$SD_MOUNT/config.txt"
printf '' > "$CONFIG_FILE"
printf '\n' >> "$CONFIG_FILE"  # Zeile 1: leer
printf '# This file is managed by moOde\n' >> "$CONFIG_FILE"  # Zeile 2: Main Header
printf '\n' >> "$CONFIG_FILE"
printf '# Device filters\n' >> "$CONFIG_FILE"
cat >> "$CONFIG_FILE" << 'EOF'
[pi5]
display_rotate=2
dtoverlay=vc4-kms-v3d-pi5,noaudio
hdmi_enable_4kp60=0
hdmi_timings=400 0 220 32 110 1280 0 10 10 10 0 0 0 60 0 59510000 0
hdmi_ignore_edid=0xa5000080
hdmi_force_hotplug=1
disable_splash=1
arm_boost=1
gpu_freq=750

[all]
max_framebuffers=2
display_auto_detect=1
arm_64bit=1
disable_overscan=1
dtparam=i2c_arm=on
dtparam=i2c_arm_baudrate=100000
dtparam=i2c_vc=on
dtparam=i2s=on
dtparam=audio=off

# General settings
hdmi_group=2
hdmi_mode=87
hdmi_drive=2
hdmi_blanking=0

# Do not alter this section
# Integrated adapters
#dtoverlay=disable-bt
#dtoverlay=disable-wifi

# Audio overlays
dtoverlay=hifiberry-amp100
force_eeprom_read=0
EOF
echo "✅ config.txt überschrieben"

# 2. ÜBERSCHREIBE cmdline.txt
echo "2. Überschreibe cmdline.txt..."
CMDLINE_FILE="$SD_MOUNT/cmdline.txt"
if [ -f "$CMDLINE_FILE" ]; then
    CMDLINE=$(cat "$CMDLINE_FILE")
    CMDLINE=$(echo "$CMDLINE" | sed 's/fbcon=rotate:[0-9]*//g' | sed 's/quiet//g' | sed 's/logo.nologo//g' | sed 's/  */ /g' | sed 's/^ *//' | sed 's/ *$//')
    echo "$CMDLINE fbcon=rotate:3" > "$CMDLINE_FILE"
else
    echo "fbcon=rotate:3" > "$CMDLINE_FILE"
fi
echo "✅ cmdline.txt überschrieben"

# 3. ÜBERSCHREIBE/CREATE SSH Flag
echo "3. Überschreibe SSH Flag..."
SSH_FLAG="$SD_MOUNT/ssh"
[ -d "$SSH_FLAG" ] && rm -rf "$SSH_FLAG"
printf '' > "$SSH_FLAG"
echo "✅ SSH Flag überschrieben"

# 4. ÜBERSCHREIBE/CREATE worker.php Patch (wird auf Pi ausgeführt)
echo "4. Überschreibe worker.php Patch-Script..."
cat > "$SD_MOUNT/patch-worker-no-overwrite.sh" << 'PATCH_EOF'
#!/bin/bash
# ÜBERSCHREIBT worker.php - verhindert config.txt Overwrite

WORKER="/var/www/daemon/worker.php"
[ ! -f "$WORKER" ] && exit 0

# Backup
[ ! -f "$WORKER.backup_fix" ] && cp "$WORKER" "$WORKER.backup_fix"

# ÜBERSCHREIBE: chkBootConfigTxt() immer "Required headers present" zurückgeben
sed -i "s/\$status = chkBootConfigTxt();/\$status = 'Required headers present'; \/\/ FIX: Overwrite disabled/g" "$WORKER"

# ÜBERSCHREIBE: Overwrite-Befehle deaktivieren
sed -i "s|sysCmd('cp /usr/share/moode-player/boot/firmware/config.txt /boot/firmware/');|// FIX: Overwrite disabled\n\t\t\t// sysCmd('cp /usr/share/moode-player/boot/firmware/config.txt /boot/firmware/');|g" "$WORKER"
sed -i "s|sysCmd('cp -f /usr/share/moode-player/boot/firmware/config.txt /boot/firmware/');|// FIX: Overwrite disabled\n\t\t\t// sysCmd('cp -f /usr/share/moode-player/boot/firmware/config.txt /boot/firmware/');|g" "$WORKER"

exit 0
PATCH_EOF
chmod +x "$SD_MOUNT/patch-worker-no-overwrite.sh"
echo "✅ worker.php Patch-Script überschrieben"

# 5. ÜBERSCHREIBE/CREATE systemd Service
echo "5. Überschreibe systemd Service..."
mkdir -p "$SD_MOUNT/systemd-services"
cat > "$SD_MOUNT/systemd-services/prevent-overwrite.service" << 'SERVICE_EOF'
[Unit]
Description=Prevent config.txt Overwrite
After=network.target
Before=worker.service

[Service]
Type=oneshot
ExecStart=/boot/firmware/patch-worker-no-overwrite.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
SERVICE_EOF
echo "✅ systemd Service überschrieben"

# 6. ÜBERSCHREIBE/CREATE Installation Script
echo "6. Überschreibe Installation Script..."
cat > "$SD_MOUNT/install-fix.sh" << 'INSTALL_EOF'
#!/bin/bash
# Installiert Fix auf Pi

cp /boot/firmware/patch-worker-no-overwrite.sh /usr/local/bin/
chmod +x /usr/local/bin/patch-worker-no-overwrite.sh

if [ -f "/boot/firmware/systemd-services/prevent-overwrite.service" ]; then
    cp /boot/firmware/systemd-services/prevent-overwrite.service /etc/systemd/system/
    systemctl daemon-reload
    systemctl enable prevent-overwrite.service
    systemctl start prevent-overwrite.service
fi

/usr/local/bin/patch-worker-no-overwrite.sh

echo "✅ Fix installiert - config.txt wird NICHT mehr überschrieben"
INSTALL_EOF
chmod +x "$SD_MOUNT/install-fix.sh"
echo "✅ Installation Script überschrieben"

sync
echo ""
echo "✅ ALLES ÜBERSCHRIEBEN"
echo ""
echo "Nach Boot: sudo /boot/firmware/install-fix.sh"
echo ""

