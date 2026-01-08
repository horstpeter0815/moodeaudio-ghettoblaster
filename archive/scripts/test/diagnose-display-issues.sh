#!/bin/bash
# Comprehensive display diagnosis for all systems

echo "=========================================="
echo "COMPREHENSIVE DISPLAY DIAGNOSIS"
echo "=========================================="
echo ""

# System 1
echo "=== SYSTEM 1 (HiFiBerryOS Pi 4) ==="
if ping -c 1 -W 1000 192.168.178.199 >/dev/null 2>&1; then
    ssh pi1 << 'EOF'
echo "Display processes:"
ps aux | grep -E 'weston|cog' | grep -v grep
echo ""
echo "Display info:"
cat /sys/class/graphics/fb0/virtual_size 2>/dev/null
echo ""
echo "Web UI URL:"
ps aux | grep cog | grep -v grep | grep -o 'http://[^ ]*' | head -1
EOF
else
    echo "❌ Offline"
fi
echo ""

# System 2
echo "=== SYSTEM 2 (moOde Pi 5) ==="
if ping -c 1 -W 1000 192.168.178.134 >/dev/null 2>&1; then
    ssh pi2 << 'EOF'
export DISPLAY=:0
echo "Display resolution:"
xrandr --query | grep -E 'connected|current'
echo ""
echo "Chromium status:"
ps aux | grep chromium | grep -v grep | wc -l | xargs echo "Processes:"
echo ""
echo "Chromium window:"
xdotool search --class Chromium 2>/dev/null | head -1 || echo "No window found"
echo ""
echo "Web server:"
curl -s -o /dev/null -w "HTTP Status: %{http_code}\n" http://localhost
EOF
else
    echo "❌ Offline"
fi
echo ""

# System 3
echo "=== SYSTEM 3 (moOde Pi 4) ==="
if ping -c 1 -W 1000 moodepi4.local >/dev/null 2>&1; then
    ssh pi3 << 'EOF'
export DISPLAY=:0
echo "Localdisplay service:"
systemctl is-active localdisplay
echo ""
echo "Display resolution:"
xrandr --query | grep -E 'connected|current'
echo ""
echo "Chromium status:"
ps aux | grep chromium | grep -v grep | wc -l | xargs echo "Processes:"
echo ""
echo "X server:"
ps aux | grep -E 'Xorg|X ' | grep -v grep | head -1
echo ""
echo "Web server:"
curl -s -o /dev/null -w "HTTP Status: %{http_code}\n" http://localhost
EOF
else
    echo "❌ Offline"
fi
echo ""

echo "=========================================="
echo "Please describe what you see on the displays:"
echo "- Black screen?"
echo "- Wrong resolution?"
echo "- Web UI not loading?"
echo "- Something else?"
echo "=========================================="

