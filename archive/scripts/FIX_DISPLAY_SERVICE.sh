#!/bin/bash
################################################################################
#
# FIX DISPLAY SERVICE - Autonomous Fix Script
# 
# Fixes all issues with localdisplay.service and Chromium startup
#
################################################################################

set -e

LOG_FILE="/var/log/fix-display-service.log"
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log "=== DISPLAY SERVICE FIX START ==="

################################################################################
# 1. Check if running as root
################################################################################
if [ "$EUID" -ne 0 ]; then 
    log "❌ Please run as root (sudo)"
    exit 1
fi

################################################################################
# 2. Ensure service file exists
################################################################################
log "Checking localdisplay.service..."
SERVICE_FILE="/lib/systemd/system/localdisplay.service"
SERVICE_SOURCE="/tmp/localdisplay.service"

if [ ! -f "$SERVICE_FILE" ]; then
    log "⚠️  Service file not found, creating..."
    cat > "$SERVICE_FILE" << 'EOF'
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
EOF
    log "✅ Service file created"
else
    log "✅ Service file exists"
fi

################################################################################
# 3. Ensure scripts exist
################################################################################
log "Checking required scripts..."

# xserver-ready.sh
if [ ! -f "/usr/local/bin/xserver-ready.sh" ]; then
    log "⚠️  xserver-ready.sh not found, creating..."
    mkdir -p /usr/local/bin
    cat > "/usr/local/bin/xserver-ready.sh" << 'EOF'
#!/bin/bash
# Wait for X Server to be ready
export DISPLAY=:0
for i in {1..30}; do
    if xset q &>/dev/null; then
        exit 0
    fi
    sleep 1
done
exit 1
EOF
    chmod +x /usr/local/bin/xserver-ready.sh
    log "✅ xserver-ready.sh created"
else
    log "✅ xserver-ready.sh exists"
    chmod +x /usr/local/bin/xserver-ready.sh
fi

# start-chromium-clean.sh
if [ ! -f "/usr/local/bin/start-chromium-clean.sh" ]; then
    log "⚠️  start-chromium-clean.sh not found, creating..."
    mkdir -p /usr/local/bin
    cat > "/usr/local/bin/start-chromium-clean.sh" << 'EOF'
#!/bin/bash
# Ghettoblaster - Clean Chromium Startup
export DISPLAY=:0
export XAUTHORITY=/home/andre/.Xauthority
LOG_FILE=/var/log/chromium-clean.log
log() {
    echo "[$(date +%Y-%m-%d\ %H:%M:%S)] $1" | tee -a "$LOG_FILE"
}
log "=== CHROMIUM CLEAN START ==="
/usr/local/bin/xserver-ready.sh || exit 1
log "✅ X Server bereit"
xhost +SI:localuser:andre 2>/dev/null || true
sleep 1
if xrandr | grep -q "400x1280"; then
    xrandr --output HDMI-2 --mode 400x1280 --rotate left 2>&1 || \
    xrandr --output HDMI-1 --mode 400x1280 --rotate left 2>&1
elif xrandr | grep -q "1280x400"; then
    xrandr --output HDMI-2 --mode 1280x400 --rotate normal 2>&1 || \
    xrandr --output HDMI-1 --mode 1280x400 --rotate normal 2>&1
fi
xset s off 2>/dev/null || true
xset -dpms 2>/dev/null || true
pkill -9 chromium 2>/dev/null || true
pkill -9 chromium-browser 2>/dev/null || true
sleep 2
rm -rf /tmp/chromium-data/Singleton* 2>/dev/null || true
log "Starte Chromium..."
chromium-browser \
    --kiosk \
    --no-sandbox \
    --user-data-dir=/tmp/chromium-data \
    --window-size=1280,400 \
    --window-position=0,0 \
    --start-fullscreen \
    --noerrdialogs \
    --disable-infobars \
    --disable-session-crashed-bubble \
    --disable-restore-session-state \
    --disable-web-security \
    --autoplay-policy=no-user-gesture-required \
    --check-for-update-interval=31536000 \
    --disable-features=TranslateUI \
    --disable-gpu \
    --disable-software-rasterizer \
    http://localhost >/dev/null 2>&1 &
