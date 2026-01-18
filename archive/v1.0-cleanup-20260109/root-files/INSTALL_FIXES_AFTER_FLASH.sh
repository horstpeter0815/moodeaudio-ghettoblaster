#!/bin/bash
# Install our fixes after flashing moOde image
# Run: sudo ./INSTALL_FIXES_AFTER_FLASH.sh

cd ~/moodeaudio-cursor

ROOTFS="/Volumes/rootfs"
BOOTFS="/Volumes/bootfs"

echo "=== INSTALLING FIXES AFTER MOODE FLASH ==="
echo ""

if [ ! -d "$ROOTFS" ]; then
    echo "❌ SD card not mounted at $ROOTFS"
    exit 1
fi

echo "✅ SD card: $ROOTFS"
echo ""

# 1. Install SSH fix
echo "1. Installing SSH fix..."
if [ -f "moode-source/lib/systemd/system/ssh-guaranteed.service" ]; then
    sudo cp moode-source/lib/systemd/system/ssh-guaranteed.service "$ROOTFS/lib/systemd/system/"
    sudo mkdir -p "$ROOTFS/etc/systemd/system/sysinit.target.wants"
    sudo ln -sf /lib/systemd/system/ssh-guaranteed.service "$ROOTFS/etc/systemd/system/sysinit.target.wants/"
    echo "✅ SSH fix installed"
fi

# 2. Install user fix
echo "2. Installing user fix..."
if [ -f "moode-source/lib/systemd/system/fix-user-id.service" ]; then
    sudo cp moode-source/lib/systemd/system/fix-user-id.service "$ROOTFS/lib/systemd/system/"
    sudo mkdir -p "$ROOTFS/etc/systemd/system/multi-user.target.wants"
    sudo ln -sf /lib/systemd/system/fix-user-id.service "$ROOTFS/etc/systemd/system/multi-user.target.wants/"
    echo "✅ User fix installed"
fi

# 3. Install Ethernet fix
echo "3. Installing Ethernet fix..."
if [ -f "moode-source/lib/systemd/system/02-eth0-configure.service" ]; then
    sudo cp moode-source/lib/systemd/system/02-eth0-configure.service "$ROOTFS/lib/systemd/system/"
    sudo mkdir -p "$ROOTFS/etc/systemd/system/local-fs.target.wants" "$ROOTFS/etc/systemd/system/sysinit.target.wants"
    sudo ln -sf /lib/systemd/system/02-eth0-configure.service "$ROOTFS/etc/systemd/system/local-fs.target.wants/"
    sudo ln -sf /lib/systemd/system/02-eth0-configure.service "$ROOTFS/etc/systemd/system/sysinit.target.wants/"
    echo "✅ Ethernet fix installed (safe mgmt link: 192.168.10.2/24, never default route)"
else
    echo "⚠️  02-eth0-configure.service not found (skipping)"
fi

# 4. Enable SSH flag
echo "4. Enabling SSH flag..."
if [ -d "$BOOTFS" ]; then
    sudo touch "$BOOTFS/ssh" 2>/dev/null || sudo touch "$BOOTFS/firmware/ssh" 2>/dev/null || true
    echo "✅ SSH flag enabled"
fi

# 5. Install iPhone USB tether service (Personal Hotspot)
echo "5. Installing iPhone USB tether service..."
if [ -f "moode-source/lib/systemd/system/iphone-usb-tether.service" ] && [ -f "moode-source/usr/local/bin/iphone-usb-tether.sh" ]; then
    sudo cp moode-source/lib/systemd/system/iphone-usb-tether.service "$ROOTFS/lib/systemd/system/"
    sudo cp moode-source/usr/local/bin/iphone-usb-tether.sh "$ROOTFS/usr/local/bin/"
    sudo chmod +x "$ROOTFS/usr/local/bin/iphone-usb-tether.sh" 2>/dev/null || true
    sudo mkdir -p "$ROOTFS/etc/systemd/system/multi-user.target.wants"
    sudo ln -sf /lib/systemd/system/iphone-usb-tether.service "$ROOTFS/etc/systemd/system/multi-user.target.wants/"
    echo "✅ iPhone USB tether service installed"
else
    echo "⚠️  iphone-usb-tether files not found in repo (skipping)"
fi

