#!/bin/bash
################################################################################
# COMPLETE GHETTOBLASTER SETUP - Automated Testing
# Waits for Pi to boot, then runs all connectivity tests
################################################################################

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  🚀 COMPLETE GHETTOBLASTER SETUP TEST                        ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Step 1: Wait for Pi to connect
echo "Step 1: Waiting for Pi to boot and connect..."
MAX_ATTEMPTS=60
ATTEMPT=0
PI_CONNECTED=0

while [ $ATTEMPT -lt $MAX_ATTEMPTS ]; do
    ATTEMPT=$((ATTEMPT + 1))
    
    if ping -c 1 -W 2 ghettoblaster.local >/dev/null 2>&1; then
        PI_IP=$(ping -c 1 ghettoblaster.local 2>&1 | grep "bytes from" | awk '{print $4}' | tr -d ':')
        echo "✅ Pi is connected! IP: $PI_IP"
        PI_CONNECTED=1
        break
    fi
    
    if [ $((ATTEMPT % 10)) -eq 0 ]; then
        echo "   Still waiting... ($ATTEMPT/$MAX_ATTEMPTS attempts)"
    fi
    sleep 2
done

if [ $PI_CONNECTED -eq 0 ]; then
    echo "❌ Pi did not connect within $((MAX_ATTEMPTS * 2)) seconds"
    echo ""
    echo "Please check:"
    echo "  1. Pi is powered on"
    echo "  2. SD card is inserted correctly"
    echo "  3. Mac's 'Ghettoblaster' network is active"
    exit 1
fi

echo ""
echo "Step 2: Checking DHCP lease..."
if [ -f /var/db/dhcpd_leases ]; then
    LEASE_INFO=$(cat /var/db/dhcpd_leases | grep -i ghetto | head -3)
    if [ -n "$LEASE_INFO" ]; then
        echo "✅ DHCP lease found:"
        echo "$LEASE_INFO" | sed 's/^/   /'
    else
        echo "⚠️  No DHCP lease info found (may take a moment)"
    fi
fi

echo ""
echo "Step 3: Testing SSH connection..."
if ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no andre@ghettoblaster.local "echo 'SSH test successful'" 2>/dev/null; then
    echo "✅ SSH connection works!"
else
    echo "⚠️  SSH test failed (password may be required)"
    echo "   Try manually: ssh andre@ghettoblaster.local"
fi

echo ""
echo "Step 4: Testing network on Pi (via SSH)..."
SSH_CMD="ip addr show wlan0 | grep 'inet ' && ping -c 2 8.8.8.8 >/dev/null 2>&1 && echo 'Internet: OK' || echo 'Internet: FAILED' && nmcli connection show Ghettoblaster 2>/dev/null | head -5"

if ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no andre@ghettoblaster.local "$SSH_CMD" 2>/dev/null; then
    echo "✅ Network verification on Pi successful"
else
    echo "⚠️  Could not verify network on Pi (SSH may require password)"
    echo "   Connect manually and run:"
    echo "   ip addr show wlan0"
    echo "   ping -c 3 8.8.8.8"
    echo "   nmcli connection show Ghettoblaster"
fi

echo ""
echo "Step 5: Testing web interface..."
if curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 http://ghettoblaster.local | grep -q "200\|301\|302"; then
    echo "✅ Web interface is accessible at http://ghettoblaster.local"
else
    echo "⚠️  Web interface test failed (may still be starting)"
    echo "   Try manually: http://ghettoblaster.local or http://$PI_IP"
fi

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  ✅ SETUP TEST COMPLETE                                     ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "Summary:"
echo "  - Pi IP: $PI_IP"
echo "  - Hostname: ghettoblaster.local"
echo "  - Web Interface: http://ghettoblaster.local"
echo "  - SSH: ssh andre@ghettoblaster.local"
echo ""
echo "Other devices can now connect to 'Ghettoblaster' WiFi network"
echo "and access the Pi at http://ghettoblaster.local"
echo ""

