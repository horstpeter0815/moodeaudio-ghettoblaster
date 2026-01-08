#!/bin/bash
################################################################################
#
# SETUP USB GADGET MODE - MAC SIDE CONFIGURATION
#
# Configures Mac to recognize Pi as USB Ethernet device
# Mac IP: 192.168.10.1
# Pi IP: 192.168.10.2
#
################################################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${GREEN}[MAC-USB]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
info() { echo -e "${BLUE}[INFO]${NC} $1"; }

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  🍎 MAC USB GADGET CONFIGURATION                             ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Check if running on Mac
if [[ "$OSTYPE" != "darwin"* ]]; then
    error "This script is for macOS only"
    exit 1
fi

# Wait for USB Ethernet interface
log "Waiting for USB Ethernet interface (connect Pi via USB cable)..."
echo ""

USB_INTERFACE=""
MAX_WAIT=30
WAITED=0

while [ $WAITED -lt $MAX_WAIT ]; do
    # Look for USB Ethernet interfaces
    USB_INTERFACE=$(networksetup -listallhardwareports | grep -A 1 "USB" | grep "Hardware Port" | head -1 | awk -F': ' '{print $2}')
    
    if [ -n "$USB_INTERFACE" ]; then
        # Check if it's actually a USB Ethernet device
        INTERFACE_NAME=$(networksetup -listallhardwareports | grep -B 1 "$USB_INTERFACE" | grep "Device:" | awk '{print $2}')
        if [ -n "$INTERFACE_NAME" ]; then
            log "✅ Found USB Ethernet interface: $USB_INTERFACE ($INTERFACE_NAME)"
            break
        fi
    fi
    
    echo -n "."
    sleep 1
    WAITED=$((WAITED + 1))
done

echo ""

if [ -z "$USB_INTERFACE" ]; then
    error "USB Ethernet interface not found"
    echo ""
    warn "Troubleshooting:"
    echo "  1. Make sure Pi is booted and connected via USB cable"
    echo "  2. Use USB-C to USB-C cable (or USB-A to USB-C)"
    echo "  3. Connect to USB port on Pi (not power-only port)"
    echo "  4. Check System Preferences > Network for new interface"
    echo ""
    info "Available network interfaces:"
    networksetup -listallhardwareports | grep -A 1 "Hardware Port"
    exit 1
fi

# Get the actual device name
DEVICE_NAME=$(networksetup -listallhardwareports | grep -B 1 "$USB_INTERFACE" | grep "Device:" | awk '{print $2}')

if [ -z "$DEVICE_NAME" ]; then
    error "Could not determine device name for $USB_INTERFACE"
    exit 1
fi

log "Configuring $USB_INTERFACE ($DEVICE_NAME)..."
echo ""

# Configure static IP
info "Setting static IP: 192.168.10.1"
echo "   (Requires sudo password)"
echo ""

sudo networksetup -setmanual "$USB_INTERFACE" 192.168.10.1 255.255.255.0

if [ $? -ne 0 ]; then
    error "Failed to configure network interface"
    exit 1
fi

log "✅ Network interface configured"
echo ""

# Wait a moment for interface to come up
sleep 2

# Test connection to Pi
log "Testing connection to Pi (192.168.10.2)..."
echo ""

if ping -c 3 -W 2 192.168.10.2 >/dev/null 2>&1; then
    log "✅ Pi is reachable at 192.168.10.2"
    echo ""
    info "Connection successful!"
    echo ""
    info "You can now connect via SSH:"
    echo "  ssh andre@192.168.10.2"
    echo ""
    info "Or access moOde web interface:"
    echo "  http://192.168.10.2"
    echo ""
else
    warn "Pi not responding yet (may take 30-60 seconds after boot)"
    echo ""
    info "Configuration complete. Try connecting:"
    echo "  ssh andre@192.168.10.2"
    echo ""
    info "Or check connection with:"
    echo "  ping 192.168.10.2"
    echo ""
fi

# Show network configuration
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  📋 NETWORK CONFIGURATION                                    ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
info "Mac Configuration:"
echo "  Interface: $USB_INTERFACE ($DEVICE_NAME)"
echo "  IP Address: 192.168.10.1"
echo "  Subnet: 255.255.255.0"
echo ""
info "Pi Configuration:"
echo "  IP Address: 192.168.10.2"
echo "  Interface: usb0"
echo ""

