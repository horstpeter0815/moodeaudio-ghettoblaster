#!/bin/bash
################################################################################
#
# SETUP USB GADGET MODE FOR STANDARD MOODE AUDIO
#
# Works with standard moOde download (not custom build)
# Can be run:
#   - On Mac with SD card mounted
#   - On Pi via SSH/WebSSH
#
################################################################################

set -e

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
echo "║  🔌 USB GADGET MODE - STANDARD MOODE AUDIO                   ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Detect where we're running
BOOTFS=""
ROOTFS=""

if [ -d "/Volumes/bootfs" ]; then
    # SD card mounted on Mac (bootfs partition)
    BOOTFS="/Volumes/bootfs"
    # Check for rootfs (may have space suffix)
    if [ -d "/Volumes/rootfs" ]; then
        ROOTFS="/Volumes/rootfs"
    elif [ -d "/Volumes/rootfs 1" ]; then
        ROOTFS="/Volumes/rootfs 1"
    else
        ROOTFS="/Volumes/rootfs"
    fi
    log "✅ Detected mounted SD card (Mac)"
elif [ -d "/Volumes/boot" ]; then
    # SD card mounted on Mac (boot partition)
    BOOTFS="/Volumes/boot"
    # Check for rootfs (may have space suffix)
    if [ -d "/Volumes/rootfs" ]; then
        ROOTFS="/Volumes/rootfs"
    elif [ -d "/Volumes/rootfs 1" ]; then
        ROOTFS="/Volumes/rootfs 1"
    else
        ROOTFS="/Volumes/rootfs"
    fi
    log "✅ Detected mounted SD card (Mac)"
elif [ -d "/boot/firmware" ]; then
    # Running on Pi (Raspberry Pi OS / moOde)
    BOOTFS="/boot/firmware"
    ROOTFS="/"
    log "✅ Running on Pi - configuring running system"
    if [ "$EUID" -ne 0 ]; then
        error "Must run as root (use sudo)"
        exit 1
    fi
elif [ -d "/boot" ]; then
    # Running on Pi (older Raspberry Pi OS)
    BOOTFS="/boot"
    ROOTFS="/"
    log "✅ Running on Pi (legacy boot) - configuring running system"
    if [ "$EUID" -ne 0 ]; then
        error "Must run as root (use sudo)"
        exit 1
    fi
else
    error "Could not find boot partition"
    echo ""
    warn "Options:"
    echo "  1. Mount SD card on Mac (bootfs and rootfs partitions)"
    echo "  2. Run on Pi via SSH: sudo bash $0"
    exit 1
fi

# Check if we need sudo for mounted SD card
if [[ "$BOOTFS" == /Volumes/* ]] && [ "$EUID" -ne 0 ]; then
    warn "SD card mounted - may need sudo for some operations"
fi

# 1. Configure config.txt
log "1. Configuring config.txt for USB gadget mode..."

CONFIG_FILE="$BOOTFS/config.txt"
if [ ! -f "$CONFIG_FILE" ]; then
    error "config.txt not found at $CONFIG_FILE"
    exit 1
fi

# Backup config.txt
if [ ! -f "$CONFIG_FILE.backup" ]; then
    cp "$CONFIG_FILE" "$CONFIG_FILE.backup"
    log "✅ Created backup: config.txt.backup"
fi

# Check if already configured
if grep -q "dtoverlay=dwc2" "$CONFIG_FILE"; then
    warn "USB gadget overlay already configured"
else
    # Add USB gadget overlay
    echo "" >> "$CONFIG_FILE"
    echo "# USB Gadget Mode - Mac to Pi connection via USB cable" >> "$CONFIG_FILE"
    echo "dtoverlay=dwc2" >> "$CONFIG_FILE"
    log "✅ Added dtoverlay=dwc2 to config.txt"
fi

# 2. Configure cmdline.txt
log "2. Configuring cmdline.txt for USB gadget modules..."

CMDLINE_FILE="$BOOTFS/cmdline.txt"
if [ ! -f "$CMDLINE_FILE" ]; then
    error "cmdline.txt not found at $CMDLINE_FILE"
    exit 1
fi

# Backup cmdline.txt
if [ ! -f "$CMDLINE_FILE.backup" ]; then
    cp "$CMDLINE_FILE" "$CMDLINE_FILE.backup"
    log "✅ Created backup: cmdline.txt.backup"
fi

# Read current cmdline (remove newlines)
CMDLINE=$(cat "$CMDLINE_FILE" | tr -d '\n' | tr -s ' ')

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
SERVICE_DIR="$(dirname "$SERVICE_FILE")"

# Create directory if needed
if [ ! -d "$SERVICE_DIR" ]; then
    mkdir -p "$SERVICE_DIR"
fi

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
if [ "$ROOTFS" = "/" ]; then
    # Running on Pi - enable via systemctl
    systemctl enable usb-gadget-network.service 2>/dev/null || true
    log "✅ Enabled usb-gadget-network.service"
else
    # On mounted SD card - create symlink
    ENABLE_DIR="$ROOTFS/etc/systemd/system/multi-user.target.wants"
    if [ -d "$ENABLE_DIR" ]; then
        mkdir -p "$ENABLE_DIR"
        ln -sf "/lib/systemd/system/usb-gadget-network.service" \
               "$ENABLE_DIR/usb-gadget-network.service" 2>/dev/null || true
        log "✅ Enabled usb-gadget-network.service (will start on boot)"
    else
        warn "Could not enable service (will be enabled on first boot)"
    fi
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
if [ "$ROOTFS" = "/" ]; then
    warn "Next Steps:"
    echo "  1. Reboot Pi: sudo reboot"
    echo "  2. Boot Pi with USB cable connected to Mac"
    echo "  3. On Mac, run: ./SETUP_USB_GADGET_MAC.sh"
    echo "  4. Connect via SSH: ssh pi@192.168.10.2"
    echo "     (or ssh moode@192.168.10.2 if moOde user exists)"
else
    warn "Next Steps:"
    echo "  1. Eject SD card"
    echo "  2. Boot Pi with USB cable connected to Mac"
    echo "  3. On Mac, run: ./SETUP_USB_GADGET_MAC.sh"
    echo "  4. Connect via SSH: ssh pi@192.168.10.2"
    echo "     (or ssh moode@192.168.10.2 if moOde user exists)"
fi
echo ""

