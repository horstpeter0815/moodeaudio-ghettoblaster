#!/bin/bash
# Fix display on SD card

if [ ! -d "/Volumes/rootfs" ]; then
    echo "❌ SD card not mounted"
    exit 1
fi

sudo bash << 'SUDO'
# Copy fix-display script
cp /Users/andrevollmer/moodeaudio-cursor/temp/fix-display.sh /Volumes/rootfs/usr/local/bin/
chmod +x /Volumes/rootfs/usr/local/bin/fix-display.sh

# Create config.txt if missing
if [ ! -f /Volumes/rootfs/boot/firmware/config.txt ]; then
    echo "# moOde config.txt" > /Volumes/rootfs/boot/firmware/config.txt
fi

# Add display_rotate=0
sed -i '' '/^display_rotate=/d' /Volumes/rootfs/boot/firmware/config.txt 2>/dev/null || true
echo "display_rotate=0" >> /Volumes/rootfs/boot/firmware/config.txt

# Copy worker.php patch if exists
if [ -f /Users/andrevollmer/moodeaudio-cursor/moode-source/usr/local/bin/worker-php-patch.sh ]; then
    mkdir -p /Volumes/rootfs/usr/local/bin
    cp /Users/andrevollmer/moodeaudio-cursor/moode-source/usr/local/bin/worker-php-patch.sh /Volumes/rootfs/usr/local/bin/
    chmod +x /Volumes/rootfs/usr/local/bin/worker-php-patch.sh
fi

echo "✅ Display fix applied"
SUDO
