#!/bin/bash
# Wait for Pi to boot and connect, then test connectivity

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  🔍 WAITING FOR PI TO CONNECT                                ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "Waiting for Pi to boot and connect to 'Ghettoblaster' network..."
echo "This may take 30-60 seconds..."
echo ""

MAX_ATTEMPTS=30
ATTEMPT=0

while [ $ATTEMPT -lt $MAX_ATTEMPTS ]; do
    ATTEMPT=$((ATTEMPT + 1))
    
    # Check if Pi is reachable
    if ping -c 1 -W 2 ghettoblaster.local >/dev/null 2>&1; then
        PI_IP=$(ping -c 1 ghettoblaster.local 2>&1 | grep "bytes from" | awk '{print $4}' | tr -d ':')
        echo "✅ Pi is connected! IP: $PI_IP"
        echo ""
        
        # Check DHCP lease
        if [ -f /var/db/dhcpd_leases ]; then
            echo "DHCP Lease Info:"
            cat /var/db/dhcpd_leases | grep -i ghetto || echo "  (checking...)"
        fi
        
        exit 0
    fi
    
    echo -n "."
    sleep 2
done

echo ""
echo "❌ Pi did not connect within $((MAX_ATTEMPTS * 2)) seconds"
echo ""
echo "Troubleshooting:"
echo "  1. Check Pi is powered on"
echo "  2. Check SD card is inserted correctly"
echo "  3. Verify Mac's 'Ghettoblaster' network is active"
echo "  4. Check Pi boot logs if accessible"
exit 1
