#!/bin/bash
################################################################################
#
# Setup Ethernet Internet Sharing
# 
# Shares Mac's internet to Pi via Ethernet cable
#
################################################################################

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Ethernet Internet Sharing Setup"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# 1. Check Mac has internet
echo "1️⃣  Checking Mac's internet..."
if curl -s -o /dev/null -w "%{http_code}" https://www.google.com --connect-timeout 3 | grep -q "200"; then
    echo "   ✅ Mac has internet"
else
    echo "   ❌ Mac has no internet - connect to hotel WiFi first"
    exit 1
fi

echo ""

# 2. Find Ethernet interface
echo "2️⃣  Finding Ethernet interface..."
ETHERNET_IFACE=""
for iface in $(ifconfig | grep -E "^en[0-9]:" | cut -d: -f1); do
    # Check if interface has status: active and has ether address
    STATUS=$(ifconfig $iface | grep "status: active" | wc -l)
    HAS_ETHER=$(ifconfig $iface | grep "ether" | wc -l)
    
    if [ "$STATUS" -gt 0 ] && [ "$HAS_ETHER" -gt 0 ]; then
        # Check if it's NOT WiFi (WiFi interfaces show "media: autoselect" differently)
        IS_WIFI=$(ifconfig $iface | grep -i "802.11" | wc -l)
        if [ "$IS_WIFI" -eq 0 ]; then
            ETHERNET_IFACE=$iface
            break
        fi
    fi
done

if [ -n "$ETHERNET_IFACE" ]; then
    echo "   ✅ Found Ethernet: $ETHERNET_IFACE"
    ETH_IP=$(ifconfig $ETHERNET_IFACE | grep "inet " | awk '{print $2}')
    echo "   📍 Current IP: ${ETH_IP:-none}"
else
    echo "   ⚠️  Could not auto-detect Ethernet interface"
    echo ""
    echo "   Active interfaces:"
    for iface in $(ifconfig | grep -E "^en[0-9]:" | cut -d: -f1); do
        STATUS=$(ifconfig $iface | grep "status:" | awk '{print $2}')
        IP=$(ifconfig $iface | grep "inet " | grep -v "127.0.0.1" | awk '{print $2}')
        if [ -n "$IP" ]; then
            echo "      • $iface: $IP ($STATUS)"
        fi
    done
fi

echo ""

# 3. Check current Internet Sharing status
echo "3️⃣  Checking Internet Sharing status..."
SHARING_ENABLED=$(sudo pfctl -s nat 2>/dev/null | grep -c "nat-anchor" || echo "0")
if [ "$SHARING_ENABLED" -gt 0 ]; then
    echo "   ✅ Internet Sharing appears to be enabled"
else
    echo "   ⚠️  Internet Sharing appears to be disabled"
fi

echo ""

# 4. Scan for Pi on Ethernet network
echo "4️⃣  Scanning for Pi..."

# Try known IPs
for ip in 172.24.1.1 192.168.2.2 192.168.2.3; do
    if ping -c 1 -W 1 $ip > /dev/null 2>&1; then
        echo "   ✅ Pi found at $ip"
        PI_IP=$ip
        break
    fi
done

if [ -z "$PI_IP" ]; then
    echo "   ⚠️  Pi not found at common IPs"
    echo ""
    echo "   Trying subnet scan..."
    
    # Get Mac's Ethernet network
    if [ -n "$ETH_IP" ]; then
        SUBNET=$(echo $ETH_IP | cut -d. -f1-3)
        echo "   Scanning $SUBNET.0/24..."
        
        for i in {1..254}; do
            TEST_IP="$SUBNET.$i"
            if [ "$TEST_IP" != "$ETH_IP" ]; then
                if ping -c 1 -W 1 $TEST_IP > /dev/null 2>&1; then
                    # Try SSH to see if it's the Pi
                    if sshpass -p '0815' ssh -o StrictHostKeyChecking=no -o ConnectTimeout=1 andre@$TEST_IP "hostname" 2>/dev/null | grep -qi "moode\|ghetto\|raspberrypi"; then
                        echo "   ✅ Pi found at $TEST_IP"
                        PI_IP=$TEST_IP
                        break
                    fi
                fi
            fi
        done
    fi
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ -n "$PI_IP" ]; then
    echo "  ✅ SUCCESS - Pi is reachable at $PI_IP"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Next steps:"
    echo "  cd ~/moodeaudio-cursor"
    echo "  ./scripts/audio/CHECK_SYSTEM_STATUS.sh"
    echo ""
    echo "Or open browser:"
    echo "  http://$PI_IP"
else
    echo "  ⚠️  Pi not found - Manual setup needed"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Manual setup:"
    echo ""
    echo "1. Open System Settings → Sharing"
    echo "2. Click 'Internet Sharing'"
    echo "3. Share connection from: Wi-Fi"
    echo "4. To computers using: [your Ethernet interface]"
    echo "5. Enable Internet Sharing"
    echo ""
    echo "Wait 30 seconds, then run this script again."
fi

