#!/bin/bash
################################################################################
# CHECK USB GADGET STATUS
# Monitors for Pi USB gadget connection
################################################################################

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  🔍 CHECKING USB GADGET STATUS                               ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Check network interfaces
echo "📡 Network Interfaces:"
networksetup -listallhardwareports | grep -E "Hardware Port|Device:" | grep -B 1 "USB\|Ethernet" | head -20
echo ""

# Check for 192.168.10.1 interface
echo "🔍 Checking for USB Ethernet interface..."
USB_IF=$(ifconfig | grep -B 1 "192.168.10.1" | grep "^[a-z]" | awk '{print $1}' | sed 's/:$//' | head -1)
if [ -n "$USB_IF" ]; then
    echo "✅ Found interface: $USB_IF (configured with 192.168.10.1)"
else
    echo "⏳ No USB Ethernet interface found yet"
    echo "   (Pi may still be booting or USB cable not connected)"
fi
echo ""

# Check if Pi is responding
echo "🔍 Checking if Pi is responding (192.168.10.2)..."
if ping -c 1 -W 2 192.168.10.2 >/dev/null 2>&1; then
    echo "✅ Pi is responding at 192.168.10.2!"
    echo ""
    echo "🎉 SUCCESS! You can now connect:"
    echo "   ssh pi@192.168.10.2"
    echo "   or"
    echo "   ssh moode@192.168.10.2"
else
    echo "⏳ Pi not responding yet"
    echo ""
    echo "Possible reasons:"
    echo "  1. Pi is still booting (wait 30-60 seconds)"
    echo "  2. USB gadget service file not created (need sudo)"
    echo "  3. USB cable not connected properly"
    echo ""
    echo "To create service file, run:"
    echo "  sudo bash COMPLETE_USB_SETUP_NOW.sh"
fi
echo ""

