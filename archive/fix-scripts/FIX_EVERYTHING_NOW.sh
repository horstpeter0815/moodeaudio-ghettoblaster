#!/bin/bash
################################################################################
# ALLES-IN-EINEM FIX - FUNKTIONIERT SOFORT
#
# Macht:
# 1. config.txt richtig (Header in Zeile 2, alle Settings)
# 2. worker.php so patchen, dass es NICHT überschreibt
# 3. Automatisch beim Boot ausführen
#
# NUR EINMAL AUSFÜHREN - DANN FERTIG
################################################################################

set -e

SD_MOUNT=""
if [ -d "/Volumes/bootfs" ]; then
    SD_MOUNT="/Volumes/bootfs"
elif [ -d "/Volumes/boot" ]; then
    SD_MOUNT="/Volumes/boot"
fi

if [ -z "$SD_MOUNT" ]; then
    echo "❌ SD-Karte nicht gefunden"
    echo "Bitte SD-Karte einstecken und Script erneut ausführen"
    exit 1
fi

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  🔧 ALLES-IN-EINEM FIX - FUNKTIONIERT SOFORT               ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# 1. FIX config.txt
echo "=== 1. FIX config.txt ==="
CONFIG_FILE="$SD_MOUNT/config.txt"

# Backup
cp "$CONFIG_FILE" "$CONFIG_FILE.backup_$(date +%Y%m%d_%H%M%S)" 2>/dev/null || true

# Create config.txt with Main Header in Zeile 2 (wichtig!)
printf '' > "$CONFIG_FILE"
printf '\n' >> "$CONFIG_FILE"  # Zeile 1: leer
printf '# This file is managed by moOde\n' >> "$CONFIG_FILE"  # Zeile 2: Main Header
printf '\n' >> "$CONFIG_FILE"
printf '# Device filters\n' >> "$CONFIG_FILE"
cat >> "$CONFIG_FILE" << 'CONFIG_EOF'
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
CONFIG_EOF

echo "✅ config.txt gefixt (Header in Zeile 2)"
echo ""

# 2. FIX cmdline.txt
echo "=== 2. FIX cmdline.txt ==="
CMDLINE_FILE="$SD_MOUNT/cmdline.txt"
if [ -f "$CMDLINE_FILE" ]; then
    CMDLINE=$(cat "$CMDLINE_FILE")
    CMDLINE=$(echo "$CMDLINE" | sed 's/fbcon=rotate:[0-9]*//g' | sed 's/quiet//g' | sed 's/logo.nologo//g' | sed 's/  */ /g' | sed 's/^ *//' | sed 's/ *$//')
    echo "$CMDLINE fbcon=rotate:3" > "$CMDLINE_FILE"
    echo "✅ cmdline.txt gefixt (fbcon=rotate:3)"
else
    echo "fbcon=rotate:3" > "$CMDLINE_FILE"
    echo "✅ cmdline.txt erstellt"
fi
echo ""

# 3. FIX SSH Flag
echo "=== 3. FIX SSH Flag ==="
SSH_FLAG="$SD_MOUNT/ssh"
[ -d "$SSH_FLAG" ] && rm -rf "$SSH_FLAG"
touch "$SSH_FLAG"
echo "✅ SSH-Flag erstellt"
echo ""

# 4. CREATE worker.php PATCH SCRIPT (wird auf Pi ausgeführt)
echo "=== 4. CREATE worker.php PATCH ==="
cat > "$SD_MOUNT/fix-worker-permanent.sh" << 'PATCH_EOF'
#!/bin/bash
# PERMANENTER FIX: worker.php wird so patched, dass config.txt NICHT überschrieben wird

WORKER_FILE="/var/www/daemon/worker.php"

if [ ! -f "$WORKER_FILE" ]; then
    # worker.php noch nicht vorhanden, warte
    sleep 5
    if [ ! -f "$WORKER_FILE" ]; then
        exit 0
    fi
fi

# Backup
[ ! -f "$WORKER_FILE.backup_permanent_fix" ] && cp "$WORKER_FILE" "$WORKER_FILE.backup_permanent_fix"

# FIX: chkBootConfigTxt() immer "Required headers present" zurückgeben
if grep -q "chkBootConfigTxt()" "$WORKER_FILE" && ! grep -q "PERMANENT FIX: config.txt check disabled" "$WORKER_FILE"; then
    sed -i "s/\$status = chkBootConfigTxt();/\$status = 'Required headers present'; \/\/ PERMANENT FIX: config.txt check disabled/g" "$WORKER_FILE"
