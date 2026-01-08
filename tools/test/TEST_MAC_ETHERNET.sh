#!/bin/bash
################################################################################
# Test Mac Ethernet Connection
################################################################################

echo "Testing Mac Ethernet connection..."
echo ""

# Check if Ethernet interface exists
ETH_INTERFACE=$(networksetup -listallhardwareports | grep -A 1 "Ethernet" | grep "Device" | awk '{print $2}')

if [ -z "$ETH_INTERFACE" ]; then
    echo "❌ No Ethernet interface found on Mac"
    exit 1
fi

echo "✅ Ethernet interface found: $ETH_INTERFACE"
echo ""

# Check if interface is connected
if ifconfig "$ETH_INTERFACE" 2>/dev/null | grep -q "status: active"; then
    echo "✅ Ethernet cable is connected (status: active)"
else
    echo "⚠️  Ethernet cable may not be connected"
    echo "   Interface status: $(ifconfig "$ETH_INTERFACE" 2>/dev/null | grep "status:" || echo "unknown")"
fi

# Check if interface has link
if ifconfig "$ETH_INTERFACE" 2>/dev/null | grep -q "flags=.*UP"; then
    echo "✅ Interface is UP"
else
    echo "⚠️  Interface is DOWN"
fi

# Check current IP (if any)
IP=$(ifconfig "$ETH_INTERFACE" 2>/dev/null | grep "inet " | awk '{print $2}')
if [ -n "$IP" ]; then
    echo "✅ Ethernet has IP address: $IP"
else
    echo "ℹ️  Ethernet has no IP address (normal if not connected to network)"
fi

echo ""
echo "To test Internet Sharing:"
echo "  1. System Preferences > Sharing > Internet Sharing"
echo "  2. Share from: [Your internet connection]"
echo "  3. To computers using: Ethernet"
echo "  4. Enable checkbox"
echo ""
echo "After enabling, Ethernet should get IP: 192.168.10.1"
echo ""



