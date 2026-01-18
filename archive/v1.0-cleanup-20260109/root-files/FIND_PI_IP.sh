#!/bin/bash
# Find Raspberry Pi IP address on network

echo "=== Finding Raspberry Pi on Network ==="
echo ""

# Method 1: Check ARP table
echo "📡 Method 1: Checking ARP table..."
PI_IP=$(arp -a | grep -i "b8:27:eb\|dc:a6:32\|e4:5f:01" | head -1 | awk '{print $2}' | tr -d '()')
if [ ! -z "$PI_IP" ]; then
    echo "✅ Found Pi in ARP table: $PI_IP"
    echo ""
    echo "🌐 Access moOde at: http://$PI_IP"
    exit 0
fi

# Method 2: Scan common network ranges
echo "📡 Method 2: Scanning network..."
echo "This may take a minute..."

# Get local network range
LOCAL_IP=$(ifconfig | grep "inet " | grep -v "127.0.0.1" | head -1 | awk '{print $2}')
NETWORK=$(echo $LOCAL_IP | cut -d. -f1-3)

echo "Scanning network: $NETWORK.0/24"
echo ""

# Scan for Pi MAC addresses
for i in {1..254}; do
    IP="$NETWORK.$i"
    MAC=$(arp -n $IP 2>/dev/null | grep -i "b8:27:eb\|dc:a6:32\|e4:5f:01" | awk '{print $4}')
    if [ ! -z "$MAC" ]; then
        echo "✅ Found Raspberry Pi!"
        echo "   IP: $IP"
        echo "   MAC: $MAC"
        echo ""
        echo "🌐 Access moOde at: http://$IP"
        exit 0
    fi
done

echo "❌ Could not find Pi automatically"
echo ""
echo "📋 Manual options:"
echo "1. Check router admin page for device 'raspberrypi' or 'moode'"
echo "2. Check Pi's screen if display is connected"
echo "3. Try common IPs:"
echo "   - http://192.168.1.100"
echo "   - http://192.168.0.100"
echo "   - http://10.0.0.100"
echo ""

