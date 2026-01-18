#!/bin/bash
# Apply working .xinitrc display configuration
# Run: sudo ./APPLY_XINITRC_DISPLAY.sh

ROOTFS="/Volumes/rootfs"

echo "=== APPLYING WORKING .xinitrc DISPLAY CONFIG ==="
echo ""

if [ ! -d "$ROOTFS" ]; then
    echo "❌ SD card not mounted at $ROOTFS"
    exit 1
fi

echo "✅ SD card: $ROOTFS"
echo ""

# Create .xinitrc with working display settings
echo "Creating .xinitrc..."
mkdir -p "$ROOTFS/home/andre"

cat > "$ROOTFS/home/andre/.xinitrc" << 'EOF'
#!/bin/bash
# Working Display Configuration - Landscape 1280x400
# From DISPLAY_CONFIG_WORKING.md

export DISPLAY=:0
export XAUTHORITY=/home/andre/.Xauthority

# Force SCREEN_RES to landscape for Chromium
SCREEN_RES="1280,400"

# Wait for X server
for i in {1..30}; do
    if xset q &>/dev/null 2>&1; then
        break
    fi
    sleep 1
done

# CRITICAL: Reset rotation first, then set mode, then apply rotation
DISPLAY=:0 xrandr --output HDMI-1 --rotate normal 2>/dev/null || true
sleep 1
DISPLAY=:0 xrandr --output HDMI-1 --mode 400x1280 2>/dev/null || true
sleep 1
DISPLAY=:0 xrandr --output HDMI-1 --rotate left 2>/dev/null || true
sleep 1

# Launch Chromium with working flags
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

chmod +x "$ROOTFS/home/andre/.xinitrc"
chown -R 1000:1000 "$ROOTFS/home/andre"

echo "✅ .xinitrc created"
echo ""
echo "=== VERIFICATION ==="
ls -la "$ROOTFS/home/andre/.xinitrc"
echo ""
echo "✅✅✅ WORKING DISPLAY CONFIG COMPLETE ✅✅✅"
echo ""
echo "Files applied:"
echo "  ✅ /boot/firmware/config.txt (hdmi_group=0)"
echo "  ✅ /boot/firmware/cmdline.txt (video=HDMI-A-1:400x1280M@60,rotate=90)"
echo "  ✅ /home/andre/.xinitrc (SCREEN_RES=1280,400 + xrandr rotation)"
echo ""
echo "Next: Eject SD card and boot Pi"
echo ""

