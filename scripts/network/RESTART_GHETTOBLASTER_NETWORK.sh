#!/bin/bash
################################################################################
#
# Restart Ghettoblaster WiFi Network
# 
# Recreates the WiFi access point that Pi connects to
#
################################################################################

echo "🔧 Setting up Ghettoblaster WiFi Network..."
echo ""

# Check if Mac has internet
if ! curl -s -o /dev/null -w "%{http_code}" https://www.google.com --connect-timeout 3 | grep -q "200"; then
    echo "❌ Mac needs internet access first"
    echo "👉 Connect to hotel WiFi or iPhone hotspot"
    exit 1
fi

echo "✅ Mac has internet"
echo ""

# Check current sharing status
SHARING_STATUS=$(sudo /usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate 2>/dev/null || echo "unknown")

echo "📋 Current Internet Sharing status:"
networksetup -listallnetworkservices

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Manual Setup Required"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "To share your Mac's internet with the Pi:"
echo ""
echo "1. Open System Settings → Sharing"
echo "2. Click 'Internet Sharing'"
echo "3. Select 'Share connection from: Wi-Fi' (or iPhone hotspot)"
echo "4. Check 'To computers using: Wi-Fi'"
echo "5. Click 'Wi-Fi Options':"
echo "   • Network Name: Ghettoblaster"
echo "   • Security: WPA2 Personal"
echo "   • Password: (your password)"
echo "6. Enable Internet Sharing"
echo ""
echo "Then wait 30 seconds for Pi to connect."
echo ""
echo "Verify with:"
echo "  ping 172.24.1.1"
echo ""