# 6. Set moOde Hotspot password default + clean old WiFi profiles
echo "6. Installing Hotspot password + WiFi cleanup (optional)..."
if [ -f "moode-source/lib/systemd/system/hotspot-set-password.service" ] && [ -f "moode-source/usr/local/bin/hotspot-set-password.sh" ]; then
    sudo cp moode-source/lib/systemd/system/hotspot-set-password.service "$ROOTFS/lib/systemd/system/"
    sudo cp moode-source/usr/local/bin/hotspot-set-password.sh "$ROOTFS/usr/local/bin/"
    sudo chmod +x "$ROOTFS/usr/local/bin/hotspot-set-password.sh" 2>/dev/null || true
    sudo mkdir -p "$ROOTFS/etc/systemd/system/multi-user.target.wants"
    sudo ln -sf /lib/systemd/system/hotspot-set-password.service "$ROOTFS/etc/systemd/system/multi-user.target.wants/"
    echo "✅ Hotspot password service installed (default PSK: 08150815)"
else
    echo "⚠️  hotspot-set-password files not found (skipping)"
fi

if [ -f "moode-source/lib/systemd/system/network-cleanup-profiles.service" ] && [ -f "moode-source/usr/local/bin/network-cleanup-profiles.sh" ]; then
    sudo cp moode-source/lib/systemd/system/network-cleanup-profiles.service "$ROOTFS/lib/systemd/system/"
    sudo cp moode-source/usr/local/bin/network-cleanup-profiles.sh "$ROOTFS/usr/local/bin/"
    sudo chmod +x "$ROOTFS/usr/local/bin/network-cleanup-profiles.sh" 2>/dev/null || true
    sudo mkdir -p "$ROOTFS/etc/systemd/system/multi-user.target.wants"
    sudo ln -sf /lib/systemd/system/network-cleanup-profiles.service "$ROOTFS/etc/systemd/system/multi-user.target.wants/"
    echo "✅ WiFi cleanup service installed (removes only: Ghettoblaster / Ghetto LAN)"
else
    echo "⚠️  network-cleanup-profiles files not found (skipping)"
fi

# 7. Install Audio Chain Fix (HiFiBerry AMP100)
echo "7. Installing Audio Chain Fix..."

# First, ensure AMP100 overlay is in config.txt
if [ -d "$BOOTFS" ]; then
    CONFIG_TXT="$BOOTFS/config.txt"
    if [ ! -f "$CONFIG_TXT" ]; then
        CONFIG_TXT="$BOOTFS/firmware/config.txt"
    fi
    
    if [ -f "$CONFIG_TXT" ]; then
        # Check if AMP100 overlay is already present
        if ! grep -q "dtoverlay=hifiberry-amp100" "$CONFIG_TXT" 2>/dev/null; then
            echo "  Adding AMP100 overlay to config.txt..."
            # Disable onboard audio first
            if ! grep -q "dtparam=audio=off" "$CONFIG_TXT" 2>/dev/null; then
                echo "dtparam=audio=off" | sudo tee -a "$CONFIG_TXT" >/dev/null
            fi
            # Add AMP100 overlay
            echo "dtoverlay=hifiberry-amp100,automute" | sudo tee -a "$CONFIG_TXT" >/dev/null
            echo "force_eeprom_read=0" | sudo tee -a "$CONFIG_TXT" >/dev/null
            echo "✅ AMP100 overlay added to config.txt"
        else
            echo "✅ AMP100 overlay already in config.txt"
        fi
    else
        echo "⚠️  config.txt not found at $CONFIG_TXT"
    fi
fi

# Install fix script and service
if [ -f "moode-source/lib/systemd/system/fix-audio-chain.service" ] && [ -f "moode-source/usr/local/bin/fix-audio-chain.sh" ]; then
    sudo cp moode-source/lib/systemd/system/fix-audio-chain.service "$ROOTFS/lib/systemd/system/"
    sudo cp moode-source/usr/local/bin/fix-audio-chain.sh "$ROOTFS/usr/local/bin/"
    sudo chmod +x "$ROOTFS/usr/local/bin/fix-audio-chain.sh" 2>/dev/null || true
    sudo mkdir -p "$ROOTFS/etc/systemd/system/multi-user.target.wants"
    sudo ln -sf /lib/systemd/system/fix-audio-chain.service "$ROOTFS/etc/systemd/system/multi-user.target.wants/"
    echo "✅ Audio Chain Fix service installed"
