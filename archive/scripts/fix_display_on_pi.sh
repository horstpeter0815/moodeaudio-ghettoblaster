#!/bin/bash
# DISPLAY FIX - Direkt auf dem Pi ausführen
# Kopiere dieses Script auf den Pi und führe es aus

set -e
export DISPLAY=:0

echo "=== MOODE AUDIO DISPLAY FIX ==="
echo ""

# Backup
echo "1. Backup..."
sudo cp /boot/firmware/config.txt /boot/firmware/config.txt.backup.$(date +%Y%m%d_%H%M%S)
sudo cp /boot/firmware/cmdline.txt /boot/firmware/cmdline.txt.backup.$(date +%Y%m%d_%H%M%S)
[ -f /home/andre/.xinitrc ] && cp /home/andre/.xinitrc /home/andre/.xinitrc.backup.$(date +%Y%m%d_%H%M%S)
echo "✅ Backup erstellt"
echo ""

# config.txt
echo "2. Setze config.txt..."
sudo tee /boot/firmware/config.txt > /dev/null << 'CONFIG_EOF'
# Moode Audio - Pi 5 - Final Display Configuration
# Waveshare 7.9" HDMI - 1280x400 Landscape

[all]
disable_fw_kms_setup=1

[pi5]
display_rotate=0
hdmi_force_hotplug=1
hdmi_ignore_edid=0xa5000080
hdmi_group=2
hdmi_mode=87
disable_overscan=1
framebuffer_width=1280
framebuffer_height=400
CONFIG_EOF
echo "✅ config.txt gesetzt"
echo ""

# cmdline.txt
echo "3. Setze cmdline.txt..."
sudo sed -i 's/video=[^ ]*//g' /boot/firmware/cmdline.txt
sudo sed -i 's/$/ video=HDMI-A-2:1280x400M@60/' /boot/firmware/cmdline.txt
echo "✅ cmdline.txt gesetzt"
echo ""

# xinitrc
echo "4. Setze xinitrc..."
cat > /home/andre/.xinitrc << 'XINITRC_EOF'
#!/bin/sh
export DISPLAY=:0
sleep 2

for i in 1 2 3 4 5; do
    if xrandr --output HDMI-A-2 --query 2>/dev/null | grep -q "connected"; then
        break
    fi
    sleep 1
done

xrandr --output HDMI-A-2 --mode 1280x400 2>/dev/null || \
xrandr --output HDMI-A-2 --mode 400x1280 --rotate right 2>/dev/null || \
xrandr --output HDMI-A-2 --auto 2>/dev/null

xrandr --fb 1280x400 2>/dev/null || true

exec chromium-browser \
    --kiosk \
    --noerrdialogs \
    --disable-infobars \
    --disable-session-crashed-bubble \
    --disable-restore-session-state \
    --window-size=1280,400 \
    --start-fullscreen \
    http://localhost
XINITRC_EOF
chmod +x /home/andre/.xinitrc
echo "✅ xinitrc gesetzt"
echo ""

# Touchscreen
echo "5. Setze Touchscreen-Config..."
sudo mkdir -p /etc/X11/xorg.conf.d
sudo tee /etc/X11/xorg.conf.d/99-touchscreen.conf > /dev/null << 'TOUCH_EOF'
Section "InputClass"
    Identifier "WaveShare Touchscreen"
    MatchUSBID "0712:000a"
    MatchIsTouchscreen "on"
    Driver "libinput"
    Option "TransformationMatrix" "1 0 0 0 1 0 0 0 1"
EndSection
TOUCH_EOF
echo "✅ Touchscreen-Config gesetzt"
echo ""

echo "=== FERTIG ==="
echo ""
echo "Reboot erforderlich:"
echo "  sudo reboot"
echo ""

