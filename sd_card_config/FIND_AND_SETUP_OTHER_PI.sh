#!/bin/bash

# FIND OTHER PI (Raspberry Pi OS) AND SETUP MOODE AUDIO
# With working touchscreen configuration

set -e

echo "=========================================="
echo "FINDING OTHER PI AND SETTING UP MOODE"
echo "=========================================="
echo ""

# Find Pi on network
PI_IP=""
LOCAL_IP=$(ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1 2>/dev/null)

if [ -n "$LOCAL_IP" ]; then
    NETWORK=$(echo "$LOCAL_IP" | cut -d. -f1-3)
    echo "Scanning ${NETWORK}.0/24 for Raspberry Pi..."
    
    for i in {1..100}; do
        IP="${NETWORK}.${i}"
        if timeout 0.5 ping -c 1 -W 0.3 "$IP" &>/dev/null; then
            # Try to connect as pi user (Raspberry Pi OS default)
            if timeout 2 ssh -o ConnectTimeout=1 -o StrictHostKeyChecking=no pi@"$IP" "cat /proc/device-tree/model 2>/dev/null | grep -i raspberry && echo 'Raspberry Pi found'" &>/dev/null; then
                PI_IP="$IP"
                echo "✓ Found Raspberry Pi at: $IP"
                break
            fi
        fi
    done
fi

if [ -z "$PI_IP" ]; then
    echo "❌ Could not find Raspberry Pi automatically"
    echo "Please provide IP address:"
    read -p "Pi IP: " PI_IP
fi

if [ -z "$PI_IP" ]; then
    echo "No IP provided. Exiting."
    exit 1
fi

echo ""
echo "Connecting to Pi at $PI_IP..."
echo ""

# Connect and setup
ssh pi@"$PI_IP" << 'ENDSSH'
echo "=== CURRENT SYSTEM ==="
cat /proc/device-tree/model
uname -a
echo ""

echo "=== CHECKING IF MOODE IS INSTALLED ==="
if [ -d /var/www ]; then
    echo "Moode directory exists"
    if [ -f /var/www/moode_version.txt ]; then
        echo "Moode version: $(cat /var/www/moode_version.txt)"
    else
        echo "Moode may not be fully installed"
    fi
else
    echo "Moode not found - needs installation"
fi
echo ""

echo "=== CURRENT CONFIG ==="
echo "config.txt (HDMI section):"
grep -E "hdmi_|display_rotate|dtoverlay.*vc4" /boot/firmware/config.txt 2>/dev/null || grep -E "hdmi_|display_rotate|dtoverlay.*vc4" /boot/config.txt 2>/dev/null | head -10
echo ""

echo "=== TOUCHSCREEN ==="
lsusb | grep -i touch || echo "No USB touchscreen found"
xinput list 2>/dev/null | grep -i touch || echo "No touchscreen in xinput"
ENDSSH

echo ""
echo "=========================================="
echo "Pi found and checked"
echo "=========================================="
echo ""
echo "Next steps will be provided based on current state"
echo ""

