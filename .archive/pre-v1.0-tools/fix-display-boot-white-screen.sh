#!/bin/bash
# Fix white screen on boot - proper display initialization
# Run: sudo bash fix-display-boot-white-screen.sh

echo "=== FIXING WHITE SCREEN ON BOOT ==="

# The issue: Display/X11 starts before rotation is applied, showing white screen
# Fix: Add proper delays and hide display until rotation is complete

# 1. Fix .xinitrc to hide display until ready
cat > /home/andre/.xinitrc << 'XINITRC'
#!/bin/bash
# moOde .xinitrc with proper display initialization to prevent white screen

# Turn off screen immediately to prevent white flash
xset dpms force off 2>/dev/null || true
sleep 0.5

# Get moOde settings
PEPPY_DISPLAY=$(sqlite3 /var/local/www/db/moode-sqlite3.db "SELECT value FROM cfg_system WHERE param='peppy_display';" 2>/dev/null || echo "0")
LOCAL_DISPLAY=$(sqlite3 /var/local/www/db/moode-sqlite3.db "SELECT value FROM cfg_system WHERE param='local_display';" 2>/dev/null || echo "0")
LOCAL_DISPLAY_URL=$(sqlite3 /var/local/www/db/moode-sqlite3.db "SELECT value FROM cfg_system WHERE param='local_display_url';" 2>/dev/null || echo "http://localhost/")
HDMI_SCN_ORIENT=$(sqlite3 /var/local/www/db/moode-sqlite3.db "SELECT value FROM cfg_system WHERE param='hdmi_scn_orient';" 2>/dev/null || echo "landscape")

# Detect HDMI output - wait for it to be ready
HDMI_OUT=""
for i in {1..15}; do
    HDMI_OUT=$(xrandr --query 2>/dev/null | awk '/^HDMI-[0-9]+ connected/{print $1; exit}')
    [ -n "${HDMI_OUT}" ] && break
    sleep 0.5
done
[ -z "${HDMI_OUT}" ] && HDMI_OUT=HDMI-1

# Apply rotation BEFORE turning screen back on
if [ "$HDMI_SCN_ORIENT" = "portrait" ]; then
    xrandr --output "$HDMI_OUT" --rotate normal 2>/dev/null || true
    sleep 0.3
    xrandr --output "$HDMI_OUT" --mode 400x1280 2>/dev/null || true
    sleep 0.3
    xrandr --output "$HDMI_OUT" --rotate left 2>/dev/null || true
else
    xrandr --output "$HDMI_OUT" --rotate normal 2>/dev/null || true
    sleep 0.3
    xrandr --output "$HDMI_OUT" --mode 1280x400 2>/dev/null || true
fi

# Wait for rotation to settle
sleep 0.5

# Set background to black (prevents white flash)
xsetroot -solid black 2>/dev/null || true

# NOW turn screen back on
xset dpms force on 2>/dev/null || true
xset s off 2>/dev/null || true
xset -dpms 2>/dev/null || true

# Disable screensaver
xset s noblank 2>/dev/null || true

# Start applications
if [ "$PEPPY_DISPLAY" = "1" ]; then
    # PeppyMeter
    /opt/peppymeter/peppymeter.py 2>/dev/null
fi

if [ "$LOCAL_DISPLAY" = "1" ]; then
    # Chromium
    sleep 2
    chromium-browser --kiosk --noerrdialogs --disable-infobars \
        --disable-session-crashed-bubble --check-for-update-interval=31536000 \
        --no-first-run --disable-features=TranslateUI \
        --window-position=0,0 --window-size=1280,400 \
        --start-fullscreen "$LOCAL_DISPLAY_URL" 2>/dev/null &
fi

# Keep X session alive
while true; do
    sleep 3600
done
XINITRC

chown andre:andre /home/andre/.xinitrc
chmod +x /home/andre/.xinitrc
echo "✅ .xinitrc fixed with proper display initialization"

# 2. Add delay to localdisplay service
cat > /lib/systemd/system/localdisplay.service << 'SERVICE'
[Unit]
Description=Local display on HDMI
After=network.target sound.target
Wants=network.target

[Service]
Type=simple
User=andre
Environment=DISPLAY=:0
Environment=XAUTHORITY=/home/andre/.Xauthority
ExecStartPre=/bin/sleep 3
ExecStart=/usr/bin/startx /home/andre/.xinitrc -- -nocursor
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
SERVICE

systemctl daemon-reload
echo "✅ Display service updated with startup delay"

echo ""
echo "=== FIX COMPLETE ==="
echo "Changes:"
echo "  1. Display turns off immediately on X start"
echo "  2. Rotation applied while screen is off"
echo "  3. Screen turns back on after rotation complete"
echo "  4. Black background prevents white flash"
echo "  5. 3 second delay before X starts"
echo ""
echo "Reboot to test: sudo reboot"
