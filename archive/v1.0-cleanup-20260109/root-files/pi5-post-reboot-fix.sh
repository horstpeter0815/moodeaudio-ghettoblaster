#!/bin/bash
# Post-Reboot Fix Script for Pi 5
# Fixes PeppyMeter service and verifies all systems

PI5_ALIAS="pi2"
PI5_IP="192.168.178.143"

echo "=========================================="
echo "PI 5 POST-REBOOT FIX"
echo "=========================================="
echo ""

# Wait for Pi 5 to come online
echo "Waiting for Pi 5 to come online..."
for i in {1..60}; do
    if ping -c 1 -W 1000 "$PI5_IP" >/dev/null 2>&1; then
        if ssh -o ConnectTimeout=5 "$PI5_ALIAS" "echo 'Online!'" >/dev/null 2>&1; then
            echo "✅ Pi 5 is online!"
            break
        fi
    fi
    echo -n "."
    sleep 5
done

echo ""
echo "Applying fixes..."

ssh "$PI5_ALIAS" << 'POSTREBOOTFIX'
export DISPLAY=:0

echo "=== POST-REBOOT FIXES ==="
echo ""

echo "1. Fixing PeppyMeter service (removing duplicate ExecStart):"
sudo tee /etc/systemd/system/peppymeter.service.d/override.conf > /dev/null << 'PEPPY_FIX'
[Unit]
Requires=localdisplay.service mpd.service
After=localdisplay.service mpd.service

[Service]
Type=simple
User=andre
Group=andre
TimeoutStartSec=60
Environment=DISPLAY=:0
Environment=XAUTHORITY=/home/andre/.Xauthority
ExecStartPre=/bin/bash -c "for i in {1..30}; do [ -S /tmp/.X11-unix/X0 ] && mpc status >/dev/null 2>&1 && exit 0; sleep 1; done; exit 1"
ExecStart=/usr/local/bin/peppymeter-wrapper.sh
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal
PEPPY_FIX

sudo systemctl daemon-reload
echo "   ✅ PeppyMeter service fixed"

echo ""
echo "2. Starting PeppyMeter:"
sudo systemctl start peppymeter.service
sleep 5

echo ""
echo "3. System Status:"
echo "   Display: $(xrandr --query 2>/dev/null | grep 'HDMI-2' | head -1 | awk '{print $3, $4}')"
echo "   localdisplay: $(systemctl is-active localdisplay.service 2>/dev/null || echo 'inactive')"
echo "   mpd: $(systemctl is-active mpd.service 2>/dev/null || echo 'inactive')"
echo "   peppymeter: $(systemctl is-active peppymeter.service 2>/dev/null || echo 'inactive')"
echo "   chromium: $(pgrep -f chromium >/dev/null && echo 'running' || echo 'not running')"

echo ""
echo "4. Touchscreen:"
WAVESHARE_ID=$(xinput list | grep -i "WaveShare" | grep -oP 'id=\K[0-9]+' | head -1)
if [ -n "$WAVESHARE_ID" ]; then
    echo "   ✅ WaveShare detected (id=$WAVESHARE_ID)"
    SEND_EVENTS=$(xinput list-props "$WAVESHARE_ID" 2>/dev/null | grep "Send Events Mode Enabled" | awk '{print $NF}')
    echo "   Send Events Mode: $SEND_EVENTS"
    if [ "$SEND_EVENTS" != "1, 0" ]; then
        echo "   ⚠️ Re-enabling Send Events Mode..."
        xinput enable "$WAVESHARE_ID"
        xinput set-prop "$WAVESHARE_ID" "libinput Send Events Mode Enabled" 1 0
    fi
else
    echo "   ⚠️ WaveShare not found"
fi

echo ""
echo "5. Boot Configuration Verification:"
echo "   display_rotate: $(sudo grep '^display_rotate=' /boot/firmware/config.txt 2>/dev/null | cut -d= -f2)"

echo ""
echo "✅ Post-reboot fixes applied!"

POSTREBOOTFIX

echo ""
echo "=========================================="
echo "POST-REBOOT FIX COMPLETE"
echo "=========================================="

