#!/bin/bash
# APPLY CONFIG - Kopiere diesen Inhalt in WebSSH Terminal

# Backup
sudo cp /boot/firmware/config.txt /boot/firmware/config.txt.backup_$(date +%Y%m%d_%H%M%S)

# Boot beschreibbar machen
sudo mount -o remount,rw /boot/firmware

# Config anwenden
sudo tee /boot/firmware/config.txt > /dev/null << 'CONFIG_EOF'
#########################################
# moOde Audio - Pi 5 - Waveshare 7.9" HDMI Config
# Basierend auf: https://www.waveshare.com/wiki/7.9inch_Touch_Monitor
# Resolution: 400×1280 (Hardware), 1280×400 (Landscape)
# HiFiBerry AMP100 integriert
#########################################

[cm4]
otg_mode=1

[pi5]
# Pi 5 spezifisches KMS Overlay (WICHTIG: vc4-kms-v3d-pi5, nicht generisch!)
dtoverlay=vc4-kms-v3d-pi5,noaudio
hdmi_enable_4kp60=0

[all]
# Basis-KMS (True KMS)
dtoverlay=vc4-kms-v3d

# Waveshare 7.9" HDMI Display - OFFIZIELLE WAVESHARE TIMINGS
# Quelle: https://www.waveshare.com/wiki/7.9inch_Touch_Monitor
hdmi_group=2
hdmi_mode=87
hdmi_timings=400 0 220 32 110 1280 0 10 10 10 0 0 0 60 0 59510000 0

# HDMI aktivieren
hdmi_ignore_hotplug=0
display_auto_detect=1
hdmi_force_hotplug=1
hdmi_blanking=0
hdmi_drive=2

# Display Rotation (0 = Landscape, 1 = 90°, 2 = 180°, 3 = 270°)
display_rotate=0

# Framebuffer aktivieren
fbcon=map=1

# Firmware-KMS aktivieren (WICHTIG!)
disable_fw_kms_setup=0

# I2C aktivieren (für Touchscreen)
dtparam=i2c_arm=on
dtparam=i2c_arm_baudrate=100000
dtparam=i2c_vc=on

# Audio - HiFiBerry AMP100
# Audio über I2S, HDMI Audio deaktiviert (noaudio im pi5 Overlay)
dtparam=audio=off
dtparam=i2s=on

# HiFiBerry AMP100 Overlay
dtoverlay=hifiberry-amp100

# Allgemeine Einstellungen
arm_64bit=1
arm_boost=1
disable_splash=0
disable_overscan=1

# Power Management
WAKE_ON_GPIO=1
POWER_OFF_ON_HALT=0
CONFIG_EOF

# Permissions setzen
sudo chmod 644 /boot/firmware/config.txt

# SSH für nächsten Boot aktivieren
sudo touch /boot/firmware/ssh
sudo systemctl enable ssh
sudo systemctl start ssh

# Sync
sync

echo "✅ Config angewendet!"
echo "✅ SSH aktiviert!"
echo ""
echo "⚠️  Reboot erforderlich!"
echo "   sudo reboot"

