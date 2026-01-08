#!/bin/bash
# Quick Status Check - Moode Display

echo "=========================================="
echo "Moode Display Status"
echo "=========================================="
echo ""

# X11 Status
echo "X11:"
if pgrep -x "X" > /dev/null || pgrep -x "Xorg" > /dev/null; then
    echo "  ✅ Running (PID: $(pgrep -x X || pgrep -x Xorg))"
    export DISPLAY=:0
else
    echo "  ❌ NOT running"
fi
echo ""

# Chromium Status
echo "Chromium:"
if pgrep -f "chromium" > /dev/null; then
    echo "  ✅ Running (PID: $(pgrep -f chromium | head -1))"
else
    echo "  ❌ NOT running"
fi
echo ""

# xinitrc Status
echo "xinitrc:"
if [ -f "$HOME/.xinitrc" ]; then
    if grep -q "chromium" "$HOME/.xinitrc"; then
        echo "  ✅ Exists and has Chromium"
    else
        echo "  ⚠️  Exists but missing Chromium"
    fi
else
    echo "  ❌ Missing!"
fi
echo ""

# Moode Web Server
echo "Moode Web Server:"
if systemctl is-active --quiet moode 2>/dev/null; then
    echo "  ✅ Running"
    if curl -s http://localhost/ > /dev/null 2>&1; then
        echo "  ✅ Accessible at http://localhost/"
    else
        echo "  ⚠️  Not accessible"
    fi
else
    echo "  ❌ NOT running"
fi
echo ""

# Display Manager
echo "Display Manager:"
if systemctl is-active --quiet lightdm 2>/dev/null; then
    echo "  ⚠️  LightDM running (may show login screen)"
elif systemctl is-active --quiet gdm 2>/dev/null; then
    echo "  ⚠️  GDM running (may show login screen)"
else
    echo "  ✅ No display manager (good)"
fi
echo ""

# Summary
echo "=========================================="
echo "Summary"
echo "=========================================="

X11_RUNNING=$(pgrep -x X > /dev/null || pgrep -x Xorg > /dev/null && echo "yes" || echo "no")
CHROMIUM_RUNNING=$(pgrep -f chromium > /dev/null && echo "yes" || echo "no")

if [ "$X11_RUNNING" = "yes" ] && [ "$CHROMIUM_RUNNING" = "yes" ]; then
    echo "✅ Moode Display should be working!"
elif [ "$X11_RUNNING" = "no" ]; then
    echo "❌ X11 not running - run: startx or ./fix_login_screen.sh"
elif [ "$CHROMIUM_RUNNING" = "no" ]; then
    echo "❌ Chromium not running - run: ./fix_login_screen.sh"
else
    echo "⚠️  Something is wrong - run: ./fix_login_screen.sh"
fi
echo ""

