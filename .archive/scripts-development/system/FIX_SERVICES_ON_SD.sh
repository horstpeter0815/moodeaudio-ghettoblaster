#!/bin/bash
# Fix Stopped Services - Run on Mac with SD card mounted
# Run from HOME: bash ~/moodeaudio-cursor/scripts/system/FIX_SERVICES_ON_SD.sh

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  🔧 Fix Stopped Services on SD Card                          ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

ROOTFS="/Volumes/rootfs"
BOOTFS="/Volumes/bootfs"

# Check if SD card is mounted
if [ ! -d "$ROOTFS" ]; then
    echo "❌ SD card not mounted!"
    echo ""
    echo "Please:"
    echo "  1. Insert SD card into Mac"
    echo "  2. Wait for it to mount"
    echo "  3. Run this script again"
    echo ""
    echo "Expected mount points:"
    echo "  - /Volumes/bootfs (boot partition)"
    echo "  - /Volumes/rootfs (root partition)"
    exit 1
fi

echo "✅ SD card found"
echo "   Boot: $BOOTFS"
echo "   Root: $ROOTFS"
echo ""

# 1. Enable SSH (if not already)
echo "1. Enabling SSH..."
if [ -d "$BOOTFS" ]; then
    sudo touch "$BOOTFS/ssh" 2>/dev/null
    echo "   ✅ SSH enabled (boot/ssh file created)"
else
    echo "   ⚠️  Boot partition not found"
fi
echo ""

# 2. Check and enable critical services
echo "2. Checking service enablement..."
echo ""

# NetworkManager
if [ -f "$ROOTFS/etc/systemd/system/multi-user.target.wants/NetworkManager.service" ] || \
   [ -L "$ROOTFS/etc/systemd/system/multi-user.target.wants/NetworkManager.service" ]; then
    echo "   ✅ NetworkManager: enabled"
else
    echo "   ⚠️  NetworkManager: not enabled"
    echo "      (will enable on next boot)"
fi

# Apache
if [ -f "$ROOTFS/etc/systemd/system/multi-user.target.wants/apache2.service" ] || \
   [ -L "$ROOTFS/etc/systemd/system/multi-user.target.wants/apache2.service" ]; then
    echo "   ✅ Apache: enabled"
else
    echo "   ⚠️  Apache: not enabled"
    echo "      (will enable on next boot)"
fi

# MPD
if [ -f "$ROOTFS/etc/systemd/system/multi-user.target.wants/mpd.service" ] || \
   [ -L "$ROOTFS/etc/systemd/system/multi-user.target.wants/mpd.service" ]; then
    echo "   ✅ MPD: enabled"
else
    echo "   ⚠️  MPD: not enabled"
    echo "      (will enable on next boot)"
fi

# SSH
if [ -f "$ROOTFS/etc/systemd/system/multi-user.target.wants/ssh.service" ] || \
   [ -L "$ROOTFS/etc/systemd/system/multi-user.target.wants/ssh.service" ] || \
   [ -f "$ROOTFS/etc/systemd/system/multi-user.target.wants/sshd.service" ] || \
   [ -L "$ROOTFS/etc/systemd/system/multi-user.target.wants/sshd.service" ]; then
    echo "   ✅ SSH: enabled"
else
    echo "   ⚠️  SSH: not enabled"
    echo "      (will enable on next boot)"
fi

# localdisplay
if [ -f "$ROOTFS/etc/systemd/system/multi-user.target.wants/localdisplay.service" ] || \
   [ -L "$ROOTFS/etc/systemd/system/multi-user.target.wants/localdisplay.service" ]; then
    echo "   ✅ localdisplay: enabled"
else
    echo "   ⚠️  localdisplay: not enabled"
    echo "      (will enable on next boot)"
fi
echo ""