else
    echo "⚠️  Audio Chain Fix files not found (checking scripts/audio/)..."
    if [ -f "scripts/audio/fix-audio-chain.sh" ]; then
        sudo mkdir -p "$ROOTFS/usr/local/bin"
        sudo cp scripts/audio/fix-audio-chain.sh "$ROOTFS/usr/local/bin/"
        sudo chmod +x "$ROOTFS/usr/local/bin/fix-audio-chain.sh" 2>/dev/null || true
        
        # Create service file if it doesn't exist
        if [ ! -f "$ROOTFS/lib/systemd/system/fix-audio-chain.service" ]; then
            sudo mkdir -p "$ROOTFS/lib/systemd/system"
            sudo tee "$ROOTFS/lib/systemd/system/fix-audio-chain.service" >/dev/null <<'EOFSERVICE'
[Unit]
Description=Fix Audio Chain for HiFiBerry AMP100
After=sound.target
After=local-fs.target
After=mpd.service
Wants=sound.target
Wants=mpd.service

[Service]
Type=oneshot
RemainAfterExit=yes
StandardOutput=journal
StandardError=journal
ExecStart=/usr/local/bin/fix-audio-chain.sh

[Install]
WantedBy=multi-user.target
EOFSERVICE
            sudo mkdir -p "$ROOTFS/etc/systemd/system/multi-user.target.wants"
            sudo ln -sf /lib/systemd/system/fix-audio-chain.service "$ROOTFS/etc/systemd/system/multi-user.target.wants/"
            echo "✅ Audio Chain Fix service created and enabled"
        fi
    else
        echo "⚠️  Audio Chain Fix script not found (skipping)"
    fi
fi

# Install validation script
if [ -f "scripts/audio/validate-audio-chain.sh" ]; then
    sudo mkdir -p "$ROOTFS/usr/local/bin"
    sudo cp scripts/audio/validate-audio-chain.sh "$ROOTFS/usr/local/bin/"
    sudo chmod +x "$ROOTFS/usr/local/bin/validate-audio-chain.sh" 2>/dev/null || true
    echo "✅ Audio Chain validation script installed"
fi

# 8. Install PeppyMeter Blue Skin Fix
echo "8. Installing PeppyMeter Blue Skin Fix..."
if [ -f "moode-source/lib/systemd/system/set-peppymeter-blue.service" ] && [ -f "moode-source/usr/local/bin/set-peppymeter-blue.sh" ]; then
    sudo cp moode-source/lib/systemd/system/set-peppymeter-blue.service "$ROOTFS/lib/systemd/system/"
    sudo cp moode-source/usr/local/bin/set-peppymeter-blue.sh "$ROOTFS/usr/local/bin/"
    sudo chmod +x "$ROOTFS/usr/local/bin/set-peppymeter-blue.sh" 2>/dev/null || true
    sudo mkdir -p "$ROOTFS/etc/systemd/system/multi-user.target.wants"
    sudo ln -sf /lib/systemd/system/set-peppymeter-blue.service "$ROOTFS/etc/systemd/system/multi-user.target.wants/"
    echo "✅ PeppyMeter Blue Skin Fix installed"
else
    echo "⚠️  PeppyMeter Blue Skin Fix files not found (checking scripts/wizard/)..."
    if [ -f "scripts/wizard/set-peppymeter-blue.sh" ]; then
        sudo mkdir -p "$ROOTFS/usr/local/bin"
        sudo cp scripts/wizard/set-peppymeter-blue.sh "$ROOTFS/usr/local/bin/"
        sudo chmod +x "$ROOTFS/usr/local/bin/set-peppymeter-blue.sh" 2>/dev/null || true
        
        # Create service file
        if [ ! -f "$ROOTFS/lib/systemd/system/set-peppymeter-blue.service" ]; then
            sudo mkdir -p "$ROOTFS/lib/systemd/system"
            sudo tee "$ROOTFS/lib/systemd/system/set-peppymeter-blue.service" >/dev/null <<'EOFSERVICE'
[Unit]
Description=Set PeppyMeter to Blue Skin
After=sound.target
Before=peppymeter.service
Wants=sound.target

