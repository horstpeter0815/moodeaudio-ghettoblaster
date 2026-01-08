#!/bin/bash
################################################################################
#
# FIX IMAGE DIRECTLY - Mount and fix image without waiting for Pi
# 
# Mounts the image file, applies all fixes directly to the filesystem
#
################################################################################

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Find latest image
LATEST_IMG=$(ls -t *.img 2>/dev/null | grep -E "(moode|hifiberryos)" | head -1)

if [ -z "$LATEST_IMG" ]; then
    echo "❌ No image file found"
    exit 1
fi

echo "=== FIXING IMAGE DIRECTLY: $LATEST_IMG ==="

# Check if running on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo "❌ This script requires macOS (for hdiutil)"
    exit 1
fi

# Create mount point
MOUNT_POINT="/tmp/image-rootfs-$$"
mkdir -p "$MOUNT_POINT"

echo "Mounting image..."
# On macOS, we need to use hdiutil or qemu-img to mount
# For now, let's try using the Docker container approach
if docker ps | grep -q complete-simulator; then
    echo "Using Docker container to mount image..."
    
    # Copy image to container
    docker cp "$LATEST_IMG" complete-simulator:/tmp/image.img
    
    # Mount in container
    docker exec complete-simulator bash -c "
        mkdir -p /tmp/image-mount
        # Try to mount using loop device
        LOOP=\$(losetup -f)
        losetup -P \$LOOP /tmp/image.img
        mount \${LOOP}p2 /tmp/image-mount 2>/dev/null || mount \${LOOP}p3 /tmp/image-mount 2>/dev/null || {
            echo 'Could not mount image partitions'
            losetup -d \$LOOP
            exit 1
        }
        
        echo 'Image mounted at /tmp/image-mount'
        
        # Apply fixes
        echo 'Applying fixes...'
        
        # 1. Copy service file
        if [ -f /tmp/image-mount/lib/systemd/system/localdisplay.service ]; then
            echo 'Service file already exists'
        else
            mkdir -p /tmp/image-mount/lib/systemd/system
            cat > /tmp/image-mount/lib/systemd/system/localdisplay.service << 'EOFSERVICE'
[Unit]
Description=Start Local Display (Ghettoblaster)
After=graphical.target
After=xserver-ready.service
Wants=graphical.target
Wants=xserver-ready.service
Requires=graphical.target

[Service]
Type=simple
User=andre
Environment=DISPLAY=:0
Environment=XAUTHORITY=/home/andre/.Xauthority
ExecStartPre=/usr/local/bin/xserver-ready.sh
ExecStartPre=/bin/sleep 2
ExecStart=/usr/local/bin/start-chromium-clean.sh
TimeoutStartSec=60
Restart=on-failure
RestartSec=5
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOFSERVICE
            echo '✅ Service file created'
        fi
        
        # 2. Copy auto-fix service
        mkdir -p /tmp/image-mount/lib/systemd/system
        cat > /tmp/image-mount/lib/systemd/system/auto-fix-display.service << 'EOFAUTOFIX'
[Unit]
Description=Auto-Fix Display Service on Boot
After=network.target
Before=localdisplay.service

[Service]
Type=oneshot
ExecStart=/usr/local/bin/auto-fix-display.sh
RemainAfterExit=yes
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOFAUTOFIX
        echo '✅ Auto-fix service created'
        
        # 3. Copy scripts
        mkdir -p /tmp/image-mount/usr/local/bin
        
        # xserver-ready.sh
        cat > /tmp/image-mount/usr/local/bin/xserver-ready.sh << 'EOFXSERVER'
#!/bin/bash
export DISPLAY=:0
for i in {1..30}; do
    if xset q &>/dev/null; then
        exit 0
    fi
    sleep 1
done
exit 1
EOFXSERVER
        chmod +x /tmp/image-mount/usr/local/bin/xserver-ready.sh
        
        # start-chromium-clean.sh (full version)
        cat > /tmp/image-mount/usr/local/bin/start-chromium-clean.sh << 'EOFCHROMIUM'
