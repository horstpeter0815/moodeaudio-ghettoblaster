#!/bin/bash
################################################################################
# MANUAL USB GADGET FIX
# If USB gadget hardware works but network isn't configured
# Run this on Pi via SSH (if you have another connection method)
################################################################################

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  🔧 MANUAL USB GADGET NETWORK CONFIGURATION                   ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Check if usb0 exists
if [ -d "/sys/class/net/usb0" ]; then
    echo "✅ USB gadget interface (usb0) detected!"
    echo ""
    echo "Configuring network..."
    
    # Bring up interface
    sudo ip link set usb0 up
    
    # Configure IP
    sudo ip addr add 192.168.10.2/24 dev usb0 2>/dev/null || \
    sudo ip addr replace 192.168.10.2/24 dev usb0
    
    echo "✅ Network configured!"
    echo ""
    echo "Pi IP: 192.168.10.2"
    echo ""
    echo "On Mac, run: ./SETUP_USB_GADGET_MAC.sh"
else
    echo "❌ USB gadget interface (usb0) not found"
    echo ""
    echo "Possible issues:"
    echo "  1. USB cable not connected"
    echo "  2. USB gadget mode not enabled in config.txt"
    echo "  3. Pi needs reboot after config changes"
    echo ""
    echo "Check USB gadget status:"
    ls -la /sys/class/net/ | grep usb
fi

