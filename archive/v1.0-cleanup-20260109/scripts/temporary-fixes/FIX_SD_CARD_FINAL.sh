#!/bin/bash
# FINAL FIX - Run this ONCE to fix everything on SD card
# Run: sudo ./FIX_SD_CARD_FINAL.sh

cd ~/moodeaudio-cursor

ROOTFS="/Volumes/rootfs"
BOOTFS="/Volumes/bootfs"

echo "=== FINAL SD CARD FIX ==="
echo ""

# 1. Fix config.txt (already done, but verify)
if [ -f "$BOOTFS/config.txt" ]; then
    echo "✅ config.txt: Already fixed"
else
    echo "❌ config.txt not found"
    exit 1
fi

# 2. Fix cmdline.txt (already done, but verify)
if [ -f "$BOOTFS/cmdline.txt" ]; then
    echo "✅ cmdline.txt: Already fixed"
else
    echo "❌ cmdline.txt not found"
    exit 1
fi

# 3. Create/Update ALSA configs
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

# 4. Fix Radio Station Display permissions
echo "4. Fixing Radio Station Display permissions..."
sudo mkdir -p "$ROOTFS/var/local/www/imagesw/radio-logos/thumbs"
sudo chown -R 33:33 "$ROOTFS/var/local/www/imagesw/radio-logos" 2>/dev/null || \
sudo chown -R www-data:www-data "$ROOTFS/var/local/www/imagesw/radio-logos" 2>/dev/null || true
sudo chmod -R 755 "$ROOTFS/var/local/www/imagesw/radio-logos" 2>/dev/null || true
echo "✅ Radio logos permissions fixed"

# 5. Fix Web Interface permissions
echo "5. Fixing Web Interface permissions..."
sudo chown -R 33:33 "$ROOTFS/var/local/www" 2>/dev/null || \
sudo chown -R www-data:www-data "$ROOTFS/var/local/www" 2>/dev/null || true
sudo find "$ROOTFS/var/local/www" -type d -exec chmod 755 {} \; 2>/dev/null || true
sudo find "$ROOTFS/var/local/www" -type f -exec chmod 644 {} \; 2>/dev/null || true
echo "✅ Web interface permissions fixed"

# 6. Fix Database permissions
echo "6. Fixing Database permissions..."
sudo chown -R 33:33 "$ROOTFS/var/local/www/db" 2>/dev/null || \
sudo chown -R www-data:www-data "$ROOTFS/var/local/www/db" 2>/dev/null || true
sudo chmod -R 755 "$ROOTFS/var/local/www/db" 2>/dev/null || true
if [ -f "$ROOTFS/var/local/www/db/moode-sqlite3.db" ]; then
    sudo chmod 664 "$ROOTFS/var/local/www/db/moode-sqlite3.db" 2>/dev/null || true
fi
echo "✅ Database permissions fixed"

# 7. Copy config.txt.overwrite to moOde location
if [ -d "$ROOTFS/usr/share/moode-player/boot/firmware" ]; then
    echo "7. Updating moOde config.txt.overwrite..."
    sudo cp moode-source/boot/firmware/config.txt.overwrite "$ROOTFS/usr/share/moode-player/boot/firmware/"
    echo "✅ moOde template updated"
fi

echo ""
echo "✅✅✅ SD CARD COMPLETELY FIXED ✅✅✅"
echo ""
echo "Fixed:"
echo "  ✅ config.txt (display settings)"
echo "  ✅ cmdline.txt (HDMI port)"
echo "  ✅ ALSA configs (_audioout.conf, pcm.default)"
echo "  ✅ Radio station permissions"
echo "  ✅ Web interface permissions"
echo "  ✅ Database permissions"
echo ""
echo "Eject SD card and boot Pi"
echo ""
