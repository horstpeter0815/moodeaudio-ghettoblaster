#!/bin/bash
#
# Check moOde Display Status
# Diagnose why display might not be showing
#

PI_HOST="moode.local"
PI_USER="andre"

echo "=========================================="
echo "MOODE DISPLAY STATUS CHECK"
echo "=========================================="
echo ""

# Check network
if ! ping -c 1 "$PI_HOST" &>/dev/null; then
    echo "❌ Cannot reach $PI_HOST"
    exit 1
fi

echo "1. Display Service Status:"
echo "   ssh $PI_USER@$PI_HOST 'sudo systemctl status localdisplay'"
echo ""

echo "2. Service Active Check:"
ssh -o StrictHostKeyChecking=no "$PI_USER@$PI_HOST" "sudo systemctl is-active localdisplay" 2>&1 || echo "   ⚠️  Service not active"

echo ""
echo "3. Chromium Process:"
CHROMIUM=$(ssh -o StrictHostKeyChecking=no "$PI_USER@$PI_HOST" "ps aux | grep -i chromium | grep -v grep | wc -l" 2>&1)
if [ "$CHROMIUM" -gt 0 ]; then
    echo "   ✅ Chromium running ($CHROMIUM processes)"
    ssh -o StrictHostKeyChecking=no "$PI_USER@$PI_HOST" "ps aux | grep -i chromium | grep -v grep | head -2" 2>&1
else
    echo "   ❌ Chromium NOT running"
fi

echo ""
echo "4. X Server Status:"
X_SERVER=$(ssh -o StrictHostKeyChecking=no "$PI_USER@$PI_HOST" "ps aux | grep -E 'Xorg|X ' | grep -v grep | wc -l" 2>&1)
if [ "$X_SERVER" -gt 0 ]; then
    echo "   ✅ X Server running"
else
    echo "   ❌ X Server NOT running"
fi

echo ""
echo "5. Recent Display Service Logs:"
echo "   ssh $PI_USER@$PI_HOST 'sudo journalctl -u localdisplay -n 30 --no-pager'"
echo ""

echo "6. Display Configuration:"
ssh -o StrictHostKeyChecking=no "$PI_USER@$PI_HOST" "cat /home/andre/.xinitrc | grep -E 'chromium|SCREEN|xrandr' | head -5" 2>&1 || echo "   ⚠️  Cannot read .xinitrc"

echo ""
echo "=========================================="
echo "QUICK FIXES:"
echo "=========================================="
echo ""
echo "Restart display:"
echo "  ssh $PI_USER@$PI_HOST"
echo "  sudo systemctl restart localdisplay"
echo ""
echo "Check logs:"
echo "  sudo journalctl -u localdisplay -n 50"
echo ""
echo "Check if display is enabled in database:"
echo "  sqlite3 /var/local/www/db/moode-sqlite3.db \"SELECT value FROM cfg_system WHERE param='local_display';\""
echo ""
