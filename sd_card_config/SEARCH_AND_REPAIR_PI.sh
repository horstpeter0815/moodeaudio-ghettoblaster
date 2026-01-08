#!/bin/bash

# SEARCH AND REPAIR PI 5
# Finds the Pi on network, connects, and repairs configuration

set -e

echo "=========================================="
echo "SEARCHING AND REPAIRING PI 5"
echo "=========================================="
echo ""

# Try to find Pi on network
echo "Step 1: Searching for Pi on network..."
PI_IP=""

# Try common hostnames
for hostname in moode.local raspberrypi.local moodeaudio.local; do
    if ping -c 1 -W 1 "$hostname" &>/dev/null; then
        PI_IP=$(ping -c 1 "$hostname" | grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}' | head -1)
        echo "✓ Found Pi at: $hostname ($PI_IP)"
        break
    fi
done

# Try to find via arp/network scan
if [ -z "$PI_IP" ]; then
    echo "Scanning local network..."
    # Get local network range
    LOCAL_IP=$(ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1 2>/dev/null || echo "192.168.1.1")
    NETWORK=$(echo "$LOCAL_IP" | cut -d. -f1-3)
    
    # Quick scan of common IPs
    for i in {1..254}; do
        IP="${NETWORK}.${i}"
        if ping -c 1 -W 0.5 "$IP" &>/dev/null; then
            # Try SSH to see if it's the Pi
            if timeout 2 ssh -o ConnectTimeout=1 -o StrictHostKeyChecking=no moode@"$IP" "echo pi" &>/dev/null || \
               timeout 2 ssh -o ConnectTimeout=1 -o StrictHostKeyChecking=no pi@"$IP" "echo pi" &>/dev/null; then
                PI_IP="$IP"
                echo "✓ Found Pi at: $PI_IP"
                break
            fi
        fi
    done
fi

if [ -z "$PI_IP" ]; then
    echo "❌ Could not find Pi on network"
    echo ""
    echo "Please provide Pi IP address manually:"
    read -p "Pi IP: " PI_IP
    if [ -z "$PI_IP" ]; then
        echo "No IP provided. Exiting."
        exit 1
    fi
fi

echo ""
echo "Step 2: Connecting to Pi at $PI_IP..."
echo ""

# Try to connect
SSH_USER=""
for user in moode pi; do
    if ssh -o ConnectTimeout=3 -o StrictHostKeyChecking=no "$user@$PI_IP" "echo connected" &>/dev/null; then
        SSH_USER="$user"
        echo "✓ Connected as $SSH_USER"
        break
    fi
done

if [ -z "$SSH_USER" ]; then
    echo "❌ Could not connect via SSH"
    echo "Please check:"
    echo "  1. Pi is booted and on network"
    echo "  2. SSH is enabled"
    echo "  3. Network connection"
    exit 1
fi

echo ""
echo "Step 3: Running diagnostics on Pi..."
echo ""

# Run diagnostic commands
ssh "$SSH_USER@$PI_IP" << 'ENDSSH'
echo "=== BOOT STATUS ==="
uptime
echo ""

echo "=== CONFIG FILES ==="
echo "cmdline.txt:"
cat /boot/firmware/cmdline.txt 2>/dev/null || cat /boot/cmdline.txt 2>/dev/null
echo ""

echo "config.txt (HDMI section):"
grep -E "hdmi_|display_rotate|dtoverlay.*vc4|video=" /boot/firmware/config.txt 2>/dev/null || grep -E "hdmi_|display_rotate|dtoverlay.*vc4|video=" /boot/config.txt 2>/dev/null | head -20
echo ""

echo "=== DISPLAY STATUS ==="
if command -v xrandr &> /dev/null; then
    DISPLAY=:0 xrandr 2>/dev/null | grep -E "HDMI|connected|1280x400|400x1280" || echo "X11 not running"
else
    echo "xrandr not available"
fi
echo ""

echo "=== FRAMEBUFFER ==="
fbset -s 2>/dev/null | grep geometry || echo "fbset not available"
echo ""

echo "=== DRM DEVICES ==="
ls -la /sys/class/drm/card*/status 2>/dev/null | head -5 || echo "No DRM devices"
echo ""

echo "=== KERNEL MESSAGES (last 20) ==="
dmesg | tail -20 | grep -E "HDMI|drm|vc4|display" || echo "No display-related messages"
ENDSSH

echo ""
echo "Step 4: Checking if repair is needed..."
echo ""

# Check if video parameter is missing
MISSING_VIDEO=$(ssh "$SSH_USER@$PI_IP" "grep -q 'video=HDMI-A-2:400x1280M@60,rotate=90' /boot/firmware/cmdline.txt 2>/dev/null || grep -q 'video=HDMI-A-2:400x1280M@60,rotate=90' /boot/cmdline.txt 2>/dev/null; echo \$?")

if [ "$MISSING_VIDEO" != "0" ]; then
    echo "⚠️  Missing video parameter in cmdline.txt"
    echo "Repairing cmdline.txt..."
    
    ssh "$SSH_USER@$PI_IP" << 'ENDREPAIR'
# Backup current cmdline
CMDLINE_FILE="/boot/firmware/cmdline.txt"
[ ! -f "$CMDLINE_FILE" ] && CMDLINE_FILE="/boot/cmdline.txt"

cp "$CMDLINE_FILE" "${CMDLINE_FILE}.backup.$(date +%s)"

# Get PARTUUID
PARTUUID=$(grep -o 'root=PARTUUID=[^ ]*' "$CMDLINE_FILE" | sed 's/root=PARTUUID=//' || echo "")

# Rebuild cmdline with video parameter
if [ -n "$PARTUUID" ]; then
    sed -i 's/video=HDMI-A-2:[^ ]*//g' "$CMDLINE_FILE"
    sed -i 's/  / /g' "$CMDLINE_FILE"
    sed -i "s/\$/ video=HDMI-A-2:400x1280M@60,rotate=90/" "$CMDLINE_FILE"
    echo "✅ cmdline.txt repaired"
else
    echo "⚠️  Could not find PARTUUID, manual repair needed"
fi
ENDREPAIR
    echo "✅ Repair complete"
else
    echo "✓ cmdline.txt looks good"
fi

echo ""
echo "=========================================="
echo "DIAGNOSTIC COMPLETE"
echo "=========================================="
echo ""
echo "Pi is at: $PI_IP"
echo "SSH as: $SSH_USER"
echo ""
echo "To connect manually:"
echo "  ssh $SSH_USER@$PI_IP"
echo ""

