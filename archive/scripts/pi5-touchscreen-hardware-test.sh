#!/bin/bash
# Quick Touchscreen Hardware Test for Pi 5

PI5_ALIAS="pi2"

echo "=========================================="
echo "TOUCHSCREEN HARDWARE TEST"
echo "=========================================="
echo ""

ssh "$PI5_ALIAS" << 'HARDWARETEST'
export DISPLAY=:0

echo "1. Checking USB device:"
lsusb | grep -i "WaveShare\|0712" || echo "   ⚠️ WaveShare USB device not found in lsusb"

echo ""
echo "2. Checking input devices:"
ls -la /dev/input/event* 2>/dev/null | head -10

echo ""
echo "3. Checking if touchscreen device node exists:"
WAVESHARE_ID=$(xinput list | grep -i "WaveShare" | grep -oP 'id=\K[0-9]+' | head -1)
if [ -n "$WAVESHARE_ID" ]; then
    DEVICE_NODE=$(xinput list-props "$WAVESHARE_ID" 2>/dev/null | grep "Device Node" | awk '{print $NF}' | tr -d '"')
    echo "   Device Node: $DEVICE_NODE"
    if [ -n "$DEVICE_NODE" ] && [ -e "$DEVICE_NODE" ]; then
        echo "   ✅ Device node exists"
        ls -la "$DEVICE_NODE"
    else
        echo "   ❌ Device node does not exist"
    fi
else
    echo "   ❌ WaveShare device not found in xinput"
fi

echo ""
echo "4. Testing raw input events (touch the screen now for 5 seconds):"
if [ -n "$DEVICE_NODE" ] && [ -e "$DEVICE_NODE" ]; then
    echo "   Reading from $DEVICE_NODE..."
    timeout 5 hexdump -C "$DEVICE_NODE" 2>/dev/null | head -20 || echo "   No data received"
else
    echo "   ⚠️ Cannot test - device node not available"
fi

echo ""
echo "5. Testing with evtest (if available):"
if command -v evtest >/dev/null 2>&1; then
    if [ -n "$DEVICE_NODE" ] && [ -e "$DEVICE_NODE" ]; then
        echo "   Running evtest for 3 seconds (touch the screen):"
        timeout 3 evtest "$DEVICE_NODE" 2>&1 | head -30 || echo "   No events detected"
    fi
else
    echo "   evtest not installed (install with: sudo apt install evtest)"
fi

echo ""
echo "6. Checking kernel messages:"
dmesg | grep -i "WaveShare\|input\|touch\|0712" | tail -10

echo ""
echo "=========================================="
echo "TEST COMPLETE"
echo "=========================================="
echo ""
echo "If no events were detected:"
echo "  - Check USB cable connection"
echo "  - Try unplugging and replugging USB"
echo "  - Check if device appears in lsusb"
echo "  - Verify device node permissions"

HARDWARETEST

