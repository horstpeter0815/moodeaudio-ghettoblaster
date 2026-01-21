#!/bin/bash
# Fix Black Display / Login Screen - Run directly on Pi
# Copy to Pi and run: bash FIX_BLACK_DISPLAY_PI.sh

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  🔧 Fix Black Display / Login Screen                        ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# 1. Check current status
echo "=== Current Status ==="
echo ""
echo "1. Login managers:"
systemctl is-active lightdm >/dev/null 2>&1 && echo "  ⚠️  lightdm: active" || echo "  ✅ lightdm: inactive"
systemctl is-active gdm >/dev/null 2>&1 && echo "  ⚠️  gdm: active" || echo "  ✅ gdm: inactive"
echo ""

echo "2. Chromium:"
pgrep -f chromium >/dev/null && echo "  ✅ Running (PID: $(pgrep -f chromium | head -1))" || echo "  ❌ Not running"
echo ""

echo "3. Display service:"
systemctl is-active localdisplay.service >/dev/null && echo "  ✅ Active" || echo "  ❌ Not active"
echo ""

echo "4. Web server:"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/ 2>/dev/null || echo "000")
if [ "$HTTP_CODE" = "200" ]; then
    echo "  ✅ Responding (HTTP $HTTP_CODE)"
else
    echo "  ❌ Not responding (HTTP $HTTP_CODE)"
fi
echo ""

# 2. Apply fixes
echo "=== Applying Fixes ==="
echo ""

echo "1. Disabling login managers..."
sudo systemctl disable lightdm gdm 2>/dev/null
sudo systemctl stop lightdm gdm 2>/dev/null
echo "   ✅ Login managers disabled and stopped"
echo ""

echo "2. Killing existing Chromium processes..."
pkill -9 chromium 2>/dev/null
pkill -9 chromium-browser 2>/dev/null
sleep 1
echo "   ✅ Chromium processes killed"
echo ""

echo "3. Restarting web server..."
sudo systemctl restart apache2 2>/dev/null || sudo systemctl restart nginx 2>/dev/null
sleep 2
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/ 2>/dev/null || echo "000")
if [ "$HTTP_CODE" = "200" ]; then
    echo "   ✅ Web server restarted and responding"
else
    echo "   ⚠️  Web server restarted but not responding yet (HTTP $HTTP_CODE)"
fi
echo ""

echo "4. Restarting display service..."
sudo systemctl restart localdisplay.service
echo "   ✅ Display service restarted"
echo ""

echo "5. Waiting for Chromium to start..."
sleep 5
for i in {1..10}; do
    if pgrep -f chromium >/dev/null; then
        echo "   ✅ Chromium started (PID: $(pgrep -f chromium | head -1))"
        break
    fi
    if [ $i -eq 10 ]; then
        echo "   ⚠️  Chromium not started automatically"
        echo "   Attempting manual start..."
        DISPLAY=:0 /usr/local/bin/start-chromium-clean.sh &
        sleep 3
        if pgrep -f chromium >/dev/null; then
            echo "   ✅ Chromium started manually"
        else
            echo "   ❌ Chromium failed to start"
            echo "   Check logs: tail -50 /var/log/chromium-clean.log"
        fi
    else
        sleep 1
    fi
done
echo ""

# 3. Final status
echo "=== Final Status ==="
echo ""
echo "Chromium:"
pgrep -f chromium >/dev/null && echo "  ✅ Running (PID: $(pgrep -f chromium | head -1))" || echo "  ❌ Not running"
echo ""

echo "Display service:"
systemctl is-active localdisplay.service >/dev/null && echo "  ✅ Active" || echo "  ❌ Not active"
echo ""

echo "Web server:"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/ 2>/dev/null || echo "000")
if [ "$HTTP_CODE" = "200" ]; then
    echo "  ✅ Responding (HTTP $HTTP_CODE)"
else
    echo "  ❌ Not responding (HTTP $HTTP_CODE)"
fi
echo ""

echo "Login managers:"
systemctl is-enabled lightdm >/dev/null 2>&1 && echo "  ⚠️  lightdm: enabled" || echo "  ✅ lightdm: disabled"
systemctl is-enabled gdm >/dev/null 2>&1 && echo "  ⚠️  gdm: enabled" || echo "  ✅ gdm: disabled"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if pgrep -f chromium >/dev/null; then
    echo "✅ Fix complete! Display should now show moOde web UI"
else
    echo "⚠️  Chromium not running. Check logs:"
    echo "   tail -50 /var/log/chromium-clean.log"
    echo "   journalctl -u localdisplay.service -n 50"
fi
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
