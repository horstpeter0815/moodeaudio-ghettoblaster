#!/bin/bash
# Test moOde access on known IP addresses

echo "=== Testing moOde Access ==="
echo ""

KNOWN_IPS=(
    "192.168.10.2"
    "192.168.178.161"
    "10.10.11.39"
    "192.168.1.100"
    "192.168.0.100"
)

echo "Testing known IP addresses..."
echo ""

for ip in "${KNOWN_IPS[@]}"; do
    echo -n "Testing $ip... "
    HTTP_CODE=$(curl -s --connect-timeout 2 -o /dev/null -w "%{http_code}" http://$ip 2>/dev/null)
    
    if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "301" ] || [ "$HTTP_CODE" = "302" ]; then
        echo "✅ FOUND!"
        echo ""
        echo "🌐 moOde is accessible at: http://$ip"
        echo ""
        echo "📋 Next steps:"
        echo "1. Open browser"
        echo "2. Go to: http://$ip"
        echo "3. Navigate to Audio page"
        echo "4. Click 'Run Wizard'"
        echo ""
        exit 0
    else
        echo "❌ Not accessible (HTTP $HTTP_CODE)"
    fi
done

echo ""
echo "❌ Could not find moOde automatically"
echo ""
echo "📋 Manual options:"
echo "1. Check router admin page for device 'raspberrypi' or 'moode'"
echo "2. Check Pi's screen if display is connected"
echo "3. Try opening these URLs in browser:"
for ip in "${KNOWN_IPS[@]}"; do
    echo "   - http://$ip"
done
echo ""

