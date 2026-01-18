#!/bin/bash
# Apply Display Persistence Fix to Running System
# Run this on the Pi to fix display persistence issues immediately

set -euo pipefail

echo "=== APPLYING DISPLAY PERSISTENCE FIX ==="
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "❌ Please run as root (use sudo)"
    exit 1
fi

# Copy script to /usr/local/bin
SCRIPT_SOURCE="$(dirname "$0")/persist-display-config.sh"
if [ -f "$SCRIPT_SOURCE" ]; then
    echo "1. Installing persist-display-config.sh..."
    cp "$SCRIPT_SOURCE" /usr/local/bin/
    chmod +x /usr/local/bin/persist-display-config.sh
    echo "✅ Script installed"
else
    echo "⚠️  Script not found at $SCRIPT_SOURCE"
    echo "   Make sure you're running from the project directory"
    exit 1
fi

# Copy service file
SERVICE_SOURCE="$(dirname "$0")/../../moode-source/lib/systemd/system/persist-display-config.service"
if [ -f "$SERVICE_SOURCE" ]; then
    echo "2. Installing persist-display-config.service..."
    cp "$SERVICE_SOURCE" /lib/systemd/system/
    echo "✅ Service installed"
else
    echo "⚠️  Service file not found at $SERVICE_SOURCE"
    echo "   Creating service file..."
    cat > /lib/systemd/system/persist-display-config.service <<'EOF'
[Unit]
Description=Persistent Display Configuration Fix
After=local-fs.target sound.target mpd.service
Wants=local-fs.target
# Run after moOde worker.php (which runs early via moode-player.service)
After=moode-player.service
# But don't block boot
Before=graphical.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/persist-display-config.sh
RemainAfterExit=yes
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF
    echo "✅ Service file created"
fi

# Enable and start service
echo "3. Enabling and starting service..."
systemctl daemon-reload
systemctl enable persist-display-config.service
systemctl start persist-display-config.service
echo "✅ Service enabled and started"

# Run script immediately to fix current settings
echo "4. Running fix script now..."
/usr/local/bin/persist-display-config.sh

echo ""
echo "✅✅✅ DISPLAY PERSISTENCE FIX APPLIED ✅✅✅"
echo ""
echo "The display configuration will now persist across reboots."
echo "Check logs with: sudo journalctl -u persist-display-config.service"
echo ""
