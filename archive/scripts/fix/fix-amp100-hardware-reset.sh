#!/bin/bash
# Fix AMP100 with Hardware Reset (like HiFiBerry test script)
# Performs hardware reset via GPIO before driver loads

echo "=== FIXING AMP100 WITH HARDWARE RESET ==="
echo ""

PI5_ALIAS="pi2"

if ! ssh -o ConnectTimeout=5 "$PI5_ALIAS" "echo 'Online'" >/dev/null 2>&1; then
    echo "❌ Pi 5 is not online."
    exit 1
fi

echo "✅ Pi 5 is online"
echo ""

# Create systemd service for hardware reset
echo "1. Creating hardware reset service..."
ssh "$PI5_ALIAS" "sudo tee /etc/systemd/system/amp100-reset.service > /dev/null << 'SERVICE'
[Unit]
Description=AMP100 Hardware Reset
Before=mpd.service
After=local-fs.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/amp100-reset.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
SERVICE"

echo "   ✅ Service file created"
echo ""

# Create reset script (like HiFiBerry test script)
echo "2. Creating reset script..."
ssh "$PI5_ALIAS" "sudo tee /usr/local/bin/amp100-reset.sh > /dev/null << 'RESET_SCRIPT'
#!/bin/bash
# AMP100 Hardware Reset (like HiFiBerry test script)

# Export GPIO pins
echo 17 > /sys/class/gpio/export 2>/dev/null || true
echo 4  > /sys/class/gpio/export 2>/dev/null || true

# Set directions
echo out > /sys/class/gpio/gpio17/direction 2>/dev/null || true
echo out > /sys/class/gpio/gpio4/direction 2>/dev/null || true

# Mute
echo 1 > /sys/class/gpio/gpio4/value 2>/dev/null || true
sleep 0.1

# Reset (low then high)
echo 0 > /sys/class/gpio/gpio17/value 2>/dev/null || true
sleep 0.1
echo 1 > /sys/class/gpio/gpio17/value 2>/dev/null || true
sleep 0.5

# Unmute
echo 0 > /sys/class/gpio/gpio4/value 2>/dev/null || true

echo \"AMP100 hardware reset completed\"
RESET_SCRIPT
sudo chmod +x /usr/local/bin/amp100-reset.sh"

echo "   ✅ Reset script created"
echo ""

# Enable and start service
echo "3. Enabling reset service..."
ssh "$PI5_ALIAS" "sudo systemctl daemon-reload"
ssh "$PI5_ALIAS" "sudo systemctl enable amp100-reset.service"
ssh "$PI5_ALIAS" "sudo systemctl start amp100-reset.service"
sleep 2

echo "   ✅ Service enabled and started"
echo ""

# Check service status
echo "4. Service status:"
ssh "$PI5_ALIAS" "systemctl status amp100-reset.service --no-pager | head -8"
echo ""

# Test audio
echo "5. Testing audio hardware..."
ssh "$PI5_ALIAS" "sleep 2 && aplay -l 2>&1"
echo ""

echo "=========================================="
echo "AMP100 HARDWARE RESET APPLIED"
echo "=========================================="
echo ""
echo "If audio still not detected, may need reboot."
echo ""