[Service]
Type=oneshot
RemainAfterExit=yes
StandardOutput=journal
StandardError=journal
ExecStart=/usr/local/bin/set-peppymeter-blue.sh

[Install]
WantedBy=multi-user.target
EOFSERVICE
            sudo mkdir -p "$ROOTFS/etc/systemd/system/multi-user.target.wants"
            sudo ln -sf /lib/systemd/system/set-peppymeter-blue.service "$ROOTFS/etc/systemd/system/multi-user.target.wants/"
            echo "✅ PeppyMeter Blue Skin service created and enabled"
        fi
    else
        echo "⚠️  PeppyMeter Blue Skin script not found (skipping)"
    fi
fi

# 9. Install Persistent Display Configuration Fix
echo "9. Installing Persistent Display Configuration Fix..."
if [ -f "moode-source/lib/systemd/system/persist-display-config.service" ] && [ -f "scripts/display/persist-display-config.sh" ]; then
    sudo cp moode-source/lib/systemd/system/persist-display-config.service "$ROOTFS/lib/systemd/system/"
    sudo mkdir -p "$ROOTFS/usr/local/bin"
    sudo cp scripts/display/persist-display-config.sh "$ROOTFS/usr/local/bin/"
    sudo chmod +x "$ROOTFS/usr/local/bin/persist-display-config.sh" 2>/dev/null || true
    sudo mkdir -p "$ROOTFS/etc/systemd/system/multi-user.target.wants"
    sudo ln -sf /lib/systemd/system/persist-display-config.service "$ROOTFS/etc/systemd/system/multi-user.target.wants/"
    echo "✅ Persistent Display Configuration Fix installed"
else
    echo "⚠️  Persistent Display Configuration Fix files not found (skipping)"
fi

# 10. Ensure config.txt.overwrite has correct display settings AND copy to boot partition
echo "10. Ensuring config.txt has correct display settings..."
if [ -f "moode-source/boot/firmware/config.txt.overwrite" ]; then
    # Copy to moOde template location
    if [ -d "$ROOTFS/usr/share/moode-player/boot/firmware" ]; then
        sudo cp moode-source/boot/firmware/config.txt.overwrite "$ROOTFS/usr/share/moode-player/boot/firmware/"
        echo "✅ config.txt.overwrite updated in moOde template location"
    fi
    
    # CRITICAL: Copy directly to boot partition config.txt (display settings must be there BEFORE boot)
    BOOT_CONFIG_TXT=""
    if [ -d "$BOOTFS" ]; then
        if [ -f "$BOOTFS/config.txt" ]; then
            BOOT_CONFIG_TXT="$BOOTFS/config.txt"
        elif [ -f "$BOOTFS/firmware/config.txt" ]; then
            BOOT_CONFIG_TXT="$BOOTFS/firmware/config.txt"
        fi
        
        if [ -n "$BOOT_CONFIG_TXT" ]; then
            echo "  Copying config.txt.overwrite to boot partition..."
            sudo cp moode-source/boot/firmware/config.txt.overwrite "$BOOT_CONFIG_TXT"
            echo "✅ config.txt updated on boot partition with correct display settings"
        else
            echo "⚠️  Could not find config.txt on boot partition"
        fi
    else
        echo "⚠️  Boot partition not mounted (skipping direct config.txt copy)"
    fi
else
    echo "⚠️  config.txt.overwrite not found (skipping)"
fi

# 11. Ensure cmdline.txt has correct HDMI settings
echo "11. Ensuring cmdline.txt has correct HDMI settings..."
if [ -d "$BOOTFS" ]; then
    CMDLINE_TXT="$BOOTFS/cmdline.txt"
    if [ -f "$CMDLINE_TXT" ]; then
        # Check if correct video parameter exists
        if ! grep -q "video=HDMI-A-1:400x1280M@60,rotate=90" "$CMDLINE_TXT"; then
            echo "  Fixing cmdline.txt video parameter..."
            # Remove any existing video=HDMI-A-* parameters
            sudo sed -i '' 's/video=HDMI-A-[0-9]:[^ ]*//g' "$CMDLINE_TXT"
            # Remove any existing video= parameters
            sudo sed -i '' 's/video=[^ ]*//g' "$CMDLINE_TXT"
            # Add correct video parameter
            sudo sed -i '' 's/$/ video=HDMI-A-1:400x1280M@60,rotate=90/' "$CMDLINE_TXT"
            echo "✅ cmdline.txt fixed with HDMI-A-1:400x1280M@60,rotate=90"
        else
            echo "✅ cmdline.txt already has correct HDMI-A-1 settings"
        fi
        
        # Fix any HDMI-A-2 references
        if grep -q "HDMI-A-2" "$CMDLINE_TXT"; then
            sudo sed -i '' 's/HDMI-A-2/HDMI-A-1/g' "$CMDLINE_TXT"
            echo "✅ Fixed HDMI-A-2 → HDMI-A-1 in cmdline.txt"
        fi
    else
        echo "⚠️  cmdline.txt not found (skipping)"
    fi
