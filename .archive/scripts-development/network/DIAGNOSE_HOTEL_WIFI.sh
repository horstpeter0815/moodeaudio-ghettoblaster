#!/bin/bash
################################################################################
#
# Diagnose Hotel WiFi Setup
#
################################################################################

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Hotel WiFi Diagnostic"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# 1. Check Mac's Internet
echo "1️⃣  Mac's Internet Connection"
if curl -s -o /dev/null -w "%{http_code}" https://www.google.com --connect-timeout 3 | grep -q "200"; then
    echo "   ✅ Mac has internet access"
    
    # Check what network Mac is on
    MAC_IP=$(ifconfig | grep "inet " | grep -v "127.0.0.1" | head -1 | awk '{print $2}')
    echo "   📍 Mac IP: $MAC_IP"
else
    echo "   ❌ Mac has NO internet access"
    echo "   👉 Connect Mac to hotel WiFi first"
    exit 1
fi

echo ""

# 2. Check if Pi is reachable
echo "2️⃣  Pi Connectivity"
if ping -c 2 172.24.1.1 > /dev/null 2>&1; then
    echo "   ✅ Pi is reachable at 172.24.1.1"
    
    # Check if Pi has internet
    PI_INTERNET=$(sshpass -p '0815' ssh -o StrictHostKeyChecking=no -o ConnectTimeout=3 \
        andre@172.24.1.1 \
        "curl -s -o /dev/null -w '%{http_code}' https://www.google.com --connect-timeout 3 2>/dev/null" 2>/dev/null)
    
    if [ "$PI_INTERNET" = "200" ]; then
        echo "   ✅ Pi has internet access"
    else
        echo "   ⚠️  Pi has NO internet access"
        echo "   👉 Pi can't reach internet (might not be a problem for local testing)"
    fi
else
    echo "   ❌ Cannot reach Pi at 172.24.1.1"
    echo ""
    echo "   Possible causes:"
    echo "   • Pi is not powered on"
    echo "   • Pi is not connected to network"
    echo "   • Mac and Pi are on different networks"
    echo "   • Hotel WiFi has client isolation enabled"
    echo ""
    echo "   Solutions:"
    echo "   A. Connect Mac to Pi via Ethernet cable"
    echo "   B. Use Mac's Internet Sharing to bridge to Pi"
    echo "   C. Configure Pi to connect to hotel WiFi"
    exit 1
fi

echo ""

# 3. Check network topology
echo "3️⃣  Network Topology"
MAC_NETWORKS=$(ifconfig | grep -E "^[a-z]" | grep -v "lo0" | awk '{print $1}' | tr -d ':')
echo "   Mac's network interfaces:"
for iface in $MAC_NETWORKS; do
    IP=$(ifconfig $iface 2>/dev/null | grep "inet " | grep -v "127.0.0.1" | awk '{print $2}')
    if [ -n "$IP" ]; then
        STATUS=$(ifconfig $iface 2>/dev/null | grep "status:" | awk '{print $2}')
        echo "      • $iface: $IP (${STATUS:-unknown})"
    fi
done

echo ""

# 4. Recommendation
echo "4️⃣  Recommendation"
if ping -c 1 172.24.1.1 > /dev/null 2>&1; then
    echo "   ✅ Current setup is working!"
    echo "   👉 You can proceed with Radio debugging"
    echo "   👉 Run: cd ~/moodeaudio-cursor && ./scripts/audio/CHECK_SYSTEM_STATUS.sh"
else
    echo "   ⚠️  Network setup needed"
    echo ""
    echo "   Quick fixes:"
    echo "   1. Connect Mac and Pi with Ethernet cable"
    echo "   2. Enable Internet Sharing on Mac (System Settings → Sharing → Internet Sharing)"
    echo "   3. Or connect Pi to hotel WiFi (may need to handle captive portal)"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

