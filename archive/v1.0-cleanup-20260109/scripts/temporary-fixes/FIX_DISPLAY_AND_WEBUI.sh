#!/bin/bash
# Fix display (landscape) and enable Web UI by default
# Run: sudo ./FIX_DISPLAY_AND_WEBUI.sh

ROOTFS="/Volumes/rootfs"
BOOTFS="/Volumes/bootfs"

echo "=== FIXING DISPLAY AND ENABLING WEB UI ==="
echo ""

if [ ! -d "$ROOTFS" ]; then
    echo "❌ SD card not mounted"
    exit 1
fi

echo "✅ SD card: $ROOTFS"
echo ""

# 1. Fix display configuration (landscape mode)
echo "1. Fixing display configuration (landscape)..."

# Find boot partition
BOOT_CONFIG=""
if [ -f "$BOOTFS/config.txt" ]; then
    BOOT_CONFIG="$BOOTFS/config.txt"
elif [ -f "$ROOTFS/boot/firmware/config.txt" ]; then
    BOOT_CONFIG="$ROOTFS/boot/firmware/config.txt"
    mkdir -p "$ROOTFS/boot/firmware"
fi

if [ -n "$BOOT_CONFIG" ]; then
    # Backup
    cp "$BOOT_CONFIG" "${BOOT_CONFIG}.backup" 2>/dev/null || true
    
    # Ensure hdmi_group=0 (for custom resolution)
    if ! grep -q "^hdmi_group=0" "$BOOT_CONFIG"; then
        echo "hdmi_group=0" >> "$BOOT_CONFIG"
    fi
    
    # Remove any display_rotate (we use cmdline.txt instead)
    sed -i '' '/^display_rotate=/d' "$BOOT_CONFIG" 2>/dev/null || sed -i '/^display_rotate=/d' "$BOOT_CONFIG" 2>/dev/null || true
    
    echo "✅ config.txt fixed"
else
    echo "⚠️  config.txt not found, creating..."
    if [ -d "$BOOTFS" ]; then
        echo "hdmi_group=0" > "$BOOTFS/config.txt"
    else
        mkdir -p "$ROOTFS/boot/firmware"
        echo "hdmi_group=0" > "$ROOTFS/boot/firmware/config.txt"
    fi
fi

# Fix cmdline.txt for landscape
CMDLINE=""
if [ -f "$BOOTFS/cmdline.txt" ]; then
    CMDLINE="$BOOTFS/cmdline.txt"
elif [ -f "$ROOTFS/boot/firmware/cmdline.txt" ]; then
    CMDLINE="$ROOTFS/boot/firmware/cmdline.txt"
fi

if [ -n "$CMDLINE" ]; then
    # Backup
    cp "$CMDLINE" "${CMDLINE}.backup" 2>/dev/null || true
    
    # Remove old video parameter
    sed -i '' 's/ video=[^ ]*//' "$CMDLINE" 2>/dev/null || sed -i 's/ video=[^ ]*//' "$CMDLINE" 2>/dev/null || true
    
    # Add landscape video parameter (400x1280 portrait rotated 90° = 1280x400 landscape)
    if ! grep -q "video=" "$CMDLINE"; then
        # Add to end of line
        sed -i '' 's/$/ video=HDMI-A-1:400x1280M@60,rotate=90/' "$CMDLINE" 2>/dev/null || sed -i 's/$/ video=HDMI-A-1:400x1280M@60,rotate=90/' "$CMDLINE" 2>/dev/null || true
    fi
    
    echo "✅ cmdline.txt fixed (landscape mode)"
fi

# 2. Enable Web UI by default in moOde database
echo "2. Enabling Web UI by default..."

# Create SQL script to enable Web UI
mkdir -p "$ROOTFS/usr/local/bin"
cat > "$ROOTFS/usr/local/bin/enable-webui-default.sh" << 'EOF'
#!/bin/bash
# Enable Web UI by default on first boot

DB="/var/local/www/db/moode-sqlite3.db"

