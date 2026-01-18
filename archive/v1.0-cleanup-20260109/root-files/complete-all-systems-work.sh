#!/bin/bash
# COMPLETE ALL SYSTEMS WORK
# Following project plan - no stopping

set -e

echo "=========================================="
echo "COMPLETE ALL SYSTEMS WORK"
echo "Following project plan - systematic approach"
echo "Date: $(date)"
echo "=========================================="
echo ""

# Function to check and fix Pi 5
check_and_fix_pi5() {
    echo "=== PI 5 (pi2) - Moode Audio ==="
    if ping -c 1 -W 2000 192.168.178.134 >/dev/null 2>&1; then
        if ssh -o ConnectTimeout=5 pi2 "uptime" >/dev/null 2>&1; then
            echo "✅ Pi 5 is online - applying comprehensive fix..."
            ./pi5-complete-thorough-fix.sh 2>&1 | tee "pi5-fix-$(date +%Y%m%d-%H%M%S).log"
            return 0
        fi
    fi
    echo "⏳ Pi 5 not online yet - will retry"
    return 1
}

# Function to check HiFiBerry Pi 4 (pi3)
check_hifiberry_pi4() {
    echo ""
    echo "=== HIFIBERRY PI 4 (pi3) - Status Check ==="
    if ssh -o ConnectTimeout=5 pi3 "uptime" >/dev/null 2>&1; then
        echo "✅ HiFiBerry Pi 4 is online"
        ssh pi3 << 'HIFICHECK'
export DISPLAY=:0 2>/dev/null || true

echo "System status:"
uptime

echo ""
echo "Display status:"
xrandr --query 2>/dev/null | grep "HDMI-2" || echo "No display detected"

echo ""
echo "Display service:"
systemctl is-active localdisplay && echo "✅ Active" || echo "⚠️ Not active"

echo ""
echo "Config check:"
sudo grep -E "display_rotate|hdmi_group" /boot/firmware/config.txt 2>/dev/null | grep -v "^#" | head -3

echo ""
echo "✅ HiFiBerry Pi 4 check complete"
HIFICHECK
        return 0
    else
        echo "⚠️ HiFiBerry Pi 4 not accessible"
        return 1
    fi
}

# Function to check other Pi 4 (pi4)
check_other_pi4() {
    echo ""
    echo "=== OTHER PI 4 (pi4) - Status Check ==="
    if ssh -o ConnectTimeout=5 pi4 "uptime" >/dev/null 2>&1; then
        echo "✅ Other Pi 4 is online"
        ssh pi4 << 'PI4CHECK'
export DISPLAY=:0 2>/dev/null || true

echo "System status:"
uptime

echo ""
echo "Display status:"
xrandr --query 2>/dev/null | grep "connected" || echo "No display detected"

echo ""
echo "Display service:"
systemctl is-active localdisplay && echo "✅ Active" || echo "⚠️ Not active"

echo ""
echo "✅ Other Pi 4 check complete"
PI4CHECK
        return 0
    else
        echo "⚠️ Other Pi 4 not accessible"
        return 1
    fi
}

# Main execution loop
echo "Starting systematic check of all systems..."
echo ""

# Try Pi 5 fix (with retries)
PI5_FIXED=false
for attempt in {1..20}; do
    if check_and_fix_pi5; then
        PI5_FIXED=true
        break
    fi
    echo "Waiting for Pi 5... (attempt $attempt/20)"
    sleep 10
done

# Check other systems
check_hifiberry_pi4
check_other_pi4

echo ""
echo "=========================================="
echo "SYSTEM CHECK COMPLETE"
echo "=========================================="
echo ""
echo "Summary:"
if [ "$PI5_FIXED" = true ]; then
    echo "  ✅ Pi 5: Fixed"
else
    echo "  ⏳ Pi 5: Waiting for system to come online"
fi

echo ""
echo "Next: Continuing to monitor and fix as systems come online..."

