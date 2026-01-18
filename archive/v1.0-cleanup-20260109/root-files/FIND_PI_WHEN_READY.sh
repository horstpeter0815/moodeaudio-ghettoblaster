#!/bin/bash
# Find Pi immediately after boot - Run when Pi is ready

echo "=== Finding Raspberry Pi ==="
echo ""

# Method 1: Test Ethernet (direct connection)
echo "📡 Method 1: Testing Ethernet (192.168.10.2)..."
if ping -c 2 -W 2000 192.168.10.2 >/dev/null 2>&1; then
    if curl -s --connect-timeout 2 http://192.168.10.2 >/dev/null 2>&1; then
        echo "✅ FOUND via Ethernet!"
        echo "🌐 moOde accessible at: http://192.168.10.2"
        exit 0
    fi
fi
echo "  Not accessible via Ethernet"

# Method 2: Test hostnames
echo ""
echo "📡 Method 2: Testing hostnames..."
for hostname in moode.local raspberrypi.local; do
    if curl -s --connect-timeout 2 http://$hostname >/dev/null 2>&1; then
        echo "✅ FOUND via hostname!"
        echo "🌐 moOde accessible at: http://$hostname"
        exit 0
    fi
done
echo "  Hostnames not working"

# Method 3: Scan ARP table
echo ""
echo "📡 Method 3: Scanning ARP table..."
PI_IP=$(arp -a | grep -i "b8:27:eb\|dc:a6:32\|e4:5f:01" | head -1 | awk '{print $2}' | tr -d '()')
if [ ! -z "$PI_IP" ]; then
    if curl -s --connect-timeout 2 http://$PI_IP >/dev/null 2>&1; then
        echo "✅ FOUND in ARP table!"
        echo "🌐 moOde accessible at: http://$PI_IP"
        exit 0
    fi
fi
echo "  Not found in ARP table"

# Method 4: Scan current network
echo ""
echo "📡 Method 4: Scanning current network..."
NETWORK=$(ifconfig en0 | grep "inet " | awk '{print $2}' | cut -d. -f1-3)
echo "Scanning $NETWORK.x..."
for i in {1..100}; do
    IP="$NETWORK.$i"
    timeout 0.3 ping -c 1 $IP >/dev/null 2>&1 && \
    MAC=$(arp -n $IP 2>/dev/null | awk '{print $4}') && \
    echo "$MAC" | grep -qi "b8:27:eb\|dc:a6:32\|e4:5f:01" && \
    if curl -s --connect-timeout 2 http://$IP >/dev/null 2>&1; then
        echo "✅ FOUND Pi at: $IP"
        echo "🌐 moOde accessible at: http://$IP"
        exit 0
    fi
done

echo ""
echo "❌ Pi not found automatically"
echo "Try in browser:"
echo "  - http://192.168.10.2"
echo "  - http://moode.local"
echo "  - http://raspberrypi.local"

