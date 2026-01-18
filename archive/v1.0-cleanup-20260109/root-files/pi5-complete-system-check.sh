#!/bin/bash
# COMPLETE PI 5 SYSTEM CHECK
# Checks all aspects of the system and reports status

set -e

PI5_ALIAS="pi2"
PI5_IP="192.168.178.134"

echo "=========================================="
echo "PI 5 COMPLETE SYSTEM CHECK"
echo "=========================================="
echo ""

# Check if Pi 5 is online
echo -n "Checking if Pi 5 is online... "
if ! ping -c 1 -W 2000 "$PI5_IP" >/dev/null 2>&1; then
    echo "❌ OFFLINE"
    echo ""
    echo "Pi 5 is not reachable. Please wait for it to boot."
    exit 1
fi

if ! ssh -o ConnectTimeout=5 "$PI5_ALIAS" "echo 'online'" >/dev/null 2>&1; then
    echo "❌ SSH NOT AVAILABLE"
    echo ""
    echo "Pi 5 is online but SSH is not ready yet."
    exit 1
fi

echo "✅ ONLINE"
echo ""

# Run comprehensive check
ssh "$PI5_ALIAS" << 'SYSTEMCHECK'
export DISPLAY=:0

echo "=== SYSTEM INFORMATION ==="
echo "Hostname: $(hostname)"
echo "Uptime: $(uptime -p)"
echo "OS: $(cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)"
echo ""

echo "=== DISPLAY CONFIGURATION ==="
echo "1. Boot Configuration:"
for CONFIG in "/boot/config.txt" "/boot/firmware/config.txt"; do
    if [ -f "$CONFIG" ]; then
        echo "   $CONFIG:"
        ROTATE=$(sudo grep "^display_rotate=" "$CONFIG" 2>/dev/null | head -1 || echo "not set")
        GROUP=$(sudo grep "^hdmi_group=" "$CONFIG" 2>/dev/null | head -1 || echo "not set")
        echo "     display_rotate: $ROTATE"
        echo "     hdmi_group: $GROUP"
    fi
done

echo ""
echo "2. Current Display Status:"
if command -v xrandr >/dev/null 2>&1; then
    xrandr --query 2>/dev/null | grep "HDMI-2" | head -1 || echo "   (X server not running)"
else
    echo "   (xrandr not available)"
fi

echo ""
echo "3. Framebuffer:"
if [ -f "/sys/class/graphics/fb0/virtual_size" ]; then
    FB_SIZE=$(cat /sys/class/graphics/fb0/virtual_size)
    echo "   Resolution: $FB_SIZE"
else
    echo "   (framebuffer info not available)"
fi

echo ""
echo "=== SERVICES STATUS ==="
echo "localdisplay.service: $(systemctl is-active localdisplay.service 2>/dev/null || echo 'inactive')"
echo "mpd.service: $(systemctl is-active mpd.service 2>/dev/null || echo 'inactive')"
echo "weston.service: $(systemctl is-active weston.service 2>/dev/null || echo 'inactive')"

echo ""
echo "=== APPLICATIONS ==="
if pgrep -f chromium >/dev/null; then
    CHROMIUM_PID=$(pgrep -f chromium | head -1)
    echo "✅ Chromium: Running (PID: $CHROMIUM_PID)"
else
    echo "❌ Chromium: Not running"
fi

echo ""
echo "=== BOOT CONFIGURATION ==="
echo "Boot Prompts:"
for CMDLINE in "/boot/cmdline.txt" "/boot/firmware/cmdline.txt"; do
    if [ -f "$CMDLINE" ]; then
        if grep -q "quiet" "$CMDLINE" 2>/dev/null; then
            echo "   ❌ $CMDLINE: Has 'quiet' (prompts hidden)"
        else
            echo "   ✅ $CMDLINE: Verbose (prompts visible)"
        fi
        if grep -q "systemd.show_status" "$CMDLINE" 2>/dev/null; then
            echo "   ✅ $CMDLINE: Has systemd.show_status"
        fi
    fi
done

echo ""
echo "=== TOUCHSCREEN ==="
if command -v xinput >/dev/null 2>&1; then
    TOUCH_DEVICES=$(xinput list 2>/dev/null | grep -i touch || echo "No touch devices found")
    echo "$TOUCH_DEVICES"
else
    echo "   (xinput not available)"
fi

echo ""
echo "=== NETWORK ==="
echo "IP Address: $(hostname -I | awk '{print $1}')"
echo "Hostname: $(hostname)"

echo ""
echo "=== DISK SPACE ==="
df -h / | tail -1 | awk '{print "Root: " $4 " free of " $2 " (" $5 " used)"}'

echo ""
echo "=========================================="
echo "SYSTEM CHECK COMPLETE"
echo "=========================================="

SYSTEMCHECK

echo ""
echo "✅ Complete system check finished!"

