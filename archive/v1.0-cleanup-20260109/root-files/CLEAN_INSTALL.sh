#!/bin/bash
# CLEAN INSTALL - Just set correct parameters, no workarounds
# Run: sudo ./CLEAN_INSTALL.sh

cd ~/moodeaudio-cursor

ROOTFS="/Volumes/rootfs"
BOOTFS="/Volumes/bootfs"

echo "=== CLEAN INSTALL - Setting Correct Parameters ==="
echo ""

# 1. Set config.txt correctly (display works from boot)
echo "1. Setting config.txt..."
if [ -d "$BOOTFS" ] && [ -f "moode-source/boot/firmware/config.txt.overwrite" ]; then
    sudo cp moode-source/boot/firmware/config.txt.overwrite "$BOOTFS/config.txt"
    echo "✅ config.txt set correctly"
else
    echo "❌ Boot partition or config.txt.overwrite not found"
    exit 1
fi

# 2. Set cmdline.txt correctly
echo "2. Setting cmdline.txt..."
if [ -f "$BOOTFS/cmdline.txt" ]; then
    # Remove any existing video parameters
    sudo sed -i '' 's/video=HDMI-A-[0-9]:[^ ]*//g' "$BOOTFS/cmdline.txt"
    sudo sed -i '' 's/video=[^ ]*//g' "$BOOTFS/cmdline.txt"
    # Add correct video parameter
    sudo sed -i '' 's/$/ video=HDMI-A-1:400x1280M@60,rotate=90/' "$BOOTFS/cmdline.txt"
    echo "✅ cmdline.txt set correctly"
fi

# 3. Create ALSA configs correctly (audio works immediately)
echo "3. Creating ALSA configs..."
sudo mkdir -p "$ROOTFS/etc/alsa/conf.d"

sudo tee "$ROOTFS/etc/alsa/conf.d/_audioout.conf" > /dev/null << 'EOF'
#########################################
# This file is managed by moOde
#########################################
pcm._audioout {
type copy
slave.pcm "plughw:0,0"
}
EOF

sudo tee "$ROOTFS/etc/alsa/conf.d/99-default.conf" > /dev/null << 'EOF'
#########################################
# ALSA default device - points to moOde _audioout
#########################################
pcm.!default {
    type plug
    slave.pcm "_audioout"
}

ctl.!default {
    type hw
    card 0
}
EOF

sudo tee "$ROOTFS/etc/alsa/conf.d/_peppyout.conf" > /dev/null << 'EOF'
#########################################
# This file is managed by moOde
#########################################
pcm._peppyout {
type copy
slave.pcm "plughw:0,0"
}
EOF

echo "✅ ALSA configs created"

# 4. Set permissions correctly (web interface works)
echo "4. Setting permissions..."
sudo mkdir -p "$ROOTFS/var/local/www/imagesw/radio-logos/thumbs"
sudo chown -R 33:33 "$ROOTFS/var/local/www" 2>/dev/null || sudo chown -R www-data:www-data "$ROOTFS/var/local/www" 2>/dev/null || true
sudo find "$ROOTFS/var/local/www" -type d -exec chmod 755 {} \; 2>/dev/null || true
sudo find "$ROOTFS/var/local/www" -type f -exec chmod 644 {} \; 2>/dev/null || true
echo "✅ Permissions set correctly"

# 5. Update moOde template (for future restores)
echo "5. Updating moOde template..."
if [ -d "$ROOTFS/usr/share/moode-player/boot/firmware" ]; then
    sudo cp moode-source/boot/firmware/config.txt.overwrite "$ROOTFS/usr/share/moode-player/boot/firmware/"
    echo "✅ moOde template updated"
fi

# 6. REMOVE workaround services (clean system)
echo "6. Removing workaround services..."
sudo rm -f "$ROOTFS/lib/systemd/system/persist-display-config.service" 2>/dev/null || true
sudo rm -f "$ROOTFS/lib/systemd/system/fix-audio-chain.service" 2>/dev/null || true
sudo rm -f "$ROOTFS/etc/systemd/system/multi-user.target.wants/persist-display-config.service" 2>/dev/null || true
sudo rm -f "$ROOTFS/etc/systemd/system/multi-user.target.wants/fix-audio-chain.service" 2>/dev/null || true
echo "✅ Workaround services removed"

echo ""
echo "✅✅✅ CLEAN INSTALL COMPLETE ✅✅✅"
echo ""
echo "Configuration set correctly:"
echo "  ✅ config.txt - Display settings correct"
echo "  ✅ cmdline.txt - HDMI port correct"
echo "  ✅ ALSA configs - Audio chain correct"
echo "  ✅ Permissions - Web interface correct"
echo ""
echo "No workarounds, no services, just correct parameters."
echo ""
echo "Eject SD card and boot Pi"
echo ""
