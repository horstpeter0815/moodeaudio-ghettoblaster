#!/bin/bash
# Enable Mac WiFi hotspot for moOde
# Run: sudo ./ENABLE_MAC_HOTSPOT.sh

echo "=== ENABLING MAC WIFI HOTSPOT ==="
echo ""

# WiFi hotspot settings
SSID="moode-audio"
PASSWORD="moode0815"

echo "Creating hotspot: $SSID"
echo ""

# Method 1: Use networksetup (if supported)
if networksetup -setairportnetwork en0 "$SSID" "$PASSWORD" 2>/dev/null; then
    echo "✅ WiFi network set"
else
    echo "⚠️  Need to set up manually"
fi

# Method 2: Use System Preferences
echo ""
echo "Manual setup in System Preferences:"
echo "1. System Preferences > Sharing"
echo "2. Enable 'Internet Sharing'"
echo "3. Share from: Ethernet"
echo "4. To: Wi-Fi"
echo "5. Wi-Fi Options:"
echo "   - Network Name: $SSID"
echo "   - Password: $PASSWORD"
echo "   - Channel: 11"
echo "   - Security: WPA2/WPA3"
echo ""

# Check current WiFi
echo "Current WiFi status:"
networksetup -getairportnetwork en0 2>/dev/null || echo "WiFi not active"

