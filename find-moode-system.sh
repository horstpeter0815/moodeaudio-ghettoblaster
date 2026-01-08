#!/bin/bash
# Script to find moOde system on the network

echo "=== Finding moOde System ==="
echo ""

# Check if we can ping the known hostname
KNOWN_HOSTNAME="moode"
if ping -c 1 "$KNOWN_HOSTNAME" &>/dev/null; then
    echo "✅ Can reach $KNOWN_HOSTNAME"
    IP=$(ping -c 1 "$KNOWN_HOSTNAME" | grep -oP '\d+\.\d+\.\d+\.\d+' | head -1)
    echo "   IP: $IP"
else
    echo "⚠️  Cannot reach $KNOWN_HOSTNAME"
fi

echo ""
echo "Scanning local network for moOde systems..."
echo "(This may take a moment)"
echo ""

# Try to find moOde systems via nmap or arp
if command -v nmap &>/dev/null; then
    echo "Using nmap to scan network..."
    # Scan common local network ranges
    LOCAL_IP=$(ifconfig | grep "inet " | grep -v 127.0.0.1 | awk '{print $2}' | head -1 | cut -d. -f1-3)
    if [ -n "$LOCAL_IP" ]; then
        echo "Scanning $LOCAL_IP.0/24..."
        nmap -p 80,443,8000,8080 "$LOCAL_IP.0/24" 2>/dev/null | grep -E "Nmap scan|Host|open" | head -20
    fi
fi

echo ""
echo "=== Manual Steps ==="
echo "1. Check your router's admin page for connected devices"
echo "2. Look for device named 'moode' or similar"
echo "3. Try common moOde IPs:"
echo "   - http://moode.local"
echo "   - http://192.168.1.x (check your router)"
echo "   - http://moode (if hostname works)"
echo ""
echo "4. If you have physical access to the Pi:"
echo "   - Connect a monitor/keyboard"
echo "   - Login and run: hostname -I"
echo "   - Or: ip addr show"


