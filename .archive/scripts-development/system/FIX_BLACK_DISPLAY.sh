#!/bin/bash
# Fix Black Display / Login Screen Issue
# Run from HOME: bash ~/moodeaudio-cursor/scripts/system/FIX_BLACK_DISPLAY.sh

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  🔧 Fix Black Display / Login Screen                        ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

PI_IP="${1:-192.168.1.159}"
PI_USER="${2:-andre}"

echo "Target Pi: $PI_USER@$PI_IP"
echo ""

# Check connectivity
if ! ping -c 1 -W 2 "$PI_IP" > /dev/null 2>&1; then
    echo "❌ Cannot reach Pi at $PI_IP"
    exit 1
fi

echo "✅ Pi is reachable"
echo ""

ssh "$PI_USER@$PI_IP" << 'ENDSSH'
    echo "=== Diagnosing Display Issue ==="
    echo ""
    
    # 1. Check Chromium process
    echo "1. Checking Chromium process..."
    if pgrep -f chromium > /dev/null; then
        echo "   ✅ Chromium is running"
        ps aux | grep -E "chromium|chromium-browser" | grep -v grep | head -3
    else
        echo "   ❌ Chromium is NOT running"
    fi
    echo ""
    
    # 2. Check X11 display
    echo "2. Checking X11 display..."
    if [ -n "$DISPLAY" ] || DISPLAY=:0 xdpyinfo > /dev/null 2>&1; then
        echo "   ✅ X11 is running"
        DISPLAY=:0 xdpyinfo 2>/dev/null | grep -E "dimensions|name of display" | head -2
    else
        echo "   ❌ X11 display not accessible"
    fi
    echo ""
    
    # 3. Check web server
    echo "3. Checking web server..."
    if systemctl is-active --quiet apache2 2>/dev/null || systemctl is-active --quiet nginx 2>/dev/null; then
        echo "   ✅ Web server is running"
        systemctl status apache2 --no-pager -l 2>/dev/null | head -3 || \
        systemctl status nginx --no-pager -l 2>/dev/null | head -3
    else
        echo "   ❌ Web server is NOT running"
    fi
    echo ""
    
    # 4. Check localdisplay service
    echo "4. Checking localdisplay service..."
    if systemctl is-active --quiet localdisplay.service 2>/dev/null; then
        echo "   ✅ localdisplay.service is active"
        systemctl status localdisplay.service --no-pager -l | head -10
    else
        echo "   ❌ localdisplay.service is NOT active"
        systemctl status localdisplay.service --no-pager -l | head -10
    fi
    echo ""
    
    # 5. Check Chromium logs
    echo "5. Checking Chromium logs..."
    if [ -f "/var/log/chromium-clean.log" ]; then
        echo "   Recent errors:"
        tail -20 /var/log/chromium-clean.log | grep -i error || echo "   (no errors found)"
    else
        echo "   ⚠️  Log file not found"
    fi
    echo ""
    
    # 6. Check if login screen is blocking
    echo "6. Checking for login screen..."
    if DISPLAY=:0 xwininfo -root -tree 2>/dev/null | grep -qi "login\|lightdm\|gdm"; then
        echo "   ⚠️  Login screen detected"
        DISPLAY=:0 xwininfo -root -tree 2>/dev/null | grep -i "login\|lightdm\|gdm" | head -3
    else
        echo "   ✅ No login screen detected"
    fi
    echo ""
    
    # 7. Check display resolution
    echo "7. Checking display resolution..."
    if DISPLAY=:0 xrandr --query 2>/dev/null; then
        echo "   ✅ xrandr working"
    else
        echo "   ❌ xrandr not working"
    fi
    echo ""
    
    echo "=== Suggested Fixes ==="
    echo ""
    echo "If Chromium is not running:"
    echo "  sudo systemctl restart localdisplay.service"
    echo ""
    echo "If web server is not running:"
    echo "  sudo systemctl restart apache2"
    echo ""
    echo "If login screen is blocking:"
    echo "  sudo systemctl disable lightdm  # if using lightdm"
    echo "  sudo systemctl disable gdm       # if using gdm"
    echo ""
    echo "To manually start Chromium:"
    echo "  DISPLAY=:0 /usr/local/bin/start-chromium-clean.sh"
    echo ""
    
ENDSSH

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔧 Quick Fix Commands:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "1. Restart display service:"
echo "   ssh $PI_USER@$PI_IP 'sudo systemctl restart localdisplay.service'"
echo ""
echo "2. Restart Chromium manually:"
echo "   ssh $PI_USER@$PI_IP 'DISPLAY=:0 /usr/local/bin/start-chromium-clean.sh'"
echo ""
echo "3. Check Chromium logs:"
echo "   ssh $PI_USER@$PI_IP 'tail -50 /var/log/chromium-clean.log'"
echo ""
echo "4. Disable login screen (if blocking):"
echo "   ssh $PI_USER@$PI_IP 'sudo systemctl disable lightdm gdm'"
echo ""
