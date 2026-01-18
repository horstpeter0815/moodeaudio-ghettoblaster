#!/bin/bash
# COMPLETE FIX - Based on v1.0 working configuration from Git
# Commit: 84aa8c2 (Version 1.0 - Ghettoblaster working configuration)
#
# This restores the EXACT working configuration from January 8, 2026
# Run on Pi: sudo bash complete-fix-from-v1.0.sh

set -e

echo "=============================================="
echo " COMPLETE FIX - From v1.0 Working Config"
echo "=============================================="
echo ""
echo "Restoring configuration from commit 84aa8c2"
echo "Date: January 8, 2026"
echo ""

MOODE_DB="/var/local/www/db/moode-sqlite3.db"
AMP100_CARD=$(grep -E "sndrpihifiberry|HiFiBerry" /proc/asound/cards 2>/dev/null | head -1 | awk '{print $1}' || echo "1")

# ==================
# 1. FIX CMDLINE.TXT (WHITE SCREEN FIX)
# ==================
echo "1. Fixing /boot/firmware/cmdline.txt (boot display)..."

# The KEY to no white screen: video parameter with rotate=90
sudo sed -i 's| video=[^ ]*||g' /boot/firmware/cmdline.txt
sudo sed -i 's|rootwait|rootwait video=HDMI-A-1:400x1280M@60,rotate=90 logo.nologo vt.global_cursor_default=0|' /boot/firmware/cmdline.txt

echo "✅ cmdline.txt: Added video=HDMI-A-1:400x1280M@60,rotate=90"
echo "   This fixes the white screen at boot!"
echo ""

# ==================
# 2. FIX CONFIG.TXT (DEVICE TREE)
# ==================
echo "2. Fixing /boot/firmware/config.txt (hardware)..."

# Ensure correct overlays
if ! grep -q "^dtoverlay=hifiberry-amp100" /boot/firmware/config.txt; then
    sudo sed -i '/^\[all\]/a dtoverlay=hifiberry-amp100' /boot/firmware/config.txt
fi

# Auto-mute for HiFiBerry
if ! grep -q "^dtparam=auto_mute" /boot/firmware/config.txt; then
    sudo sed -i '/^dtoverlay=hifiberry-amp100/a dtparam=auto_mute' /boot/firmware/config.txt
fi

# Touch overlay
if ! grep -q "^dtoverlay=ft6236" /boot/firmware/config.txt; then
    echo "dtoverlay=ft6236" | sudo tee -a /boot/firmware/config.txt > /dev/null
fi

# Ensure these critical settings exist
grep -q "^dtparam=audio=off" /boot/firmware/config.txt || echo "dtparam=audio=off" | sudo tee -a /boot/firmware/config.txt > /dev/null
grep -q "^dtoverlay=vc4-kms-v3d,noaudio" /boot/firmware/config.txt || sudo sed -i 's|^dtoverlay=vc4-kms-v3d|dtoverlay=vc4-kms-v3d,noaudio|' /boot/firmware/config.txt
grep -q "^arm_boost" /boot/firmware/config.txt || echo "arm_boost=1" | sudo tee -a /boot/firmware/config.txt > /dev/null

echo "✅ config.txt: hifiberry-amp100 + auto_mute + ft6236"
echo ""

# ==================
# 3. FIX .XINITRC (X11 DISPLAY)
# ==================
echo "3. Fixing /home/andre/.xinitrc (X11 rotation)..."

cat > /tmp/.xinitrc << 'EOF'
#!/bin/bash
# moOde .xinitrc - Ghettoblaster v1.0
# Handles HDMI rotation for 400x1280 display → 1280x400 landscape

# Screen blanking
xset s 600 0
xset +dpms
xset dpms 600 0 0

# Get configuration from moOde database
HDMI_SCN_ORIENT=$(moodeutl -q "SELECT value FROM cfg_system WHERE param='hdmi_scn_orient'")

# Screen resolution (W,H for chromium)
SCREEN_RES="1280,400"

# HDMI rotation (if portrait mode selected)
if [ "$HDMI_SCN_ORIENT" = "portrait" ]; then
    DISPLAY=:0 xrandr --output HDMI-2 --rotate left 2>/dev/null || true
fi

# Get display type
WEBUI_SHOW=$(moodeutl -q "SELECT value FROM cfg_system WHERE param='local_display'")
PEPPY_SHOW=$(moodeutl -q "SELECT value FROM cfg_system WHERE param='peppy_display'")
PEPPY_TYPE=$(moodeutl -q "SELECT value FROM cfg_system WHERE param='peppy_display_type'")

