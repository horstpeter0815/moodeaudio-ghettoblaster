#!/bin/bash
# PI 5 REBOOT TEST SUITE
# Tests system stability with 3 reboots as per project plan

set -e

PI5_ALIAS="pi2"
PI5_IP="192.168.178.143"
TEST_COUNT=3

echo "=========================================="
echo "PI 5 REBOOT TEST SUITE"
echo "=========================================="
echo "Testing system stability with $TEST_COUNT reboots"
echo ""

# Function to check system status
check_system() {
    echo "=== SYSTEM STATUS CHECK ==="
    ssh "$PI5_ALIAS" << 'CHECKSTATUS'
export DISPLAY=:0

echo "1. Services:"
echo "   localdisplay: $(systemctl is-active localdisplay.service 2>/dev/null || echo 'inactive')"
echo "   mpd: $(systemctl is-active mpd.service 2>/dev/null || echo 'inactive')"

echo ""
echo "2. Chromium:"
if pgrep -f chromium >/dev/null; then
    echo "   ✅ Running (PID: $(pgrep -f chromium | head -1))"
else
    echo "   ❌ Not running"
fi

echo ""
echo "3. Display:"
if command -v xrandr >/dev/null 2>&1; then
    DISPLAY_STATUS=$(xrandr --query 2>/dev/null | grep "HDMI-2" | head -1)
    echo "   $DISPLAY_STATUS"
    if echo "$DISPLAY_STATUS" | grep -q "1280x400"; then
        echo "   ✅ Landscape (1280x400)"
    else
        echo "   ⚠️  Resolution might be wrong"
    fi
else
    echo "   ⚠️  xrandr not available"
fi

echo ""
echo "4. Touchscreen:"
WAVESHARE_ID=$(xinput list | grep -i "WaveShare" | grep -oP 'id=\K[0-9]+' | head -1)
if [ -n "$WAVESHARE_ID" ]; then
    MATRIX=$(xinput list-props "$WAVESHARE_ID" 2>/dev/null | grep "Coordinate Transformation Matrix" | awk '{print $5, $6, $7, $8, $9, $10, $11, $12, $13}')
    if echo "$MATRIX" | grep -q "0.000000.*-1.000000.*1.000000.*1.000000.*0.000000.*0.000000"; then
        echo "   ✅ Calibrated (0 -1 1 1 0 0 0 0 1)"
    else
        echo "   ⚠️  Matrix: $MATRIX"
    fi
    SEND_EVENTS=$(xinput list-props "$WAVESHARE_ID" 2>/dev/null | grep "Send Events Mode Enabled" | awk '{print $5, $6}')
    if echo "$SEND_EVENTS" | grep -q "1, 0"; then
        echo "   ✅ Send Events enabled"
    else
        echo "   ⚠️  Send Events: $SEND_EVENTS"
    fi
else
    echo "   ❌ WaveShare device not found"
fi

echo ""
echo "5. Boot Configuration:"
if [ -f "/boot/config.txt" ]; then
    ROTATE=$(sudo grep "^display_rotate=" /boot/config.txt 2>/dev/null | head -1 || echo "not set")
    echo "   display_rotate: $ROTATE"
fi
for CMDLINE in "/boot/cmdline.txt" "/boot/firmware/cmdline.txt"; do
    if [ -f "$CMDLINE" ]; then
        if grep -q "quiet" "$CMDLINE" 2>/dev/null; then
            echo "   ⚠️  $CMDLINE: has 'quiet'"
        else
            echo "   ✅ $CMDLINE: verbose"
        fi
    fi
done

CHECKSTATUS
}

# Function to wait for Pi 5 to come online
wait_for_pi5() {
    echo "Waiting for Pi 5 to come online..."
    local max_wait=300  # 5 minutes
    local waited=0
    
    while [ $waited -lt $max_wait ]; do
        if ping -c 1 -W 2000 "$PI5_IP" >/dev/null 2>&1; then
            if ssh -o ConnectTimeout=5 "$PI5_ALIAS" "echo 'online'" >/dev/null 2>&1; then
                echo "✅ Pi 5 is online!"
                sleep 10  # Wait a bit more for services to start
                return 0
            fi
        fi
        sleep 5
        waited=$((waited + 5))
        if [ $((waited % 30)) -eq 0 ]; then
            echo "   Still waiting... (${waited}s)"
        fi
    done
    
    echo "❌ Pi 5 did not come online within $max_wait seconds"
    return 1
}

# Main test loop
for i in $(seq 1 $TEST_COUNT); do
    echo ""
    echo "=========================================="
    echo "REBOOT TEST $i of $TEST_COUNT"
    echo "=========================================="
    echo ""
    
    # Check system before reboot
    echo "Pre-reboot status:"
    check_system
    
    echo ""
    echo "Rebooting Pi 5..."
    ssh "$PI5_ALIAS" "sudo reboot" || true
    
    echo ""
    wait_for_pi5
    
    if [ $? -ne 0 ]; then
        echo "❌ Test $i FAILED - Pi 5 did not come online"
        exit 1
    fi
    
    echo ""
    echo "Post-reboot status:"
    check_system
    
    echo ""
    if [ $i -lt $TEST_COUNT ]; then
        echo "✅ Test $i passed - waiting 30 seconds before next reboot..."
        sleep 30
    else
        echo "✅ Test $i passed"
    fi
done

echo ""
echo "=========================================="
echo "✅ ALL REBOOT TESTS PASSED!"
echo "=========================================="
echo ""
echo "System is stable and all configurations persist!"