#!/bin/bash
export DISPLAY=:0
export XAUTHORITY=/home/andre/.Xauthority
LOG_FILE=/var/log/chromium-clean.log
log() {
    echo \"[\$(date +%Y-%m-%d\ %H:%M:%S)] \$1\" | tee -a \"\$LOG_FILE\"
}
log \"=== CHROMIUM CLEAN START ===\"
/usr/local/bin/xserver-ready.sh || exit 1
log \"✅ X Server bereit\"
xhost +SI:localuser:andre 2>/dev/null || true
sleep 1
if xrandr | grep -q \"400x1280\"; then
    xrandr --output HDMI-2 --mode 400x1280 --rotate left 2>&1 || \\
    xrandr --output HDMI-1 --mode 400x1280 --rotate left 2>&1
elif xrandr | grep -q \"1280x400\"; then
    xrandr --output HDMI-2 --mode 1280x400 --rotate normal 2>&1 || \\
    xrandr --output HDMI-1 --mode 1280x400 --rotate normal 2>&1
fi
xset s off 2>/dev/null || true
xset -dpms 2>/dev/null || true
pkill -9 chromium 2>/dev/null || true
pkill -9 chromium-browser 2>/dev/null || true
sleep 2
rm -rf /tmp/chromium-data/Singleton* 2>/dev/null || true
log \"Starte Chromium...\"
chromium-browser \\
    --kiosk \\
    --no-sandbox \\
    --user-data-dir=/tmp/chromium-data \\
    --window-size=1280,400 \\
    --window-position=0,0 \\
    --start-fullscreen \\
    --noerrdialogs \\
    --disable-infobars \\
    --disable-session-crashed-bubble \\
    --disable-restore-session-state \\
    --disable-web-security \\
    --autoplay-policy=no-user-gesture-required \\
    --check-for-update-interval=31536000 \\
    --disable-features=TranslateUI \\
    --disable-gpu \\
    --disable-software-rasterizer \\
    http://localhost >/dev/null 2>&1 &
CHROMIUM_PID=\$!
sleep 3
if ps -p \$CHROMIUM_PID > /dev/null 2>&1; then
    log \"✅ Chromium gestartet (PID: \$CHROMIUM_PID)\"
    for i in {1..10}; do
        WINDOW=\$(xdotool search --class Chromium 2>/dev/null | head -1)
        if [ -n \"\$WINDOW\" ]; then
            xdotool windowsize \$WINDOW 1280 400 2>/dev/null
            xdotool windowmove \$WINDOW 0 0 2>/dev/null
            xdotool windowraise \$WINDOW 2>/dev/null
            log \"✅ Chromium Window gefunden\"
            exit 0
        fi
        sleep 1
    done
    log \"⚠️  Chromium läuft, aber Window nicht gefunden\"
    exit 0
else
    log \"❌ Chromium Start fehlgeschlagen\"
    exit 1
fi
EOFCHROMIUM
        chmod +x /tmp/image-mount/usr/local/bin/start-chromium-clean.sh
        
        # auto-fix-display.sh
        cat > /tmp/image-mount/usr/local/bin/auto-fix-display.sh << 'EOFAUTOSCRIPT'
#!/bin/bash
export DISPLAY=:0
for i in {1..30}; do
    if xset q &>/dev/null; then
        exit 0
    fi
    sleep 1
done
exit 1
EOFAUTOSCRIPT
        chmod +x /tmp/image-mount/usr/local/bin/auto-fix-display.sh
        
        echo '✅ Scripts created'
        
        # 4. Enable services in systemd
        mkdir -p /tmp/image-mount/etc/systemd/system/multi-user.target.wants
        ln -sf /lib/systemd/system/localdisplay.service /tmp/image-mount/etc/systemd/system/multi-user.target.wants/localdisplay.service
        ln -sf /lib/systemd/system/auto-fix-display.service /tmp/image-mount/etc/systemd/system/multi-user.target.wants/auto-fix-display.service
        
        echo '✅ Services enabled'
        
        sync
        umount /tmp/image-mount
        losetup -d \$LOOP
        echo '✅ Image unmounted'
    "
    
    echo "✅ Image fixed successfully!"
else
    echo "⚠️  Docker container not available, using alternative method..."
    echo "Image will be fixed when Pi comes online via AUTONOMOUS_FIX_SYSTEM.sh"
fi

echo "=== DONE ==="