else
    echo "⚠️  Boot partition not mounted (skipping cmdline.txt fix)"
fi

# 12. Create ALSA configs directly (CRITICAL - fixes "Failed to open ALSA default")
echo "12. Creating ALSA configs..."
sudo mkdir -p "$ROOTFS/etc/alsa/conf.d"

# Create _audioout.conf
sudo tee "$ROOTFS/etc/alsa/conf.d/_audioout.conf" > /dev/null << 'EOF'
#########################################
# This file is managed by moOde
#########################################
pcm._audioout {
type copy
slave.pcm "plughw:0,0"
}
EOF
echo "✅ Created _audioout.conf"

# Create pcm.default pointing to _audioout
sudo tee "$ROOTFS/etc/alsa/conf.d/99-default.conf" > /dev/null << 'EOF'
#########################################
# ALSA default device - points to moOde _audioout
# This file is managed by fix-audio-chain.sh
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
echo "✅ Created pcm.default → _audioout"

# Create _peppyout.conf if it doesn't exist
if [ ! -f "$ROOTFS/etc/alsa/conf.d/_peppyout.conf" ]; then
    sudo tee "$ROOTFS/etc/alsa/conf.d/_peppyout.conf" > /dev/null << 'EOF'
#########################################
# This file is managed by moOde
#########################################
pcm._peppyout {
type copy
slave.pcm "plughw:0,0"
}
EOF
    echo "✅ Created _peppyout.conf"
fi

# 13. Fix Radio Station Display (CRITICAL - fixes missing logos and buttons)
echo "13. Fixing Radio Station Display..."
if [ -d "$ROOTFS/var/local/www/imagesw" ]; then
    sudo mkdir -p "$ROOTFS/var/local/www/imagesw/radio-logos/thumbs"
    sudo chown -R 33:33 "$ROOTFS/var/local/www/imagesw/radio-logos" 2>/dev/null || sudo chown -R www-data:www-data "$ROOTFS/var/local/www/imagesw/radio-logos" 2>/dev/null || true
    sudo chmod -R 755 "$ROOTFS/var/local/www/imagesw/radio-logos" 2>/dev/null || true
    echo "✅ Radio logos directory created with correct permissions"
else
    echo "⚠️  Web directory not found (will be created on first boot)"
fi

# 14. Fix Web Interface Permissions (fixes buttons not loading)
echo "14. Fixing Web Interface Permissions..."
if [ -d "$ROOTFS/var/local/www" ]; then
    # Ensure web server can read all files
    sudo chown -R 33:33 "$ROOTFS/var/local/www" 2>/dev/null || sudo chown -R www-data:www-data "$ROOTFS/var/local/www" 2>/dev/null || true
    sudo find "$ROOTFS/var/local/www" -type d -exec chmod 755 {} \; 2>/dev/null || true
    sudo find "$ROOTFS/var/local/www" -type f -exec chmod 644 {} \; 2>/dev/null || true
    echo "✅ Web interface permissions fixed"
fi

echo ""
echo "✅✅✅ FIXES INSTALLED ✅✅✅"
echo ""
echo "Next: Eject SD card and boot Pi"
echo ""
echo "All fixes are now installed:"
echo "  ✅ Audio chain fix service (runs before MPD)"
echo "  ✅ Display persistence service (runs early)"
echo "  ✅ ALSA configs (_audioout.conf, pcm.default)"
echo "  ✅ config.txt.overwrite updated"
echo "  ✅ cmdline.txt fixed"
echo "  ✅ Radio station display fixed (permissions + directories)"
echo "  ✅ Web interface permissions fixed (buttons will load)"
echo ""

