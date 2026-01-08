#!/bin/bash
################################################################################
#
# Resume Network - Quick network reconnection check
#
################################################################################

echo "🌐 Checking network connectivity..."
echo ""

# Try to reach Pi
if ping -c 2 172.24.1.1 > /dev/null 2>&1; then
    echo "✅ Pi is reachable at 172.24.1.1"
    echo ""
    echo "Ready to continue! Run:"
    echo "  cd ~/moodeaudio-cursor && ./scripts/audio/CHECK_SYSTEM_STATUS.sh"
else
    echo "❌ Cannot reach Pi at 172.24.1.1"
    echo ""
    echo "Network troubleshooting:"
    echo "1. Check if Pi is powered on"
    echo "2. Ensure Pi is connected to same network as Mac"
    echo "3. Try SSH: ssh andre@172.24.1.1 (password: 0815)"
    echo ""
    echo "If Pi needs to connect to hotel WiFi:"
    echo "  cd ~/moodeaudio-cursor/scripts/network"
    echo "  # Use network setup scripts if needed"
fi