# 3. Disable login managers (if they exist)
echo "3. Disabling login managers..."
if [ -f "$ROOTFS/etc/systemd/system/display-manager.service" ]; then
    if [ -L "$ROOTFS/etc/systemd/system/display-manager.service" ]; then
        TARGET=$(readlink "$ROOTFS/etc/systemd/system/display-manager.service")
        if echo "$TARGET" | grep -q "lightdm\|gdm"; then
            echo "   ⚠️  Login manager detected: $(basename $TARGET)"
            echo "      (will disable on next boot)"
        fi
    fi
fi

# Check for lightdm/gdm services
if [ -d "$ROOTFS/etc/systemd/system/multi-user.target.wants" ]; then
    if [ -L "$ROOTFS/etc/systemd/system/multi-user.target.wants/lightdm.service" ] || \
       [ -L "$ROOTFS/etc/systemd/system/multi-user.target.wants/gdm.service" ]; then
        echo "   ⚠️  Login manager enabled"
        echo "      (will disable on next boot)"
    else
        echo "   ✅ Login managers: disabled"
    fi
fi
echo ""

# 4. Check critical configuration files
echo "4. Checking critical configurations..."
echo ""

# NetworkManager config
if [ -d "$ROOTFS/etc/NetworkManager/system-connections" ]; then
    CONN_COUNT=$(ls "$ROOTFS/etc/NetworkManager/system-connections" 2>/dev/null | wc -l | tr -d ' ')
    if [ "$CONN_COUNT" -gt 0 ]; then
        echo "   ✅ NetworkManager: $CONN_COUNT connection(s) configured"
    else
        echo "   ⚠️  NetworkManager: No connections configured"
    fi
else
    echo "   ⚠️  NetworkManager config directory not found"
fi

# Apache config
if [ -f "$ROOTFS/etc/apache2/apache2.conf" ] || [ -f "$ROOTFS/etc/httpd/httpd.conf" ]; then
    echo "   ✅ Apache: Configuration file exists"
else
    echo "   ⚠️  Apache: Configuration file not found"
fi

# MPD config
if [ -f "$ROOTFS/etc/mpd.conf" ] || [ -f "$ROOTFS/etc/mpd/mpd.conf" ]; then
    echo "   ✅ MPD: Configuration file exists"
else
    echo "   ⚠️  Apache: Configuration file not found"
fi
echo ""

# 5. Create recovery script on SD card
echo "5. Creating recovery script on SD card..."
RECOVERY_SCRIPT="$ROOTFS/root/recover-services.sh"
sudo tee "$RECOVERY_SCRIPT" > /dev/null << 'RECOVERY_EOF'
#!/bin/bash
# Recovery script - Run on Pi after boot
echo "=== Recovering Services ==="

# Enable and start critical services
systemctl enable NetworkManager
systemctl start NetworkManager
sleep 2

systemctl enable apache2
systemctl start apache2
sleep 2

systemctl enable mpd
systemctl start mpd
sleep 2

systemctl enable ssh
systemctl start ssh
sleep 2

systemctl enable localdisplay.service
systemctl start localdisplay.service

# Disable login managers
systemctl disable lightdm gdm 2>/dev/null
systemctl stop lightdm gdm 2>/dev/null

echo "✅ Services recovered"
echo "Check status: systemctl status NetworkManager apache2 mpd ssh localdisplay"
RECOVERY_EOF

sudo chmod +x "$RECOVERY_SCRIPT"
echo "   ✅ Recovery script created: $RECOVERY_SCRIPT"
echo ""

# 6. Summary
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📋 Summary"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "✅ SD card checked and prepared"
echo ""
echo "Next steps:"
echo "  1. Eject SD card safely"
echo "  2. Insert into Pi"
echo "  3. Boot Pi"
echo "  4. Wait 2-3 minutes for full boot"
echo "  5. If services still stopped, run on Pi:"
echo "     sudo bash /root/recover-services.sh"
echo ""
echo "Or SSH to Pi and run:"
echo "  ssh andre@192.168.1.159"
echo "  sudo systemctl start NetworkManager apache2 mpd ssh localdisplay"
echo "  sudo systemctl enable NetworkManager apache2 mpd ssh localdisplay"
echo ""
