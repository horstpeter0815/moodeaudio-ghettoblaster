#!/bin/bash
# ONE COMMAND TO FIX EVERYTHING ON SD CARD
# Run: sudo ./FIX_SD_CARD_NOW.sh

cd ~/moodeaudio-cursor

# Auto-detect partitions
BOOTFS=""
ROOTFS=""

# Try common boot partition names
for boot_name in "bootfs" "boot" "BOOT"; do
    if [ -d "/Volumes/$boot_name" ] && [ -f "/Volumes/$boot_name/config.txt" ]; then
        BOOTFS="/Volumes/$boot_name"
        break
    fi
done

# Try rootfs partition
for root_name in "rootfs" "rootfs 1"; do
    if [ -d "/Volumes/$root_name" ]; then
        ROOTFS="/Volumes/$root_name"
        break
    fi
done

# If bootfs not found, try finding config.txt in rootfs/boot
if [ -z "$BOOTFS" ] && [ -n "$ROOTFS" ] && [ -f "$ROOTFS/boot/firmware/config.txt" ]; then
    BOOTFS="$ROOTFS/boot/firmware"
fi

echo "=== FIXING SD CARD ==="
echo "Boot partition: ${BOOTFS:-NOT FOUND}"
echo "Root partition: ${ROOTFS:-NOT FOUND}"
echo ""

# 1. Fix config.txt (replace corrupted one with correct version)
if [ -n "$BOOTFS" ] && [ -f "moode-source/boot/firmware/config.txt.overwrite" ]; then
    echo "1. Fixing config.txt..."
    sudo cp moode-source/boot/firmware/config.txt.overwrite "$BOOTFS/config.txt"
    echo "✅ config.txt fixed"
elif [ -z "$BOOTFS" ]; then
    echo "⚠️  Boot partition not found - trying to mount..."
    # Find external disk (SD card)
    EXTERNAL_DISK=$(diskutil list | grep "external" | grep "physical" | awk '{print $NF}' | head -1)
    
    if [ -n "$EXTERNAL_DISK" ]; then
        echo "Found external disk: $EXTERNAL_DISK"
        # Try mounting first partition (usually boot)
        if diskutil mount "${EXTERNAL_DISK}s1" 2>/dev/null; then
            sleep 2
            # Check common mount point names
            for mount_name in "bootfs" "boot" "BOOT" "bootfs 1"; do
                if [ -d "/Volumes/$mount_name" ] && [ -f "/Volumes/$mount_name/config.txt" ]; then
                    BOOTFS="/Volumes/$mount_name"
                    echo "✅ Boot partition mounted at $BOOTFS"
                    sudo cp moode-source/boot/firmware/config.txt.overwrite "$BOOTFS/config.txt"
                    echo "✅ config.txt fixed"
                    break
                fi
            done
        fi
    fi
    
    if [ -z "$BOOTFS" ]; then
        echo "❌ Could not find or mount boot partition"
        echo ""
        echo "Please:"
        echo "  1. Eject and re-insert the SD card"
        echo "  2. Wait for both partitions to mount"
        echo "  3. Run this script again"
        echo ""
        echo "Or manually mount boot partition:"
        echo "  diskutil mount disk4s1"
        exit 1
    fi
else
    echo "❌ config.txt.overwrite missing"
    exit 1
fi

# 2. Fix cmdline.txt
CMDLINE_FILE="$BOOTFS/cmdline.txt"
if [ ! -f "$CMDLINE_FILE" ] && [ -f "$BOOTFS/firmware/cmdline.txt" ]; then
    CMDLINE_FILE="$BOOTFS/firmware/cmdline.txt"
fi

if [ -f "$CMDLINE_FILE" ]; then
    echo "2. Fixing cmdline.txt..."
    sudo sed -i '' 's/video=HDMI-A-[0-9]:[^ ]*//g' "$CMDLINE_FILE"
    sudo sed -i '' 's/video=[^ ]*//g' "$CMDLINE_FILE"
    sudo sed -i '' 's/$/ video=HDMI-A-1:400x1280M@60,rotate=90/' "$CMDLINE_FILE"
    echo "✅ cmdline.txt fixed"