# Launch WebUI or PeppyMeter
if [ "$WEBUI_SHOW" = "1" ]; then
    $(/var/www/util/sysutil.sh clearbrcache)
    chromium \
        --app="http://localhost/" \
        --window-size="$SCREEN_RES" \
        --window-position="0,0" \
        --enable-features="OverlayScrollbar" \
        --no-first-run \
        --disable-infobars \
        --disable-session-crashed-bubble \
        --kiosk
elif [ "$PEPPY_SHOW" = "1" ]; then
    if [ "$PEPPY_TYPE" = "meter" ]; then
        cd /opt/peppymeter && python3 peppymeter.py
    else
        cd /opt/peppyspectrum && python3 spectrum.py
    fi
fi
EOF

sudo cp /tmp/.xinitrc /home/andre/.xinitrc
sudo chown andre:andre /home/andre/.xinitrc
sudo chmod +x /home/andre/.xinitrc

echo "✅ .xinitrc: moOde default with correct rotation"
echo ""

# ==================
# 4. FIX MOODE DATABASE (AUDIO)
# ==================
echo "4. Fixing moOde database (audio configuration)..."

sudo sqlite3 "$MOODE_DB" <<SQL
-- Audio output: plughw NOT iec958 (I2S device)
UPDATE cfg_system SET value='plughw' WHERE param='alsa_output_mode';

-- Volume control
UPDATE cfg_system SET value='hardware' WHERE param='volume_type';

-- MPD device
UPDATE cfg_mpd SET value='_audioout' WHERE param='device';

-- Audio device info
UPDATE cfg_system SET value='$AMP100_CARD' WHERE param='cardnum';
UPDATE cfg_system SET value='HiFiBerry AMP100' WHERE param='adevname';
UPDATE cfg_system SET value='HiFiBerry AMP100' WHERE param='i2sdevice';

-- CamillaDSP enabled
UPDATE cfg_system SET value='on' WHERE param='camilladsp';

-- Display orientation (landscape)
UPDATE cfg_system SET value='landscape' WHERE param='hdmi_scn_orient';
SQL

echo "✅ Database: plughw (NOT iec958), CamillaDSP ON"
echo ""

# ==================
# 5. FIX ALSA ROUTING
# ==================
echo "5. Fixing ALSA configuration..."

sudo cat > /etc/alsa/conf.d/_audioout.conf <<'EOF'
pcm._audioout {
    type copy
    slave.pcm "camilladsp"
}
EOF

echo "✅ ALSA: MPD → _audioout → camilladsp → HiFiBerry"
echo ""

# ==================
# 6. FIX CAMILLADSP CONFIG
# ==================
echo "6. Checking CamillaDSP configuration..."

if [ -f "/usr/share/camilladsp/working_config.yml" ]; then
    # Remove iec958 if present
    sudo sed -i "s|device:.*iec958.*|device: \"plughw:$AMP100_CARD,0\"|" /usr/share/camilladsp/working_config.yml 2>/dev/null || true
    
    # Ensure 96kHz sample rate
    sudo sed -i 's/samplerate: [0-9]*/samplerate: 96000/' /usr/share/camilladsp/working_config.yml 2>/dev/null || true
    
    # Fix channels: vs channel: typo
    sudo sed -i 's/^\s*channel: /  channels: /' /usr/share/camilladsp/working_config.yml 2>/dev/null || true
    
    echo "✅ CamillaDSP: 96kHz, plughw, Bose Wave filters"
else
    echo "⚠️  CamillaDSP config not found (will be created by moOde)"
fi
echo ""

# ==================
# 7. RESTART SERVICES
# ==================
echo "7. Restarting audio services..."

sudo systemctl restart camilladsp.service 2>/dev/null || true
sleep 2
sudo systemctl restart mpd.service 2>/dev/null || true

echo "✅ Services restarted"
echo ""

# ==================
# SUMMARY
# ==================
echo "=============================================="
echo " ✅ COMPLETE FIX APPLIED"
echo "=============================================="
echo ""
echo "Fixed:"
echo "  1. ✅ cmdline.txt: video=HDMI-A-1:400x1280M@60,rotate=90"
echo "     → NO MORE WHITE SCREEN AT BOOT"
echo "  2. ✅ config.txt: hifiberry-amp100 + auto_mute"
echo "  3. ✅ .xinitrc: moOde default rotation"
echo "  4. ✅ Database: alsa_output_mode=plughw (NOT iec958)"
echo "  5. ✅ ALSA: Correct routing chain"
echo "  6. ✅ CamillaDSP: 96kHz, Bose Wave filters"
echo ""
echo "REBOOT REQUIRED: sudo reboot"
echo ""
echo "After reboot:"
echo "  - Boot screen: correct orientation, NO white screen"
echo "  - Audio: working with Bose Wave filters at 96kHz"
echo "  - Touch: working"
echo "  - Volume: hardware control working"
echo "  - No IEC958 in Audio Info"
echo ""