CHROMIUM_PID=$!
sleep 3
if ps -p $CHROMIUM_PID > /dev/null 2>&1; then
    log "✅ Chromium gestartet (PID: $CHROMIUM_PID)"
    for i in {1..10}; do
        WINDOW=$(xdotool search --class Chromium 2>/dev/null | head -1)
        if [ -n "$WINDOW" ]; then
            xdotool windowsize $WINDOW 1280 400 2>/dev/null
            xdotool windowmove $WINDOW 0 0 2>/dev/null
            xdotool windowraise $WINDOW 2>/dev/null
            log "✅ Chromium Window gefunden"
            exit 0
        fi
        sleep 1
    done
    log "⚠️  Chromium läuft, aber Window nicht gefunden"
    exit 0
else
    log "❌ Chromium Start fehlgeschlagen"
    exit 1
fi
EOF
    chmod +x /usr/local/bin/start-chromium-clean.sh
    log "✅ start-chromium-clean.sh created"
else
    log "✅ start-chromium-clean.sh exists"
    chmod +x /usr/local/bin/start-chromium-clean.sh
fi

################################################################################
# 4. Ensure user andre exists and has correct permissions
################################################################################
log "Checking user 'andre'..."
if ! id -u andre &>/dev/null; then
    log "⚠️  User 'andre' not found, creating..."
    useradd -m -s /bin/bash -u 1000 -g 1000 andre 2>/dev/null || {
        groupadd -g 1000 andre 2>/dev/null || true
        useradd -m -s /bin/bash -u 1000 -g 1000 andre
    }
    usermod -aG audio,video,spi,i2c,gpio,plugdev,sudo andre 2>/dev/null || true
    echo "andre:0815" | chpasswd 2>/dev/null || true
    log "✅ User 'andre' created"
else
    log "✅ User 'andre' exists"
    # Ensure in sudo group
    usermod -aG sudo andre 2>/dev/null || true
fi

# Ensure XAUTHORITY directory exists
mkdir -p /home/andre
chown -R andre:andre /home/andre 2>/dev/null || true

################################################################################
# 5. Reload systemd and enable service
################################################################################
log "Reloading systemd..."
systemctl daemon-reload
log "✅ Systemd reloaded"

log "Enabling localdisplay.service..."
systemctl enable localdisplay.service 2>/dev/null || true
log "✅ Service enabled"

################################################################################
# 6. Check dependencies
################################################################################
log "Checking dependencies..."

# Check xserver-ready.service
if [ -f "/lib/systemd/system/xserver-ready.service" ]; then
    systemctl enable xserver-ready.service 2>/dev/null || true
    log "✅ xserver-ready.service enabled"
else
    log "⚠️  xserver-ready.service not found (may be optional)"
fi

# Check if X server is running
if pgrep -x Xorg >/dev/null || pgrep -x X >/dev/null; then
    log "✅ X Server is running"
else
    log "⚠️  X Server not running (will start with graphical.target)"
fi

################################################################################
# 7. Check for common issues
################################################################################
log "Checking for common issues..."

# Check if chromium-browser is installed
if ! command -v chromium-browser &>/dev/null; then
    log "❌ chromium-browser not found!"
    log "   Install with: apt-get install chromium-browser"
else
    log "✅ chromium-browser found"
fi

# Check if xdotool is installed
if ! command -v xdotool &>/dev/null; then
    log "⚠️  xdotool not found (optional, for window management)"
else
    log "✅ xdotool found"
fi

################################################################################
# 8. Start the service
################################################################################
log "Starting localdisplay.service..."
systemctl stop localdisplay.service 2>/dev/null || true
sleep 1
systemctl start localdisplay.service
sleep 3

if systemctl is-active --quiet localdisplay.service; then
    log "✅ localdisplay.service is running"
else
    log "❌ localdisplay.service failed to start"
    log "Checking status..."
    systemctl status localdisplay.service --no-pager -l | head -20
    log "Checking logs..."
    journalctl -u localdisplay.service -n 30 --no-pager
fi

################################################################################
# 9. Final status
################################################################################
log "=== FINAL STATUS ==="
log "Service status:"
systemctl status localdisplay.service --no-pager -l | head -10

log "Recent logs:"
journalctl -u localdisplay.service -n 20 --no-pager | tail -10

log "=== FIX COMPLETE ==="
log "Check /var/log/fix-display-service.log for full log"
log "Check /var/log/chromium-clean.log for Chromium logs"

