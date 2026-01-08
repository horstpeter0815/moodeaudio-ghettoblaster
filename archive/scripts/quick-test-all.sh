#!/bin/bash
# Quick test of all three systems - efficient SSH connections

echo "=========================================="
echo "QUICK TEST - ALL THREE SYSTEMS"
echo "=========================================="
echo "Date: $(date)"
echo ""

# Test System 1
echo "System 1 (HiFiBerryOS Pi 4):"
if ssh pi1 "hostname && echo 'IP:' && hostname -I 2>/dev/null | awk '{print \$1}' && uptime -p 2>/dev/null || uptime" 2>/dev/null; then
    echo "✅ ONLINE"
else
    echo "❌ OFFLINE"
fi
echo ""

# Test System 2
echo "System 2 (moOde Pi 5):"
if ssh pi2 "hostname && echo 'IP:' && hostname -I 2>/dev/null | awk '{print \$1}' && uptime -p 2>/dev/null || uptime" 2>/dev/null; then
    echo "✅ ONLINE"
else
    echo "❌ OFFLINE"
fi
echo ""

# Test System 3
echo "System 3 (moOde Pi 4):"
if ssh pi3 "hostname && echo 'IP:' && hostname -I 2>/dev/null | awk '{print \$1}' && uptime -p 2>/dev/null || uptime && echo 'WLAN:' && nmcli device status 2>/dev/null | grep wlan0 | awk '{print \$2, \$3, \$4}'" 2>/dev/null; then
    echo "✅ ONLINE"
else
    echo "❌ OFFLINE"
fi
echo ""

echo "=========================================="
echo "✅ All systems tested!"
echo "=========================================="