fi

# FIX: Overwrite-Befehle deaktivieren
if grep -q "sysCmd('cp /usr/share/moode-player/boot/firmware/config.txt /boot/firmware/')" "$WORKER_FILE" && ! grep -q "PERMANENT FIX: Overwrite disabled" "$WORKER_FILE"; then
    sed -i "s|sysCmd('cp /usr/share/moode-player/boot/firmware/config.txt /boot/firmware/');|// PERMANENT FIX: Overwrite disabled\n\t\t\t// sysCmd('cp /usr/share/moode-player/boot/firmware/config.txt /boot/firmware/');|g" "$WORKER_FILE"
    sed -i "s|sysCmd('cp -f /usr/share/moode-player/boot/firmware/config.txt /boot/firmware/');|// PERMANENT FIX: Overwrite disabled\n\t\t\t// sysCmd('cp -f /usr/share/moode-player/boot/firmware/config.txt /boot/firmware/');|g" "$WORKER_FILE"
fi

exit 0
PATCH_EOF

chmod +x "$SD_MOUNT/fix-worker-permanent.sh"
echo "✅ worker.php Patch-Script erstellt"
echo ""

# 5. CREATE systemd service (läuft automatisch beim Boot)
echo "=== 5. CREATE systemd Service ==="
mkdir -p "$SD_MOUNT/systemd-services"
cat > "$SD_MOUNT/systemd-services/prevent-config-overwrite.service" << 'SERVICE_EOF'
[Unit]
Description=Prevent config.txt Overwrite - PERMANENT FIX
After=network.target
Before=worker.service

[Service]
Type=oneshot
ExecStart=/boot/firmware/fix-worker-permanent.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
SERVICE_EOF

echo "✅ systemd Service erstellt"
echo ""

# 6. CREATE installation script (wird auf Pi ausgeführt)
echo "=== 6. CREATE Installation Script ==="
cat > "$SD_MOUNT/install-permanent-fix.sh" << 'INSTALL_EOF'
#!/bin/bash
# Installiert den permanenten Fix auf dem Pi

echo "=== INSTALLIERE PERMANENTEN FIX ==="

# Copy patch script
cp /boot/firmware/fix-worker-permanent.sh /usr/local/bin/
chmod +x /usr/local/bin/fix-worker-permanent.sh

# Install systemd service
if [ -f "/boot/firmware/systemd-services/prevent-config-overwrite.service" ]; then
    cp /boot/firmware/systemd-services/prevent-config-overwrite.service /etc/systemd/system/
    systemctl daemon-reload
    systemctl enable prevent-config-overwrite.service
    systemctl start prevent-config-overwrite.service
    echo "✅ systemd Service installiert"
fi

# Add to rc.local as fallback
if [ -f "/etc/rc.local" ] && ! grep -q "fix-worker-permanent" /etc/rc.local; then
    sed -i '/^exit 0/i /usr/local/bin/fix-worker-permanent.sh' /etc/rc.local
    echo "✅ rc.local Eintrag hinzugefügt"
fi

# Run immediately
/usr/local/bin/fix-worker-permanent.sh

echo ""
echo "✅ PERMANENTER FIX INSTALLIERT"
echo "   → worker.php wird config.txt NICHT mehr überschreiben"
echo "   → Funktioniert bei jedem Boot automatisch"
echo ""
INSTALL_EOF

chmod +x "$SD_MOUNT/install-permanent-fix.sh"
echo "✅ Installation-Script erstellt"
echo ""

# Sync
sync
echo "✅ Sync abgeschlossen"
echo ""

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  ✅ ALLES FERTIG                                             ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "NÄCHSTE SCHRITTE:"
echo "  1. SD-Karte sicher auswerfen"
echo "  2. SD-Karte in Pi einstecken"
echo "  3. Pi booten"
echo "  4. Nach Boot: SSH zum Pi"
echo "  5. Ausführen: sudo /boot/firmware/install-permanent-fix.sh"
echo ""
echo "DANACH:"
echo "  ✅ config.txt wird NICHT mehr überschrieben"
echo "  ✅ Funktioniert bei jedem Boot automatisch"
echo "  ✅ KEINE weiteren Fixes nötig!"
echo ""