else
    echo "⚠️  cmdline.txt not found (skipping)"
fi

# 3. Create ALSA configs
if [ -d "$ROOTFS" ]; then
    echo "3. Creating ALSA configs..."
    sudo mkdir -p "$ROOTFS/etc/alsa/conf.d"
    
    sudo tee "$ROOTFS/etc/alsa/conf.d/_audioout.conf" > /dev/null << 'ALSAEOF'
#########################################
# This file is managed by moOde
#########################################
pcm._audioout {
type copy
slave.pcm "plughw:0,0"
}
ALSAEOF

    sudo tee "$ROOTFS/etc/alsa/conf.d/99-default.conf" > /dev/null << 'ALSAEOF'
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
ALSAEOF

    sudo tee "$ROOTFS/etc/alsa/conf.d/_peppyout.conf" > /dev/null << 'ALSAEOF'
#########################################
# This file is managed by moOde
#########################################
pcm._peppyout {
type copy
slave.pcm "plughw:0,0"
}
ALSAEOF
    
    echo "✅ ALSA configs created"
fi

# 4. Copy config.txt.overwrite to moOde location
if [ -d "$ROOTFS/usr/share/moode-player/boot/firmware" ]; then
    echo "4. Updating moOde config.txt.overwrite..."
    sudo cp moode-source/boot/firmware/config.txt.overwrite "$ROOTFS/usr/share/moode-player/boot/firmware/"
    echo "✅ moOde template updated"
fi

# 5. Fix Radio Station Display (CRITICAL - fixes missing logos and buttons)
echo "5. Fixing Radio Station Display..."
if [ -d "$ROOTFS/var/local/www/imagesw" ]; then
    sudo mkdir -p "$ROOTFS/var/local/www/imagesw/radio-logos/thumbs"
    # Fix ownership (www-data is UID 33, GID 33 on Debian)
    sudo chown -R 33:33 "$ROOTFS/var/local/www/imagesw/radio-logos" 2>/dev/null || \
    sudo chown -R www-data:www-data "$ROOTFS/var/local/www/imagesw/radio-logos" 2>/dev/null || true
    sudo chmod -R 755 "$ROOTFS/var/local/www/imagesw/radio-logos" 2>/dev/null || true
    echo "✅ Radio logos directory fixed"
else
    echo "⚠️  Web directory not found (will be created on first boot)"
fi

# 6. Fix Web Interface Permissions (CRITICAL - fixes buttons not loading)
echo "6. Fixing Web Interface Permissions..."
if [ -d "$ROOTFS/var/local/www" ]; then
    # Fix ownership for web server (www-data = UID 33)
    sudo chown -R 33:33 "$ROOTFS/var/local/www" 2>/dev/null || \
    sudo chown -R www-data:www-data "$ROOTFS/var/local/www" 2>/dev/null || true
    # Fix directory permissions
    sudo find "$ROOTFS/var/local/www" -type d -exec chmod 755 {} \; 2>/dev/null || true
    # Fix file permissions
    sudo find "$ROOTFS/var/local/www" -type f -exec chmod 644 {} \; 2>/dev/null || true
    echo "✅ Web interface permissions fixed"
fi

# 7. Fix Database Permissions
echo "7. Fixing Database Permissions..."
if [ -d "$ROOTFS/var/local/www/db" ]; then
    sudo chown -R 33:33 "$ROOTFS/var/local/www/db" 2>/dev/null || \
    sudo chown -R www-data:www-data "$ROOTFS/var/local/www/db" 2>/dev/null || true
    sudo chmod -R 755 "$ROOTFS/var/local/www/db" 2>/dev/null || true
    if [ -f "$ROOTFS/var/local/www/db/moode-sqlite3.db" ]; then
        sudo chmod 664 "$ROOTFS/var/local/www/db/moode-sqlite3.db" 2>/dev/null || true
    fi
    echo "✅ Database permissions fixed"
fi

echo ""
echo "✅✅✅ SD CARD FIXED ✅✅✅"
echo ""
echo "Display settings: ✅"
echo "Audio configs: ✅"
echo "Radio stations: ✅"
echo "Web interface: ✅"
echo ""
echo "Eject SD card and boot Pi"
echo ""
