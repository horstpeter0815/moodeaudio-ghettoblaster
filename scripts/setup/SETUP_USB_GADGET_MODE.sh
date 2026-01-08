#!/bin/bash
################################################################################
#
# SETUP USB GADGET MODE FOR MAC-TO-PI CONNECTION
#
# Enables Raspberry Pi to act as USB Ethernet device when connected via USB
# Mac IP: 192.168.10.1
# Pi IP: 192.168.10.2
#
################################################################################

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR" && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${GREEN}[USB-GADGET]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
info() { echo -e "${BLUE}[INFO]${NC} $1"; }

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  🔌 USB GADGET MODE SETUP - MAC TO PI CONNECTION             ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Check if running on Mac or Pi
if [[ "$OSTYPE" == "darwin"* ]]; then
    log "Detected Mac - configuring Pi files from Mac..."
    # Continue with Pi configuration (modifying files on Mac or mounted SD card)
fi

# Running on Mac (configuring files) or Pi (configuring running system)
log "Configuring Pi for USB gadget mode..."

BOOTFS="$PROJECT_ROOT/moode-source/boot/firmware"
ROOTFS="$PROJECT_ROOT/moode-source"

# Check if we're configuring files on SD card or in build
if [ -d "/Volumes/bootfs" ] || [ -d "/Volumes/boot" ]; then
    if [ -d "/Volumes/bootfs" ]; then
        BOOTFS="/Volumes/bootfs"
        ROOTFS="/Volumes/rootfs"
    else
        BOOTFS="/Volumes/boot"
        ROOTFS="/Volumes/rootfs"
    fi
    log "✅ Detected mounted SD card - configuring directly on SD card..."
elif [ -d "/boot/firmware" ] && [ -d "/lib/systemd/system" ]; then
    # Running on Pi itself
    BOOTFS="/boot/firmware"
    ROOTFS="/"
    log "✅ Running on Pi - configuring running system..."
else
    # Configuring build files on Mac
    log "✅ Configuring build files (will be included in next build)..."
fi

# 1. Add USB gadget overlay to config.txt
log "1. Configuring config.txt for USB gadget mode..."

CONFIG_FILE="$BOOTFS/config.txt"
if [ ! -f "$CONFIG_FILE" ]; then
    CONFIG_FILE="$BOOTFS/config.txt.overwrite"
fi

if [ ! -f "$CONFIG_FILE" ]; then
    error "config.txt not found at $CONFIG_FILE"
    exit 1
fi

# Check if already configured
if grep -q "dtoverlay=dwc2" "$CONFIG_FILE"; then
    warn "USB gadget overlay already configured"
else
    # Add USB gadget overlay (for Pi 4/5)
    echo "" >> "$CONFIG_FILE"
    echo "# USB Gadget Mode - Mac to Pi connection" >> "$CONFIG_FILE"
    echo "dtoverlay=dwc2" >> "$CONFIG_FILE"
    log "✅ Added dtoverlay=dwc2 to config.txt"
fi

# 2. Update cmdline.txt
log "2. Configuring cmdline.txt for USB gadget modules..."

CMDLINE_FILE="$BOOTFS/cmdline.txt"
if [ ! -f "$CMDLINE_FILE" ]; then
    error "cmdline.txt not found at $CMDLINE_FILE"
    exit 1
fi

# Read current cmdline
CMDLINE=$(cat "$CMDLINE_FILE" | tr -d '\n')

# Check if modules-load already exists
if echo "$CMDLINE" | grep -q "modules-load="; then
    # Add to existing modules-load
    if ! echo "$CMDLINE" | grep -q "modules-load=.*g_ether"; then
        CMDLINE=$(echo "$CMDLINE" | sed 's/modules-load=\([^ ]*\)/modules-load=\1,g_ether/')
        log "✅ Added g_ether to existing modules-load"
    else
        warn "g_ether already in modules-load"
    fi
else
    # Add new modules-load
    CMDLINE="$CMDLINE modules-load=dwc2,g_ether"
    log "✅ Added modules-load=dwc2,g_ether to cmdline.txt"
fi

# Write back cmdline.txt
echo "$CMDLINE" > "$CMDLINE_FILE"

# 3. Create systemd service for USB gadget network
log "3. Creating USB gadget network service..."

SERVICE_FILE="$ROOTFS/lib/systemd/system/usb-gadget-network.service"
mkdir -p "$(dirname "$SERVICE_FILE")"

cat > "$SERVICE_FILE" << 'EOF'
[Unit]
Description=Configure USB Gadget Network Interface
After=network-pre.target
Before=network.target
Wants=network-pre.target

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/bin/bash -c 'sleep 2 && if [ -d /sys/class/net/usb0 ]; then ip link set usb0 up && ip addr add 192.168.10.2/24 dev usb0 || true; fi'
ExecStop=/bin/bash -c 'if [ -d /sys/class/net/usb0 ]; then ip link set usb0 down || true; fi'

[Install]
WantedBy=multi-user.target
EOF

log "✅ Created usb-gadget-network.service"

# 4. Enable the service
if [ -d "$ROOTFS/etc/systemd/system" ]; then
    mkdir -p "$ROOTFS/etc/systemd/system/multi-user.target.wants"
    ln -sf "/lib/systemd/system/usb-gadget-network.service" \
           "$ROOTFS/etc/systemd/system/multi-user.target.wants/usb-gadget-network.service" 2>/dev/null || true
    log "✅ Enabled usb-gadget-network.service"
elif [ "$ROOTFS" = "/" ]; then
    # Running on Pi - enable via systemctl
    systemctl enable usb-gadget-network.service 2>/dev/null || true
    log "✅ Enabled usb-gadget-network.service (will start on next boot)"
fi

echo ""
log "=== USB GADGET MODE CONFIGURATION COMPLETE ==="
echo ""
info "Configuration Summary:"
echo "  ✅ USB gadget overlay added to config.txt"
echo "  ✅ USB gadget modules added to cmdline.txt"
echo "  ✅ USB gadget network service created"
echo ""
info "Pi Configuration:"
echo "  IP Address: 192.168.10.2"
echo "  Interface: usb0"
echo ""
warn "Next Steps:"
if [ -d "/Volumes/bootfs" ] || [ -d "/Volumes/boot" ]; then
    echo "  1. Eject SD card"
    echo "  2. Boot Pi with USB cable connected to Mac"
    echo "  3. On Mac, run: ./SETUP_USB_GADGET_MAC.sh"
    echo "  4. Connect via SSH: ssh andre@192.168.10.2"
elif [ "$ROOTFS" = "/" ]; then
    echo "  1. Reboot Pi: sudo reboot"
    echo "  2. Boot Pi with USB cable connected to Mac"
    echo "  3. On Mac, run: ./SETUP_USB_GADGET_MAC.sh"
    echo "  4. Connect via SSH: ssh andre@192.168.10.2"
else
    echo "  1. Build image: ./tools/build.sh --deploy"
    echo "  2. Flash SD card and boot Pi with USB cable connected"
    echo "  3. On Mac, run: ./SETUP_USB_GADGET_MAC.sh"
    echo "  4. Connect via SSH: ssh andre@192.168.10.2"
fi
echo ""

