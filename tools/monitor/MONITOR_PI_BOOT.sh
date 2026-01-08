#!/bin/bash
################################################################################
# MONITOR PI BOOT STATUS
# Continuously monitors for Pi coming online
################################################################################

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  🔍 MONITORING PI BOOT                                       ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

MAX_CHECKS=30
CHECK_INTERVAL=3

echo "Checking for Pi every $CHECK_INTERVAL seconds..."
echo ""

for i in $(seq 1 $MAX_CHECKS); do
    echo -n "[$i/$MAX_CHECKS] "
    
    # Check USB gadget mode first (192.168.10.2)
    if ping -c 1 -W 1 192.168.10.2 >/dev/null 2>&1; then
        echo "✅ Pi found on USB gadget: 192.168.10.2"
        PI_IP="192.168.10.2"
        break
    fi
    
    # Check network hostname
    if ping -c 1 -W 1 ghettoblaster.local >/dev/null 2>&1; then
        PI_IP=$(ping -c 1 ghettoblaster.local 2>&1 | grep "bytes from" | awk '{print $4}' | tr -d ':')
        echo "✅ Pi found: ghettoblaster.local ($PI_IP)"
        break
    fi
    
    # Check DHCP range (common for internet sharing)
    for ip in $(seq 2 10); do
        if ping -c 1 -W 1 "192.168.2.$ip" >/dev/null 2>&1; then
            echo "✅ Pi found on DHCP: 192.168.2.$ip"
            PI_IP="192.168.2.$ip"
            break 2
        fi
    done
    
    echo "⏳ Waiting for Pi to boot..."
    sleep $CHECK_INTERVAL
done

echo ""

if [ -z "$PI_IP" ]; then
    echo "❌ Pi not found after $MAX_CHECKS checks"
    echo ""
    echo "Possible reasons:"
    echo "  1. Pi still booting (wait longer)"
    echo "  2. Network cable not connected"
    echo "  3. Internet sharing not enabled"
    echo "  4. Pi on different network"
else
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║  ✅ PI IS ONLINE!                                             ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo ""
    echo "Pi IP: $PI_IP"
    echo ""
    echo "Testing SSH..."
    if ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 pi@"$PI_IP" "echo 'SSH OK'" 2>&1 | grep -q "SSH OK"; then
        echo "✅ SSH working! Connect with:"
        echo "   ssh pi@$PI_IP"
        echo "   Password: raspberry"
    else
        echo "⏳ SSH not ready yet, try:"
        echo "   ssh pi@$PI_IP"
    fi
    echo ""
    echo "Testing internet access on Pi..."
    ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 pi@"$PI_IP" "ping -c 2 8.8.8.8" 2>&1 | head -5 || echo "Can't test internet (need SSH first)"
fi
