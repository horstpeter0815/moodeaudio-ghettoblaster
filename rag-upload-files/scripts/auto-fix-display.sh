#!/bin/bash
################################################################################
#
# AUTO-FIX DISPLAY ON BOOT
# 
# Automatically fixes display service if it's missing or broken
# Runs once on boot before localdisplay.service starts
#
################################################################################

set -e

LOG_FILE="/var/log/auto-fix-display.log"
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log "=== AUTO-FIX DISPLAY START ==="

# Check if service file exists
SERVICE_FILE="/lib/systemd/system/localdisplay.service"
if [ ! -f "$SERVICE_FILE" ]; then
    log "⚠️  Service file missing, creating..."
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
    systemctl daemon-reload
    systemctl enable localdisplay.service 2>/dev/null || true
fi

# Ensure scripts exist
if [ ! -f "/usr/local/bin/xserver-ready.sh" ]; then
    log "Creating xserver-ready.sh..."
    cat > "/usr/local/bin/xserver-ready.sh" << 'EOF'
#!/bin/bash
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
fi

if [ ! -f "/usr/local/bin/start-chromium-clean.sh" ]; then
    log "Creating start-chromium-clean.sh..."
    # Copy from backup location if exists, otherwise create
    if [ -f "/usr/local/bin/start-chromium-clean.sh.backup" ]; then
        cp /usr/local/bin/start-chromium-clean.sh.backup /usr/local/bin/start-chromium-clean.sh
        chmod +x /usr/local/bin/start-chromium-clean.sh
    else
        # Create minimal version
        cat > "/usr/local/bin/start-chromium-clean.sh" << 'EOF'
#!/bin/bash
export DISPLAY=:0
export XAUTHORITY=/home/andre/.Xauthority
/usr/local/bin/xserver-ready.sh || exit 1
xhost +SI:localuser:andre 2>/dev/null || true
sleep 1
pkill -9 chromium 2>/dev/null || true
pkill -9 chromium-browser 2>/dev/null || true
sleep 2
rm -rf /tmp/chromium-data/Singleton* 2>/dev/null || true
chromium-browser --kiosk --no-sandbox --user-data-dir=/tmp/chromium-data http://localhost >/dev/null 2>&1 &
EOF
        chmod +x /usr/local/bin/start-chromium-clean.sh
    fi
fi

# Ensure user exists
if ! id -u andre &>/dev/null; then
    log "Creating user andre..."
    useradd -m -s /bin/bash -u 1000 -g 1000 andre 2>/dev/null || {
        groupadd -g 1000 andre 2>/dev/null || true
        useradd -m -s /bin/bash -u 1000 -g 1000 andre
    }
    usermod -aG audio,video,spi,i2c,gpio,plugdev,sudo andre 2>/dev/null || true
    echo "andre:0815" | chpasswd 2>/dev/null || true
fi

# Set permissions
chown -R andre:andre /home/andre 2>/dev/null || true
chmod +x /usr/local/bin/*.sh 2>/dev/null || true

log "✅ Auto-fix complete"
log "=== AUTO-FIX DISPLAY END ==="