# Wait for database to exist
for i in {1..30}; do
    if [ -f "$DB" ]; then
        break
    fi
    sleep 1
done

if [ -f "$DB" ]; then
    # Enable local display (Web UI)
    sqlite3 "$DB" "UPDATE cfg_system SET value='1' WHERE param='local_display';" 2>/dev/null || true
    
    # Disable Peppy (if enabled)
    sqlite3 "$DB" "UPDATE cfg_system SET value='0' WHERE param='peppy_display';" 2>/dev/null || true
    
    # Set HDMI orientation to portrait (hardware is portrait, software rotates to landscape)
    sqlite3 "$DB" "UPDATE cfg_system SET value='portrait' WHERE param='hdmi_scn_orient';" 2>/dev/null || true
    
    echo "Web UI enabled by default"
fi
EOF

chmod +x "$ROOTFS/usr/local/bin/enable-webui-default.sh" 2>/dev/null || true

# Create systemd service to run on first boot
mkdir -p "$ROOTFS/lib/systemd/system"
cat > "$ROOTFS/lib/systemd/system/enable-webui-default.service" << 'EOF'
[Unit]
Description=Enable Web UI by Default on First Boot
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/enable-webui-default.sh
RemainAfterExit=yes
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

# Enable the service
mkdir -p "$ROOTFS/etc/systemd/system/multi-user.target.wants"
ln -sf /lib/systemd/system/enable-webui-default.service "$ROOTFS/etc/systemd/system/multi-user.target.wants/" 2>/dev/null || true

echo "✅ Web UI enabled by default service created"

# 3. Ensure localdisplay service is enabled
echo "3. Ensuring localdisplay service is enabled..."

if [ -f "$ROOTFS/lib/systemd/system/localdisplay.service" ]; then
    mkdir -p "$ROOTFS/etc/systemd/system/multi-user.target.wants"
    ln -sf /lib/systemd/system/localdisplay.service "$ROOTFS/etc/systemd/system/multi-user.target.wants/" 2>/dev/null || true
    echo "✅ localdisplay service enabled"
fi

# 4. Fix .xinitrc for landscape
echo "4. Fixing .xinitrc for landscape mode..."

mkdir -p "$ROOTFS/home/andre"
cat > "$ROOTFS/home/andre/.xinitrc" << 'EOF'
#!/bin/bash
# Landscape mode Web UI - Working Configuration

export DISPLAY=:0
export XAUTHORITY=/home/andre/.Xauthority

# Force SCREEN_RES to landscape
SCREEN_RES="1280,400"

# Wait for X server
for i in {1..30}; do
    if xset q &>/dev/null 2>&1; then
        break
    fi
    sleep 1
done

# CRITICAL: Reset rotation, set mode, then rotate
DISPLAY=:0 xrandr --output HDMI-1 --rotate normal 2>/dev/null || true
sleep 1
DISPLAY=:0 xrandr --output HDMI-1 --mode 400x1280 2>/dev/null || true
sleep 1
DISPLAY=:0 xrandr --output HDMI-1 --rotate left 2>/dev/null || true
sleep 1

# Launch Chromium with landscape settings
chromium \
--app="http://localhost/" \
--window-size="1280,400" \
--force-device-scale-factor=1 \
--window-position="0,0" \
--enable-features="OverlayScrollbar" \
--no-first-run \
--disable-infobars \
--disable-session-crashed-bubble \
--start-fullscreen \
--kiosk
EOF

chmod +x "$ROOTFS/home/andre/.xinitrc" 2>/dev/null || true
chown -R 1000:1000 "$ROOTFS/home/andre" 2>/dev/null || true

echo "✅ .xinitrc created (landscape mode)"

echo ""
echo "✅✅✅ DISPLAY AND WEB UI FIXED ✅✅✅"
echo ""
echo "Fixed:"
echo "  ✅ Display: Landscape mode (1280x400)"
echo "  ✅ Web UI: Enabled by default on first boot"
echo "  ✅ .xinitrc: Landscape configuration"
echo ""
echo "Next: Eject SD card and boot Pi"
echo ""

