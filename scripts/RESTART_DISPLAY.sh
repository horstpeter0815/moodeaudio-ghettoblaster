#!/bin/bash
#
# Restart moOde Local Display Service
# This restarts Chromium kiosk mode showing moOde UI
#

PI_HOST="moode.local"
PI_USER="andre"

echo "=========================================="
echo "RESTART MOODE DISPLAY"
echo "=========================================="
echo ""

echo "Connecting to $PI_HOST..."
echo ""

# Check if we can reach the Pi
if ! ping -c 1 "$PI_HOST" &>/dev/null; then
    echo "❌ Cannot reach $PI_HOST"
    echo "   Check network connection"
    exit 1
fi

echo "1. Checking display service status..."
ssh -o StrictHostKeyChecking=no "$PI_USER@$PI_HOST" "sudo systemctl status localdisplay --no-pager | head -15" 2>&1

echo ""
echo "2. Restarting display service..."
ssh -o StrictHostKeyChecking=no "$PI_USER@$PI_HOST" "sudo systemctl restart localdisplay" 2>&1

if [ $? -eq 0 ]; then
    echo "   ✅ Display service restarted"
else
    echo "   ❌ Failed to restart (may need password)"
    echo ""
    echo "   Run manually:"
    echo "   ssh $PI_USER@$PI_HOST"
    echo "   sudo systemctl restart localdisplay"
    exit 1
fi

echo ""
echo "3. Waiting 5 seconds for display to start..."
sleep 5

echo ""
echo "4. Checking if display is running..."
ssh -o StrictHostKeyChecking=no "$PI_USER@$PI_HOST" "sudo systemctl is-active localdisplay" 2>&1

echo ""
echo "5. Checking Chromium process..."
ssh -o StrictHostKeyChecking=no "$PI_USER@$PI_HOST" "ps aux | grep -i chromium | grep -v grep | head -3" 2>&1

echo ""
echo "=========================================="
echo "DONE"
echo "=========================================="
echo ""
echo "Display should be showing moOde UI now."
echo "If not, check:"
echo "  - HDMI cable connected"
echo "  - Display powered on"
echo "  - Run: ssh $PI_USER@$PI_HOST"
echo "  - Run: sudo journalctl -u localdisplay -n 50"
echo ""
